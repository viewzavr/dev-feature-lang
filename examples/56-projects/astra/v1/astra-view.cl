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

feature "astra-vis-1" {
	avp: visual_process
	title="Визуализация звёзд N1"
	gui={
		render-params @avp;
		find-objects-bf "lib3d_visual" root=@scene | render-guis;
	}
	gui3={
		render-params @avp;
	}
	current_file="http://127.0.0.1:8080/public_local/data2/gout_001.csv"
	{{ x-param-file name="current_file"; }}

	lines_loaded=(@loaded_data->output | geta "length")
	{{ x-param-label name="lines_loaded"}}

	scene3d=@scene->output
	{
//      	loaded_data: load-file file=@avp->current_file | joinlines "X Y Z" @.->input | parse_csv separator="\s+";
      	loaded_data: load-file file=@avp->current_file | parse_csv separator=",";

		scene: node3d visible=@avp->visible force_dump=true
		{
		   // вообще может оказаться что это будет отдельный визуальный процесс - "антураж"
		   ab: axes_box size=10;

		   @loaded_data->output | pts: points;

		   //console_log "positions are" @pts->positions;
		};
	}
};
