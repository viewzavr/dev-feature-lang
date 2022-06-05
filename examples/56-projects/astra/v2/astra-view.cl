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
			button_add_object "Просмотр Astra" 
			   add_to=@ma->project
			   add_type="astra-vis-1"
			   {{
			   	 created_add_to_current_view curview=@ma->curview;
			   }};

			/*
			на пути к добавлению произвольных цепочек
			button "Добавить просмотр Astra" {
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

feature "astra-vis-1" {
	avp: visual_process
	title="Визуализация звёзд"
	gui={
		render-params @astradata plashka;
		//find-objects-by-crit "visual_process" root=@scene recursive=false | render-guis-a;
		ko: column plashka {
			show_sources_params input=(find-objects-by-crit "visual-process" root=@scene include_root=false recursive=false)
			;

			/*
			
			|
			repeater {
				k: { 
					 insert_children input=@ko list=(@k->input | geta "gui");
				};
			};
			*/
	  };
	}
	gui3={
		render-params @avp;
	}

	scene3d=@scene->output
	{

		astradata:  N=0
		  {{ x-param-slider name="N" sliding=false min=0 max=((@listing->output | geta "length") - 1) }}

		  listing_file="http://127.0.0.1:8080/public_local/data2/data.csv"

			current_file=( join "http://127.0.0.1:8080/public_local/data2/" (@listing->output | geta @astradata->N) )
			//current_file="http://127.0.0.1:8080/public_local/data2/gout_001.csv"
			{{ x-param-file name="current_file"; }}

			lines_loaded=(@loaded_data->output | geta "length")
			{{ x-param-label name="lines_loaded"}}
		{
			listing: load-file file=@astradata->listing_file | parse_csv | df-get "FILE_points_astra";
			//loaded_data: load-file file=@astradata->current_file | parse_csv;
			loaded_data: load-file file=@astradata->current_file | parse_csv;
    };

//      	loaded_data: load-file file=@avp->current_file | joinlines "X Y Z" @.->input | parse_csv separator="\s+";

		scene: node3d visible=@avp->visible force_dump=true
		{

		   // 218 201 93
		   @loaded_data->output | 
		     pts: points title="Точки" visual-process editable-addons 
		     radius=0.02 color=[0.85, 0.78, 0.36] 
		     gui={ render-params @pts; manage-addons @pts; };

		   //console_log "positions are" @pts->positions;

		   // вообще может оказаться что это будет отдельный визуальный процесс - "антураж"
		   ab: axes_view size=1 visible=false;

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