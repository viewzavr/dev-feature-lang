load "params";

// кстати вот интересно - сейчас фильтрация сделана в загрузчике и это неплохо
// но получается на уровне визуального объекта фильтр на дныне не добавить..
// можно было бы - но тогда каждый визобъект будет фильтровать и если их 2 одинаковых то каждый будет
// по идее надо научиться на уровне данных - добавлять фильтры визуально.
// а виз объекты уже к ним цепляются.

/*
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

		};
	};
};
*/

////////////////////////////

feature "source" {
  qqe: visual_process 
    title="Загрузка данных"
    index=1 	
    gui={
    	column plashka {
    	  render-params @qqe
    	    filters={ params-hide list="title"; };
      };
    } 
    output=@loaded_data->output?
    df56
    file=(resolve_url "data/H3N2_D100_1-fixed.json")
    
    {{ x-param-file name="file" }}
    {
     	 loaded_data: m_eval "JSON.parse" (load-file file=@qqe->file);
    };
};

feature "vis-1" {
	avp: visual_process
	title="Визуализация вирусов"
	gui={
		
		//find-objects-by-crit "visual_process" root=@scene recursive=false | render-guis-a;
		ko: column plashka {

	    render-params @data;

			manage-content @scene
       root=@avp
       allow_add=false
       vp=@avp
       items=[{"title":"Визуальные слои", "find":"visual-process"}];
	  };
	}
	gui3={
		render-params @avp;
	}
	scene3d=@scene->output

	{

		data: find-data-source features="df56";

		scene: node3d visible=@avp->visible force_dump=true
		{

		   
		   @data->output | geta "spheres" 
		     | 
		     df_create_from_arrays columns=["X","Y","Z","RADIUS"]
		     | console_log_input
		     |
		    pts: spheres-vp title="spheres"
		     radius=5
		     //{{ x-param-slider name="radius" min=0.01 max=0.25 step=0.01 }}
		     ;

		   @data->output | geta "lines" 
		     | 
		     df_create_from_arrays columns=["X","Y","Z","X2","Y2","Z2"]
		     | console_log_input
		     |
		    lines: linestrips-vp title="lines"
		      color=[0.75, 0.75, 0.85]
		     //radius=0.02 
		     //{{ x-param-slider name="radius" min=0.01 max=0.25 step=0.01 }}
		     ;  

 				@data->output | geta "labels" 
		     | 
		     df_create_from_arrays columns=["X","Y","Z","TEXT"]
		     | console_log_input
		     |
		    text3d-vp title="labels"
		      size=0.01
		     //radius=0.02 
		     {{ x-param-slider name="size" min=0.01 max=0.25 step=0.01 }}
		     ;  		     

/*
		   insert_children input=@pts_dust->addons_container active=(is_default @pts_dust->addons_container) list={
		   	 // F-PIXEL-PRESET
		   	 effect3d_sprite sprite="disc.png";
		   	 effect3d_additive;
		   	 effect3d_zbuffer depth_test=false;
		   	 effect3d-opacity opacity=0.25 alfa_test=0;
		   };
*/		   

		};
	};
};
