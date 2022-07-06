load "params";

// кстати вот интересно - сейчас фильтрация сделана в загрузчике и это неплохо
// но получается на уровне визуального объекта фильтр на дныне не добавить..
// можно было бы - но тогда каждый визобъект будет фильтровать и если их 2 одинаковых то каждый будет
// по идее надо научиться на уровне данных - добавлять фильтры визуально.
// а виз объекты уже к ним цепляются.

find-objects-bf features="render_project_right_col" recursive=false 
|
insert_children { manage_astra; };

feature "manage_astra" {
	ma: 
	    project=@..->project
	    curview=@..->active_view

	collapsible "Проект Astra" {
		column plashka {
			text "Добавить:";
			button_add_object "Визуализация звёзд" 
			   add_to=@ma->project
			   add_type="astra-vis-1"
			   {{
			   	 created_add_to_current_view curview=@ma->curview;
			   }};

			button_add_object "Загрузка файла звёзд" 
			   add_to=@ma->project
			   add_type="astra-source"
			   {{
			   	 created_add_to_current_view curview=@ma->curview;
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

register_feature name="render-guis-a" {
  rep: repeater opened=true {
    das1: column {
            button text=@btntitle->output cmd="@pcol->trigger_visible" 
             {{ deploy input=@rep->button_features? }};

          pcol: column visible=false { /* @../../..->opened */
            render-params object=@das1->modelData;
            btntitle: compute_output object=@../..->modelData code=`
              return env.params.object?.params.gui_title || env.params.object?.ns.name;
            `;
            manage_addons @das1->input;
          }
          
        };
    };
};

////////////////////////////

feature "astra-source" {
  qqe: visual_process 
    title="Загрузка звёзд"
    index=1 	
    gui={
    	column plashka {
    		//render-params @astrafiles;
    		column {
      		insert_children input=@.. list=@astrafiles->gui;
    	  };
    	  render-params @astradata;
      };
    } 
    N=@astradata->N
    
    output=(list @dust->output @star->output @planet->output)
    {
			scene2d: dom {
			  		//text tag="h2" style="color:white;" (join (@listing->output | geta @astradata->N));
			  		text tag="h2" style="color:white;margin:0;" @astradata->current_file_name;
			  		
			};

			//astrafiles: select-files url="http://127.0.0.1:8080/vrungel/public_local/data1/list.txt";
			astrafiles: select-files url="https://viewlang.ru/assets/astra/data1/list.txt";

			astradata: N=0 
			    //files=[] 
			    //files_url="https://viewlang.ru/assets/astra/data/list.txt"
			    files=(@astrafiles->output | arr_filter code="(rec) => rec.name.match(/.dat$/i)")
			  // {{ x-param-files name="files"}}
			  {{ x-param-option name="files" option="priority" value=10 }}
			  {{ x-param-option name="files" option="values" value=["https://viewlang.ru/assets/astra/data/list.txt"] }}
			  
				{{ x-param-slider name="N" sliding=false min=0 max=((@astradata->files | geta "length") - 1) }}
				
				{{ x-param-label-small name="files_count"}}
				{{ x-param-label-small name="current_file_name"}}
				{{ x-param-option name="current_file" option="readonly" value=true }}

				{{ x-param-label-small name="lines_loaded"}}
				current_file=(@astradata->files | geta @astradata->N default='') // файл
		    current_file_name=(@astradata->files | geta @astradata->N default='' | geta 'name' default='') // символ имени
		    lines_loaded=(@loaded_data2->output | geta "length")
		    files_count=(@astradata->files | geta "length")

				{{ x-param-label-small name="dust_count"}}
		    dust_count = (@dust->output | geta "length")
		    {{ x-param-label-small name="star_count"}}
		    star_count = (@star->output | geta "length")
		    {{ x-param-label-small name="planet_count"}}
		    planet_count = (@planet->output | geta "length")
      {
      	 loaded_data2: load-file file=(@astradata->current_file or null)
         	| + 'X Z Y DENSITY ID TYPE\n' + @.->input // F-CHANGE-DATA-AXES
			   	| parse_csv separator="\s+" df56;

			   dust: @loaded_data2->output | df_filter "(line) => line.ID < 1000000";
			   star: @loaded_data2->output | df_filter "(line) => line.ID == 1000000";
			   planet: @loaded_data2->output | df_filter "(line) => line.ID == 1000001";
			};
    };
	  //astra-source-dir;
};

feature "astra-camera-rotate" {
	avp: visual_process
	title="Вращение камеры и N"
	project=@..
	gui={
		ko: column plashka {
			/*
			text "Источник данных";
 		  render-params @astradata;
 		  text "Целевая камера";
 		  //render-params-list object=@avp list=["camera"];
 		  */
 		  render-params @avp;
	  };
	}
	gui3={
		render-params @avp;
	}
	
	{{ x-param-objref-3 name="astra_source" values=(@avp->project | find-objects-bf features="astra_source") }}
	{{ x-param-objref-3 name="camera" values=(@avp->project | geta "cameras") }}
	{{ x-param-slider name="start_angle" min=0 max=360 }}
	{{ x-param-slider name="coef" min=0 max=100 step=0.1 }}
	{{ x-param-label name="theta"}}
	start_angle=0
	coef=3.6
	theta=(m_eval "(n,start,coef) => {
					  if (isFinite(n) && isFinite(start) && isFinite(coef))
					    return coef*n+start;
					  return 0;
					}" (@avp->astra_source |geta "N") @avp->start_angle @avp->coef)
	{
		//astradata: find-data-source;

		if (@avp->visible) then={
			@avp->camera | x-modify {
				x-set-params theta=@avp->theta;
			};
	  };

			scene2d: dom {
			  		text tag="h4" style="color:white;margin:0;" (+ "theta=" @avp->theta);
			};	  
	}
};

feature "astra-vis-1" {
	avp: visual_process
	title="Визуализация звёзд"
	dust_mode=0
	gui={
		
		//find-objects-by-crit "visual_process" root=@scene recursive=false | render-guis-a;
		ko: column plashka {

		  /*
			collapsible "Источник данных" {
  		  render-params @astradata;
	    };
	    */

	    render-params @astradata;


	    text "Раскраска частиц:";
			ssr_dust_color: 
			   switch_selector_row
               index=@avp->dust_mode
               items=["Плотность","Сложение цветов","Выкл"]
               style_qq="margin-bottom:15px;" {{ hilite_selected }}
               {{ m_on "param_index_changed" "(obj,sending_obj,v) => obj.setParam('dust_mode',v,true);" @avp }}
               ;
/* тоже рабочий вариант но ненадежный пока
		  l1: csp {
		  	when @ssr_dust_color "param_index_changed" then={ |v|
		  		a: call @avp "setParam" "dust_mode" @v auto_apply;
	  			when @a "done" then={
	  			  restart @l1;
	  			};
		  	};
		  };
*/

/*
			show_sources_params 
			  input=(find-objects-by-crit "visual-process" root=@scene include_root=false recursive=false)
			  auto_expand_first=false
			;*/

			manage-content @scene
       root=@avp
       title="Слои"
       allow_add=false
       vp=@avp
       items=[{"title":"Скалярные слои", "find":"visual-process"}];
	  };

	  //{{ x-add-cmd2 "сложение_цветов" }}



	}
	gui3={
		render-params @avp;
	}
	scene3d=@scene->output
	scene2d=@scene2d->output
	{

		astradata: find-data-source features="astra_source";

		scene2d: dom_group input=(find-objects-bf features="viewzavr-object" root=@scene include_root=false | map_geta "scene2d" default=null | arr_compact)
		;

		scene: node3d visible=@avp->visible force_dump=true
		{

//			 dust_color_logic: csp {
//			 	 when @
//			 }

				//mesh positions=[0,0,0, 10,10,10, 0,10,0 ];

		   // 218 201 93 цвет
		   @astradata->output | geta 0 | pts_dust: points title="Частицы" visual-process editable-addons 
		     addons_tab_expanded=true
		     radius=0.02 color=[0.85, 0.78, 0.36] 
		     {{ x-param-slider name="radius" min=0.01 max=0.25 step=0.01 }}
		     // слайдер сделан специально чтобы не указать слишком больших значений
		     gui={ render-params @pts_dust; manage-addons @pts_dust; };

		   @astradata->output | geta 1 | pts_star: spheres-vp title="Звезда" visual-process editable-addons 
		     //src="https://viewlang.ru/assets/planets/Sun_1_1391000.glb"
		     //src="https://viewlang.ru/assets/models/Lake_IV_Heavy.glb" 
		     //src="https://viewlang.ru/assets/planets/Mars_1_6792.glb"
		     radius=0.15 color=[1,0,0]
		     {{ x-param-slider name="radius" min=0.01 max=1 step=0.001 }}
		     //{{ x-param-slider name="radius" min=0.001 max=1 step=0.001 }}
		     //gui={ render-params @pts_star; manage-addons @pts_star; }
		     ;

		     // 107 123 279
		   @astradata->output | geta 2 | pts_planet: spheres-vp title="Планета"
		     radius=0.03 color=[0.42,0.5,0.93] 
		     {{ x-param-slider name="radius" min=0.01 max=1 step=0.001 }}
		     addons={ effect3d-opacity opacity=0.5; }
		     ;

		   //insert_children input=@pts_dust->addons_container active=(is_default @pts_dust->addons_container) list=@coloring_variants->density;


		   insert_children input=@pts_dust->addons_container 
		      list=( (list @coloring_variants->density @coloring_variants->additive []) | geta @avp->dust_mode);

		   coloring_variants:
		     additive={ // F-PIXEL-PRESET
						effect3d_sprite sprite="disc.png";
		   	 	  effect3d_additive;
		   	 		effect3d_zbuffer depth_test=false;
		   	    effect3d-opacity opacity=0.25 alfa_test=0;		     	
		     }
		     density={
		     	  effect3d_colorize selected_column="DENSITY" datafunc="sqrt4" tab_expanded=true show_palette_on_screen=true;
		     	  // x-set-params radius=0.015;
		     	  // effect3d_sprite sprite="circle.png";
		     };


/*
		   m_density: x-modify {
		   		effect3d_colorize selected_column="DENSITY" datafunc="sqrt4";
		   };

		   m_additive: x-modify {
						effect3d_sprite sprite="disc.png";
		   	 	  effect3d_additive;
		   	 		effect3d_zbuffer depth_test=false;
		   	    effect3d-opacity opacity=0.25 alfa_test=0;
		   };
*/

		   //k1: recreator input=@pts_dust->addons_container;

/*
		   insert_children input=@pts_star->addons_container active=(is_default @pts_star->addons_container) list={
		   	 // F-PIXEL-PRESET
		   	 //effect3d_sprite sprite="ball.png";
		   	 //effect3d-scale x=@pts_star->radius y=@pts_star->radius z=@pts_star->radius;
		   };

		   insert_children input=@pts_planet->addons_container active=(is_default @pts_planet->addons_container) list={
		   	 // F-PIXEL-PRESET
		   	 // effect3d_sprite sprite="ball.png";
		   	 //effect3d-scale x=@pts_star->radius y=@pts_star->radius z=@pts_star->radius;
		   };
*/		   

		   // вообще может оказаться что это будет отдельный визуальный процесс - "антураж"
		   // ab: axes_view size=1;

		};
	};
};

register_feature name="joinlines" code=`
  env.on("param_changed",(name) => {
    if (name == "output") return;
    compute();
  });
  
  function compute() {

    let count = env.params.args_count;
    let arr = [];
    for (let i=0; i<count; i++)
      arr.push( env.params[ i ] );
    let res = arr.join( env.params.with || "\\n" ); // по умолчанию пустой строкой
    env.setParam("output",res );
  };
  
  compute();
`;

