/*
  идеи
  - сделать визпроцессы наборными в группе  
  - раскраска это добавка
  - расщепить загрузчик N
  - добавление поля это добавка
  - придумать как формировать "проект"

*/

load "params";


find-objects-bf features="render_project_right_col" recursive=false 
|
insert_children { manage_project; };

feature "manage_project" {
	ma: 
	    project=@..->project
	    curview=@..->active_view

	collapsible "Проект Lava" {
		column plashka {
			text "Добавить:";
			button_add_object "Визуализация VTK точек" 
			   add_to=@ma->project
			   add_type="vtk-vis-1"
			   {{
			   	 created_add_to_current_view curview=@ma->curview
			   	   {{ created_mark_manual }}
			   	 ; 
			   }};

			button_add_object "Загрузка серии VTK" 
			   add_to=@ma->project
			   add_type="vtk-source"
			   {{
			   	 created_add_to_current_view curview=@ma->curview
			   	   {{ created_mark_manual }}
			   	 ;
			   }};
			

			/*
			на пути к добавлению произвольных цепочек
			button "Добавить визуализацию звезд" {
				creator target=@ma->project input={ astra-vis-1; } 
				 {{ created_mark_manual }};
			};
			*/
		};
	};
};

////////////////////////////

// берет на вход серию файлов а на выходе выдает содержимое в форме df
feature "vtk-source" {
  qqe: visual_process df56 
    title="Загрузка серии VTK"
    index=1 	
    gui={
    	column plashka {
    		
    		column {
      		insert_children input=@.. list=@files->gui;
    	  };
    	  render-params @data;
      };
    } 
    N=@data->N
    
    output=@loaded_data2->output

    url="http://127.0.0.1:8080/vrungel/public_local/Kalima/list.txt"
    dictionary_urls=["http://127.0.0.1:8080/vrungel/public_local/Kalima/list.txt"]

    {
			scene2d: dom {
			  		//text tag="h2" style="color:white;" (join (@listing->output | geta @astradata->N));
			  		text tag="h2" style="color:white;margin:0;" @data->current_file_name;
			};

			files: select-files url=@qqe->url;
			
			data: N=0 
			      files=@files->output
			  {{ x-param-option name="files" option="priority" value=10 }}
			  {{ x-param-option name="files" option="values" value=@qqe->dictionary_urls? }}
			  
				{{ x-param-slider name="N" sliding=false min=0 max=((@data->files | geta "length") - 1) }}
				
				{{ x-param-label-small name="files_count"}}
				{{ x-param-label-small name="current_file_name"}}
				{{ x-param-option name="current_file" option="readonly" value=true }}

				{{ x-param-label-small name="points_loaded"}}
				
				current_file=(@data->files | geta @data->N default=[] | geta 1 default=null)
		    current_file_name=(@data->files | geta @data->N default=[] | geta 0 default=null)
		    points_loaded=(@loaded_data2->output | geta "length")
		    files_count=(@data->files | geta "length")

      {
      	 loaded_data2: load_file_binary file=@data->current_file | parse_vtk_points 
      	    | compute_magnitude_col; // туду это должна быть добавка
			};   
    };
};

// объект который дает диалог пользвателю 
// а в output выдает найденный dataframe отмеченный меткой df56
// todo предикат ф-ю
feature "find-data-source" {
   findsource: 
      data_length=(@findsource->output | geta "length")
	    input_link=(@datafiles->output | geta 0)
	    features="df56"
      {{
          datafiles: find-objects-bf features=@findsource->features | arr_map code="(v) => v.getPath()+'->output'";

          x-param-combo
           name="input_link" 
           values=@datafiles->output 
           ;

          x-param-option
           name="input_link"
           option="priority"
           value=10;

           x-param-option
           name="data_length"
           option="priority"
           value=12;

          x-param-label name="data_length";
      }}
    {
      link from=@findsource->input_link to="@findsource->output";
    };
};


