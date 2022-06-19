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

// вход - взаимодействие с пользователем либо файл list.txt
// выход - список vtk_files, obj_files

feature "vtk-data-package" {
  qqe: visual_process
    title="Загрузка пакета данных лавы"
    gui={
    	column plashka {
    		
    		column {
      		insert_children input=@.. list=@files->gui;
    	  };

    	  render-params @qqe filters={ params-hide list="title"; };
      };
    }
    //url="http://127.0.0.1:8080/vrungel/public_local/Kalima/list.txt"
    url="https://viewlang.ru/assets/lava/Etna/list.txt"
    dictionary_urls=["http://127.0.0.1:8080/vrungel/public_local/Kalima/list.txt"]

    vtk_files=(@files->output | arr_filter code="(rec) => rec[0].match(/\.vtk/i)")
    obj_files=(@files->output | arr_filter code="(rec) => rec[0].match(/\.obj/i)")

    {{ x-param-label-small name="all_files_count"}}
		{{ x-param-label-small name="vtk_files_count"}}
		{{ x-param-label-small name="obj_files_count"}}
		vtk_files_count=(@qqe->vtk_files | geta "length")    
		obj_files_count=(@qqe->obj_files | geta "length")
		all_files_count=(@files->output | geta "length")
    {
			files: select-files url=@qqe->url;
    };
};

// input - список файлов
// output - выбранный файл
feature "select-file-by-n" {
	q: visual_process
	   title="Выбор файла"
	   gui={ column plashka {
				   	render-params @q filters={ params-hide list="title"; }
				   	;
				   } 
				 }
	   N=0
				{{ x-param-slider name="N" sliding=false min=0 max=((@q->input | geta "length") - 1) }}
				
				{{ x-param-label-small name="fname"}}
				{{ x-param-option name="current_file" option="readonly" value=true }}
				{{ x-param-option name="N" option="priority" value=10 }}
				{{ x-param-option name="fname" option="priority" value=20 }}

				current_file=(@q->input | geta @q->N default=[] | geta 1 default=null)
		    fname=(@q->input | geta @q->N default=[] | geta 0 default=null)

		    output=@q->current_file

		scene2d=@scene2d
		{
			scene2d: dom style="" {
			  		text tag="h2" style="color:white;margin:0;" @q->fname;
			};
		}
	;  
};

