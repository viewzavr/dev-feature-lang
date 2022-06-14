load "params";

// кстати вот интересно - сейчас фильтрация сделана в загрузчике и это неплохо
// но получается на уровне визуального объекта фильтр на дныне не добавить..
// можно было бы - но тогда каждый визобъект будет фильтровать и если их 2 одинаковых то каждый будет
// по идее надо научиться на уровне данных - добавлять фильтры визуально.
// а виз объекты уже к ним цепляются.

find-objects-bf features="render_project_right_col" recursive=false 
|
insert_children { manage_vir; };

feature "manage_vir" {
	ma: 
	    project=@..->project
	    curview=@..->active_view

	collapsible "Проект 'Вирусы'" {
		column plashka {
			text "Добавить:";
			button_add_object "Визуализация вирусов" 
			   add_to=@ma->project
			   add_type="vis-1"
			   {{
			   	 created_add_to_current_view curview=@ma->curview;
			   }};

			button_add_object "Загрузка файла вирусов" 
			   add_to=@ma->project
			   add_type="source"
			   {{
			   	 created_add_to_current_view curview=@ma->curview;
			   }};   

		};
	};
};

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
    //files=(resolve_url "data/H3N2_D100_1-fixed.json")
    {{ x-param-files name="files" }}

/*
    {{ x-param-combo name="file" 
           titles=(@listing->output | arr_map code="(val) => val[0]") 
           values=(@listing->output | arr_map code="(val) => val[1]") 
    }}
*/
	  {{ pc: param_combo name="file" 
           titles=(@qqe->current_listing | arr_map code="(val) => val[0]") 
           values=(@qqe->current_listing | arr_map code="(val) => val[1] || val[0]")
           index=0
    }}
    current_file_name=(@pc->titles | geta @pc->index)
    scene2d=@scene2d
    current_listing=( @qqe->files or @listing->output)
    //current_listing=@listing->output
    {
				scene2d: dom {
			  		text tag="h2" style="color:white;margin:0;" (m_eval "(s) => s.split('.')[0]" @qqe->current_file_name)
			  		;
				};

    	 listing: select-files-inet listing_file="https://viewlang.ru/assets/majid/2022-06/list.txt";

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
		   
		   @data->output? | geta "spheres" 
		     | 
		     df_create_from_arrays columns=["X","Y","Z","RADIUS"]
		     |
		    pts: spheres-vp title="spheres"
		     radius=5
		     color=[1,0,0]
		     //{{ x-param-slider name="radius" min=0.01 max=0.25 step=0.01 }}
		     ;

		   @data->output? | geta "lines" 
		     | 
		     df_create_from_arrays columns=["X","Y","Z","X2","Y2","Z2"]
		     |
		    lines: lines-vp title="lines"
		      color=[0.75, 0.75, 0.85]
		     //radius=0.02 
		     //{{ x-param-slider name="radius" min=0.01 max=0.25 step=0.01 }}
		     ;  

 				@data->output? | geta "labels" 
		     | 
		     df_create_from_arrays columns=["X","Y","Z","TEXT"]
		     |
		    text3d-lines-vp title="labels"
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