// тут у нас и раскраска и доп.фильтр встроен. ну ладно.
// и это 1 штучка
feature "vtk-vis-1" {
	avp: visual_process
	title="Визуализация VTK точек"
	input=@vtkdata->output

    columns=(@avp->input | geta "colnames")
    selected_data = (get input=@avp->input name=@avp->selected_column)
    selected_column=""
    {{ x-param-combo name="selected_column" values=@avp->columns }}
    //{{ selected_column: param_combo values=@avp->columns index=0; }}


	gui={
		
		ko: column plashka {

			collapsible "Источник данных" {
  		  render-params @vtkdata;
	    };

	    render-params-list object=@avp list=["selected_column"];
	    //render-params @avp;

	    collapsible "Раскраска данных" {
   	    render-params @arrtocols;
	    };

			show_sources_params 
			  input=(find-objects-by-crit "visual-process" root=@scene include_root=false recursive=false)
			  auto_expand_first=false
			;
	  };
	}
	gui3={
		render-params @avp;
	}
	scene3d=@scene->output
	scene2d=@scene2d->output

	{

		vtkdata: find-data-source; // гуи выбора входных данных

		scene2d: dom {
			  		text tag="h3" style="color:white;margin:0;" @avp->selected_column;
		};

		scene: node3d visible=@avp->visible {{ force_dump }}
		{

		   // 218 201 93 цвет 0.85, 0.78, 0.36
		   @avp->input | pts: points title="Точки" visual-process editable-addons 
		     radius=1 color=[1,0,0] 
		     gui={ render-params @pts; manage-addons @pts; }
		     colors=( @avp->selected_data | arrtocols: arr_to_colors gui_title="Цвета"  ) // color_func=(color_func_white)
		     ;

		   insert_children input=@pts->addons_container active=(is_default @pts->addons_container) list={
		   	 // F-PIXEL-PRESET
		   	 effect3d_sprite sprite="disc.png";
		   	 //effect3d_additive;
		   	 //effect3d_zbuffer depth_test=false;
		   	 //effect3d-opacity opacity=0.25 alfa_test=0;
		   };

		   // вообще может оказаться что это будет отдельный визуальный процесс - "антураж"
		   //ab: axes_view size=1;

		   text3d_one text=@avp->selected_column 
		   {{
          box: get_coords_bbox input=@pts->output;
          effect3d-pos x=(@box->max | geta 0) y=(@box->max | geta 1) z=(@box->max | geta 2);
       }}   


		};
	};
};


// туду добавка это. а 2-я версия вообще ако скрипт
register_feature name="compute_magnitude_col" code=`
      env.onvalue("input",(df) => {

        if (!df || !df.isDataFrame) {
          env.setParam("output",[]);
          return;
        }

        let v0 = df.get_column( "velocity0" );
        let v1 = df.get_column( "velocity1" );
        let v2 = df.get_column( "velocity2" );
        if (!(v0 && v1 && v2)) {
          env.setParam("output",df);
          return;
        }

        df = df.clone();
        let arr = new Float32Array( df.get_length() );
        for (let i=0; i<arr.length; i++)
          arr[i] = Math.sqrt( v0[i]*v0[i] + v1[i]*v1[i] + v2[i]*v2[i] );

        df.add_column( "magnitude", arr, df.get_column_names().indexOf( "velocity2" )+1 );
        env.setParam("output",df);
      });
`;


feature "vtk-vis-group" {
	vp: visual_process
	title="Визуализация наборов VTK точек"

	gui={
		render-params @vp;

    button "Настройки объектов" {
      lambda @vp @vp->gui2 code="(obj,g2) => { 
         obj.emit('show-settings',g2) 
         }";
    };		

    manage-addons @scene;
	}

	gui2={ 
   	render_layers_inner title="Визуальные объекты" expanded=true
           root=@vp
           items=[ { "title":"Объекты данных", 
                     "find":"vtk-vis-1",
                     "add":"vtk-vis-1",
                     "add_to": "@scene->.",
                     "sibling_types":["vtk-vis-1"],
                     "sibling_titles":["Точки VTK"]
                   }
                 ]
           ;

  }

  scene3d=@scene->output

  {{ x-param-slider name="delta" min=0.5 max=10 step=0.1 }}
  delta=1

  {
  	scene: node3d editable-addons;
  	//points positions=[1,2,3,4,5,6];

/*
  	@scene | get_children_arr | x-modify {
  		effect3d-pos z=5;
  	};
  	*/

  	@scene | find-objects-bf features="vtk-vis-1" | repeater {
  		rep: x-modify {
  		  effect3d-pos z=(@rep->input_index * @vp->delta);
  	  };
  	};  
  };

};

feature "vtk-vis" {
	vp: visual_process
	title="Визуализация наборов VTK точек"
	columns=(@vp->input | geta "colnames")
	input=@vtkdata->output

	gui={
		render-params @vp;

		collapsible "Источник данных" {
  		  render-params @vtkdata;
	  };		

   	show_sources_params input=@vp->generated_processes;

    manage-addons @scene;
	}

  scene3d=@scene->output

  {{ x-param-slider name="delta" min=0.5 max=10 step=0.1 }}
  delta=1
  generated_processes=(@scene | find-objects-bf features="vtk-vis-1")

  {
    vtkdata: find-data-source; // гуи выбора входных данных

  	scene: node3d editable-addons {
  		@vp->columns | repeater {
  			rep: node3d {
  			 vtk-vis-1 
  			    input=@vp->input 
  			    selected_column=@rep->input title=@rep->input;
  			};
  		};
  		
  	};

  	 @vp->generated_processes | filter_geta "visible" | console_log_input "EEE" | repeater {
	  		rep: x-modify {
	  		  effect3d-pos z=(@rep->input_index * @vp->delta);
	  	  };
  	  };  
  };

};