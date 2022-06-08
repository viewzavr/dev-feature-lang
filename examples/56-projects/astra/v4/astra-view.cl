load "params";


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

			button_add_object "Полёт камеры" 
			   add_to=@ma->project
			   add_type="camera-fly-vp"
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
  qqe: visual_process df56 
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
    
    output=@loaded_data2->output
    {
			scene2d: dom {
			  		//text tag="h2" style="color:white;" (join (@listing->output | geta @astradata->N));
			  		text tag="h2" style="color:white;" @astradata->current_file_name;
			  		
			};

			astrafiles: select-files url="https://viewlang.ru/assets/astra/data/list.txt";

			astradata: N=0 
			    //files=[] 
			    //files_url="https://viewlang.ru/assets/astra/data/list.txt"
			    files=@astrafiles->output
			  // {{ x-param-files name="files"}}
			  {{ x-param-option name="files" option="priority" value=10 }}
			  {{ x-param-option name="files" option="values" value=["https://viewlang.ru/assets/astra/data/list.txt"] }}
			  
				{{ x-param-slider name="N" sliding=false min=0 max=((@astradata->files | geta "length") - 1) }}
				
				{{ x-param-label-small name="files_count"}}
				{{ x-param-label-small name="current_file_name"}}
				{{ x-param-option name="current_file" option="readonly" value=true }}

				{{ x-param-label-small name="lines_loaded"}}
				current_file=(@astradata->files | geta @astradata->N | geta 1)
		    current_file_name=(@astradata->files | geta @astradata->N | geta 0)
		    lines_loaded=(@loaded_data2->output | geta "length")
		    files_count=(@astradata->files | geta "length")
      {
      	 loaded_data2: load-file file=(@astradata->current_file or null)
         	| m_eval "() => 'X Z Y\n' + env.params.input" // F-CHANGE-DATA-AXES
			   	| parse_csv separator="\s+";
			};   
    };
	  //astra-source-dir;
};

// объект который дает диалог пользвателю 
// а в output выдает найденный dataframe отмеченный меткой df56
feature "find-data-source" {
   findsource: 
      data_length=(@findsource->output | geta "length")
	    input_link=(@datafiles->output | geta 0)
      {{
          datafiles: find-objects-bf features="df56" | arr_map code="(v) => v.getPath()+'->output'";

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

feature "astra-vis-1" {
	avp: visual_process
	title="Визуализация звёзд"
	gui={
		
		//find-objects-by-crit "visual_process" root=@scene recursive=false | render-guis-a;
		ko: column plashka {

			collapsible "Источник данных" {
  		  render-params @astradata;
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

	{

		astradata: find-data-source;

		scene: node3d visible=@avp->visible force_dump=true
		{

		   // 218 201 93
		   @astradata->output | pts: points title="Точки" visual-process editable-addons 
		     radius=0.02 color=[0.85, 0.78, 0.36] 
		     {{ x-param-slider name="radius" min=0.01 max=0.25 step=0.01 }}
		     // слайдер сделан специально чтобы не указать слишком больших значений
		     gui={ render-params @pts; manage-addons @pts; };

		   insert_children input=@pts->addons_container active=(is_default @pts->addons_container) list={
		   	 // F-PIXEL-PRESET
		   	 effect3d_sprite sprite="disc.png";
		   	 effect3d_additive;
		   	 effect3d_zbuffer depth_test=false;
		   	 effect3d-opacity opacity=0.25 alfa_test=0;
		   };

		   //console_log "positions are" @pts->positions;

		   // вообще может оказаться что это будет отдельный визуальный процесс - "антураж"
		   ab: axes_view size=1;

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
    let res = arr.join( env.params.with || "\n" ); // по умолчанию пустой строкой
    env.setParam("output",res );
  };
  
  compute();
`;