// input - путь к файлу или объект файла
// output - df-ка с данными
feature "load-vtk-file" {
	loader: df56 visual-process title="Загрузчик файла VTK"
				gui={
					column plashka {
						render-params @loader filters={ params-hide list="title"; };
					};
				}
				{{ x-param-label-small name="points_loaded"}}
		    points_loaded=(@loader->output | geta "length")
		    output= @l->output
		    {
      	l: load_file_binary file=@loader->input
      	    | parse_vtk_points
      	    | compute_magnitude_col; // туду это должна быть добавка
      	}    
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


feature "lava-group" {
		vp: visual_process
		  title="Расчёты по лаве"
		  //scene2d=(list @cur->scene2d @vis->scene2d?)
		  scene2d=(list @cur->scene2d @vis->scene2d)
		  
		  //scene2d=@s->scene2d
		  scene3d=(list @vis->scene3d @visobj->scene3d)
		  //scene3d=(list @vis->scene3d)
		  //scene3d=@vis->scene3d
		  //{{ console_log_params "RRR" }}
		  gui={
		  	column style="padding-left: 1em;" {
		  	  //show_sources_params input=(list @s @cur @load @vis @visobj);
		  	  show_sources_params input=(list @s @cur @vis @visobj);
		  	  //show_sources_params input=@s;
		  	  //show_sources_params input=@vis;
		    };
		  	//insert_children input=@.. list=@.->0;
		  	//render-gui @s->gui;
		  	//render-gui @vis->gui;
		  }
		  gui3={
		  	render-params @vp;
		  }
		  {{ x-on "cocreated" {
		  		setter target="@vis->initial_input_link" value=(+ (@load | geta "getPath") "->output");
		  	} }}
		  {
		  	//s: vtk-source;
		  	s: vtk-data-package;

		  	cur: select-file-by-n 
		  	    input=@s->vtk_files 
		  	    title="Выбор N";

		  	load: load-vtk-file input=@cur->output;

/*
		  	vis: vtk-vis show_source=false; 
			  	     //initial_input_link=(+ (@load | geta "getPath") "->output");
*/

				vis: vis-many title="Колонки данных VTK" find="vtk-vis-1" add="vtk-vis-1" 
				points_loaded=(@load->output | geta "length")
				{{ x-param-label-small name="points_loaded" }}

				gui0={ render-params plashka @vis filters={ params-hide list=["title","visible"]; }; }
		  	{
  	  		vtk-vis-1 
  			      input=@load->output
  			      title=@.->selected_column
  			      selected_column="visco_coefs"
  			      show_source=false; // эт начальное
  			;
		  	};
				insert_children input=@vis->addons_container active=(is_default @vis) list={
						effect3d-delta dz=5;
				};		  	


		  	visobj: vis-many title="OBJ-файлы" find="obj-vp" add="obj-vp" 
		  	{
		  	  repeater input=@s->obj_files { 
		  	    i: obj-vp
  							  file=(@i->input | geta 1)
  							  title=(@i->input | geta 0);
		  	  };
		  	};

		  };
};

feature "obj-vp" {
		it: visual_process title='obj' 
		scene3d=@mesh->scene3d 
		gui={

			render-params @it filters={ params-hide list="title"; };

			insert_children input=@.. list=@mesh->gui;
			
			//text "positions"
		}
		{{ x-param-file name="file" }}
		visible=@mesh->visible
		{
  			loadobj: load_file file=@it->file | parse_obj;
	  		mesh: mesh-vp input=@loadobj->output?
	  		  visible=@it->visible;
 	  };
};

// визуальный процесс изображающий группу
// find - описание рисователя строчкой
// add - описание рисователя строчкой

feature "vis-many" 
{
	vp: visual_process
	title="Изображение группы"
	show_settings_vp=@vp

	gui={
		column style="padding-left:0em;" {

			column {
			  insert_children input=@.. list=@vp->gui0?;
		  };
		  /*
			cp: column plashka visible=( > (@cp | get_children_arr | geta "length") 1) 
			{
			  render-params @vp filters={ params-hide list=["title","visible"]; }; 
		  };
		  */

	    manage-content @vp 
	       vp=@vp->show_settings_vp
	       title="" 
	       items=(m_eval `(t,t2) => { return [{title:"Скалярные слои", find:t, add:t2}]}` 
	       	      @vp->find @vp->add)
	       ;

	    manage-addons @vp;

    };
	}
	generated_processes=(find-objects-bf root=@vp features="visual-process" include_root=false recursive=false)
  scene2d=(@vp->generated_processes | map_geta "scene2d" default=null)

  scene3d=@vp->output
  
  node3d 
  editable-addons
  // авось прокатит
  {
  };

};


// тут у нас и раскраска и доп.фильтр встроен. ну ладно.
// и это 1 штучка

feature "vtk-vis-1" {
	avp: visual_process
	//title="Визуализация VTK точек"
	input=@vtkdata->output
	output=@avp->scene3d
	show_source=true
	title=(@avp->selected_column or "Слой точек")

    columns=(@avp->input | geta "colnames")
    selected_data = (geta input=@avp->input @avp->selected_column default=[])
    selected_column=""
    {{ x-param-combo name="selected_column" values=@avp->columns }}
    //{{ selected_column: param_combo values=@avp->columns index=0; }}

	gui={
		
		ko: column plashka {

			// render-params-list object=@avp list=["visible"];
			//checkbox "visible" value=@avp->visible
			//{{ x-on "user-changed" "(obj) => obj.setParam('visible',!obj.params.visible, true) " }}

			collapsible "Источник данных" visible=@avp->show_source{
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

		   //insert_children input=@pts->addons_container active=(is_default @pts->addons_container) list={
		   	 // F-PIXEL-PRESET
		   	 // effect3d_sprite sprite="disc.png";
		   //};

		   // вообще может оказаться что это будет отдельный визуальный процесс - "антураж"
		   //ab: axes_view size=1;

/*
		   tx: text3d_vp text=@avp->selected_column
		   {{
          box: get_coords_bbox input=@pts->output;
				  effect3d-pos x=(@box->max | geta 0) y=(@box->max | geta 1) z=(@box->max | geta 2);
       }};
*/       

		};
	};
};