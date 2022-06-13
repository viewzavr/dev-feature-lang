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

feature "text3d_vp" {
	vp: visual-process editable-addons title="Текст"
	  gui={ render-params @vp
	  	       filters={ params-hide list="title"; }; 
	    manage-addons @vp; }
	  text3d_one
	  ;
};

feature "points_vp" {
	vp: visual-process editable-addons title="Точки"
	  gui={ render-params @vp
	  	       filters={ params-hide list="title"; }; 
	    manage-addons @vp; }
	  points;
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



// тут у нас и раскраска и доп.фильтр встроен. ну ладно.
// и это 1 штучка
feature "vtk-vis-1" {
	avp: visual_process
	title="Визуализация VTK точек"
	input=@vtkdata->output
	output=@avp->scene3d

    columns=(@avp->input | geta "colnames")
    selected_data = (get input=@avp->input name=@avp->selected_column)
    selected_column=""
    {{ x-param-combo name="selected_column" values=@avp->columns }}
    //{{ selected_column: param_combo values=@avp->columns index=0; }}

	gui={
		
		ko: column plashka {

			// render-params-list object=@avp list=["visible"];
			//checkbox "visible" value=@avp->visible
			//{{ x-on "user-changed" "(obj) => obj.setParam('visible',!obj.params.visible, true) " }}

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

	gui1={
		
		ko: column plashka {

			//render-params-list object=@avp list=["visible"];

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
		   @avp->input | pts: points_vp
		     radius=1 color=[1,0,0]
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

		   tx: text3d_vp text=@avp->selected_column 
		   {{
          box: get_coords_bbox input=@pts->output;
				  effect3d-pos x=(@box->max | geta 0) y=(@box->max | geta 1) z=(@box->max | geta 2);
       }};

/*
		   insert_children input=@tx->addons_container active=(is_default @tx->addons_container) list={
          box: get_coords_bbox input=@pts->output;
          effect3d-pos x=(@box->max | geta 0) y=(@box->max | geta 1) z=(@box->max | geta 2);
		   };       
*/

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

   /*
  	@scene | find-objects-bf features="vtk-vis-1" | repeater {
  		rep: x-modify {
  		  effect3d-pos z=(@rep->input_index * @vp->delta);
  	  };
  	};
  	*/

  };

};

feature "vtk-vis" {
	vp: visual_process
	title="VTK точки"
	columns=(@vp->input | geta "colnames")
	input=@vtkdata->output

	gui={
		render-params @vp;

		collapsible "Источник данных" {
  		  render-params @vtkdata;
	  };

    manage-addons @scene;

    manage-content @scene 
       vp=@vp
       title="Слои" 
       items=[{"title":"Скалярные слои", "find":"vtk-vis-1","add":"vtk-vis-1"}];
	}

  scene3d=@scene->output

  generated_processes=(@scene | find-objects-bf features="vtk-vis-1")
  sub_processes=@vp->generated_processes

  {
    vtkdata: find-data-source; // гуи выбора входных данных

  	scene: node3d editable-addons 
  	  {

  	  	// это должно быть разовым действием - добавление всех колонок
  		@vp->columns | repeater {
  			 rep: output=@vv->output {
  			 	  vv: vtk-vis-1 
  			      input=@vp->input 
  			      selected_column=@rep->input title=@rep->input
  			      ;
  			    };  
  		};

  	};

/*
  	 @vp->generated_processes | filter_geta "visible" | repeater {
	  		rep: x-modify {
	  		  effect3d-pos z=(@rep->input_index * @vp->delta);
	  	  };
  	  };
*/  	  
  };

};

feature "manage-content-1" {

 	mc: column 
   lagui={
   	render_layers_mc
 			   root=@mc->0
 			   title=@mc->title
 			   items=@mc->items;
   }
 	{

 		button @mc->title {
 			m_lambda "(visprocess,g2) => {
 			 visprocess.emit('show-settings',g2) }" @mc->vp @mc->lagui;
 		};

/*
   	@vp->sub_processes | repeater {
   		rep: row {
   			button (@rep->input | geta "title") style='min-width:220px;'
   			{
		       m_lambda "(obj,g2) => { obj.emit('show-settings',g2) }" @vp (@rep->input | geta "gui1");
   			};
   			k: checkbox-c value=(@rep->input | geta "visible")
   			   {{ x-on 'user-changed' {
   			   	  m_lambda "(obj) => obj.setParam('visible', !obj.params.visible, true);" @rep->input;
   			   } }};
   		};
   	};
*/   	
    };

};

/*
   типа как render_layers_inner но на один объект детей управлять

    render_layers_mc 
         title="Визуальные объекты" 
         root=@vroot
         items=[ {"title":"Объекты данных", find":"guiblock datavis","add":"linestr"},
                 {"title":"Статичные","find":"guiblock staticvis","add":"axes"}
               ];
*/

feature "render_layers_mc" {

rl_root: 
    column text=@.->title
    style="min-width:250px" 
    style_h = "max-height:80vh;"
    {
     s: switch_selector_row {{ hilite_selected }} 
         items=(@rl_root->items | arr_map code="(v) => v.title")
         plashka style_qq="margin-bottom:0px !important;"
         ;
        
     ba: button_add_object add_to=@rl_root->root
                       add_type=(@rl_root->items | get @s->index | get "add");

     objects_list:
     find-objects-bf (@rl_root->items | get @s->index | get "find") 
                     root=@rl_root->root
                     recursive=false
                     include_root=false debug=true
     | sort_by_priority;
     ;

     /// выбор объекта

     cbsel: combobox style="margin: 5px;" dom_size=5 
       values=(@objects_list->output | arr_map code="(elem) => elem.$vz_unique_id")
       titles=(@objects_list->output | map_param "title")
       visible=( (@cbsel->values |geta "length") > 0)
       ;

    /// параметры объекта   

     co: column plashka style_r="position:relative; overflow: auto;"  
            input=(@objects_list->output | get index=@cbsel->index?)
            visible=(@co->input?)
      {
        row visible=((@co->input?  | geta  "sibling_types" | geta "length" default=0) > 1) 
        {
          object_change_type input=@co->input?
            types=(@co->input?  | geta  "sibling_types" )
            titles=(@co->input? | geta "sibling_titles")
            //types=(@co->input  | geta  "items" | geta (i_call_js code="Object.keys"))
            //titles=(@co->input  | geta  "items" | geta (i_call_js code="Object.values"))
            ;
        };

        column {
          insert_children input=@.. list=(@co->input? | geta "gui" default=[]);
        };

        if (has_feature input=@co->input? name="editable-addons") then={
          manage_addons input=@co->input?;
        };

        button "x" style="position:absolute; top:0px; right:0px;" 
        {
          lambda @co->input? code=`(obj) => { obj.removedManually = true; obj.remove(); }`;
        };

     };


  };   

};



feature "manage-content" {

 	mc: column root=@mc->0 {

     ba: button_add_object 
          add_to=@mc->root
          add_type=(@mc->items | geta 0 | get "add");

     objects_list:
     find-objects-bf (@mc->items | geta 0 | get "find") 
                     root=@mc->root
                     recursive=false
                     include_root=false debug=true
     | sort_by_priority;

		@objects_list->output | repeater {
   		rep: row {
   			button (@rep->input | geta "title") style='min-width:220px;'
   			{
		       m_lambda "(obj,g2) => { obj.emit('show-settings',g2) }" @mc->vp (@rep->input | geta "gui");
   			};
   			k: checkbox-c value=(@rep->input | geta "visible")
   			   {{ x-on 'user-changed' {
   			   	  m_lambda "(obj,obj2,val) => {
   			   	    //console.log('setting visible to obj',obj,val );
   			   	    obj.setParam('visible', val, true);
   			   	  }" @rep->input;
   			   } }};
   		};
   	};
   	
    };
};
