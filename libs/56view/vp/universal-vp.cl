find-objects-bf features="render_project_right_col" recursive=false 
|
insert_children { manage_universal_vp; };

feature "compute_title" {
  r: object output=@q->output {
    q: m-eval "(t,a,b) =>
       {
          
          let ind = a.indexOf(t); 
          return b[ind];
       }" @r->key @r->types @r->titles;
  };
};

feature "manage_universal_vp_co" {}; // тпу

feature "manage_universal_vp" {
  ma:  collapsible "Универсальное"
      project=@..->project
      curview=@..->active_view
   {
    column ~plashka ~manage_universal_vp_co 
       curview=@ma->curview project=@ma->project
    {
      text "Добавить:";

      button_add_object "Полёт камеры" 
         add_to=@ma->project 
         add_type="camera-fly-vp"
         {{
           created_add_to_current_view curview=@ma->curview;
         }};
      /* решил пока мозг не выносить. пусть будет что будет.
      
      button_add_object "Добавить 3d образ" 
         add_to=@ma->project 
         add_type="elinestr"
         {{
           created_add_to_current_view curview=@ma->curview;
         }};

      button_add_object "Добавить вычисление" 
         add_to=@ma->project 
         add_type="ecompute1"
         {{
           created_add_to_current_view curview=@ma->curview;
         }};

      button_add_object "Добавить синхронизацию" 
         add_to=@ma->project 
         add_type="esync1"
         {{
           created_add_to_current_view curview=@ma->curview;
         }};

      button_add_object "Добавить файл" 
         add_to=@ma->project 
         add_type="linesetc_file"
         {{
           created_add_to_current_view curview=@ma->curview;
         }};

         
      button_add_object "Добавить группу" 
         add_to=@ma->project 
         add_type="group-vp"
         {{
           created_add_to_current_view curview=@ma->curview;
         }};
         */

      button_add_object "Оси координат" 
         add_to=@ma->project 
         add_type="axes-view"
         {{
           created_add_to_current_view curview=@ma->curview;
         }};              

	  button_add_object "Визуальный процесс общего назначения" 
         add_to=@ma->project 
         add_type="universal_vp"
         {{
           created_add_to_current_view curview=@ma->curview;
         }};

    };
  };
};

feature "df56";

feature "linesetc-file" {
  view: visual_process ~df56
    title="Файл" 
    visible=true 
    output=@loaded_data->output
    ~efile

    // todo это не df 56 в будущем

  gui={
    column ~plashka {
        text "Укажите текстовый файл с данными";
        render-params  input=@fileparams;
    };
  }
  gui3={
    render-params @view;
  }
  {
    fileparams: object 
      separator=","
      {{ x-param-string name="separator"}}
    {
      //f1_info: param_label "Укажите текстовый файл с данными";
      f1:  param_file;
      lines_loaded: param_label (@loaded_data->output | geta "length" default=0);

      loaded_data: load-file file=@fileparams->f1
             | parse_csv separator=@fileparams->separator;

      // on изменение в выборе файла - перейти в вид1
      // но опять же - при старте программы это изменение тоже происходит.. 

    };

  }
};

feature "universal_vp" 
{
  view: visual_process title="Визуальный процесс" visible=true 
  
  //time_index=@timeparams->time_index

  scene3d=( if ( > @scene->object3d_count 0) then={@scene->output} )
  scene2d=@screen_space

  gui3={ render-params @view }
  {{ x-param-string name="title" }}

  gui={
    render_layers_inner title="Визуальные объекты" expanded=true
           root=@view
           items=[ { "title":"3d графика", 
                     "find":"edatavis",
                     "add":"elinestr",
                     "add_to": "@scene->."
                   },

                   {"title":"Текстовые написи",
                    "find":"escreenvis",
                    "add":"eh2",
                    "add_to":"@screen_space->."
                   },

                   {"title":"Вычисления",
                    "find":"ecompute",
                    "add":"ecompute1",
                    "add_to": "@ecomputescene->."
                   },

                   {"title":"Файлы данных",
                    "find":"linesetc-file",
                    "add":"linesetc-file",
                    "add_to": "@ecomputescene->."
                   },

                   {"title":"Синхронизация",
                    "find":"esync",
                    "add":"esync1",
                    "add_to": "@ecomputescene->."
                   }
                 ]
           ;
  }
    /*
        row {
          object_change_type input=@co->input
            types=(@co->input | get_param "sibling_types" )
            titles=(@co->input | get_param "sibling_titles");
        };

        column {
          insert_children input=@.. list=(@co->input | get_param name="gui");
        };
    */
  
  {

    ecomputescene: object force_dump=true project=@view->project;

    scene: node3d visible=@view->visible force_dump=true
    {
        ob1: lines input=@data56->output;
        //ob1: elinestr;

        // вообще может оказаться что это будет отдельный визуальный процесс - "антураж"
  	};

    // ну вот... как бы это.. а мы бы хотели...

    insert_children input=@screen_space list=@view->scene2d_items active=(is_default @screen_space);
    // это у нас место куда будут добавляться объекты пользователем
    screen_space: dom visible=@view->visible force_dump=true
    {
    };

  };

};

///////////////////////////
///////////////////////////
/////////////////////////// наполнение

elinestr: feature {
  main: linestrips ~edatavis
     _gui={ 
       render-params input=@main;
      };
};

eptstr: feature {
  main: points ~edatavis _gui={ render-params input=@main };
};
    
// вход input это dataframe
emodels: feature {
    root: render_models ~edatavis _gui={ render-params input=@root }
        {
        };
};

feature "emesh" {
        main: mesh ~edatavis _gui={ render-params input=@main; }
       ;
};

/////////////////////////////// надписи для экрана
// todo опора на vroot
// 

// параметр: time
feature "eh2" {
  sv: escreenvis ~dom tag="h2" style="color: white; margin: 0;"
     {{ x-param-string "innerText" }};
};

feature "etext" {
  sv: escreenvis ~dom style="color: white; margin: 0;"
     {{ x-param-string "innerHTML" }};
};

/////////////////////////// суммарная информация

edatavis: feature {
  rt: 
    visual_process
    input=@data56->output 
    
    gui={
      render-params @fileparams;
      render-params @rt;
    }

    sibling_types=["elinestr","eptstr","emodels","emesh"] 
    sibling_titles=["Ломаная","Точки","Модели","Меш"]
    title=(join 
//              (compute_title key=@rt->data_adjust
//                         types=@da->values
//                         titles=@da->titles)
//              " - "
              (compute_title key=(detect_type @rt @rt->sibling_types) 
                         types=@rt->sibling_types 
                         titles=@rt->sibling_titles)
    )


  {
    fileparams: object data_length=(@data56->output | geta "length")
       {{
          datafiles: find-objects-bf features="df56" | arr_map code="(v) => v.getPath()+'->output'";

          x-param-combo
           name="input_link" 
           values=@datafiles->output;

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
      data56: object foo=1;
      link from=@fileparams->input_link to="@data56->output";
    };    

  };   

};

escreenvis: feature {
  rt: object sibling_types=["eh2","etext"] 
      sibling_titles=["Заголовок","Текст"]
      gui={render-params @rt}
      title=(compute_title key=(detect_type @rt @rt->sibling_types) 
                    types=@rt->sibling_types titles=@rt->sibling_titles)
      ;
};

efile: feature {
  rt: object sibling_types=["linesetc-file"] 
      sibling_titles=["Файл CSV"]

      ;
};

ecompute: feature {
  visual_process
	title="Вычисление"
	sibling_types=["ecompute1"] 
    sibling_titles=["Смешать построчно"];
};

ecompute1: feature {
	ec1: ecompute ~df56

	gui={
		text "Массив 1";
		render-params @p1;
		text "Массив 2";
		render-params @p2;
		
		//render-params @ec1;
		text (join "Размер результата: " (@ec1->output | geta "length"));
	}
//	{{
//		x-param-label name="output_length";
//	}}
	output=(list @p1->output @p2->output | df_interleave) // columns=["X","Y","Z"]
//	output_length=(@ec1->output | geta "length")
	{
		p1: ecompute_param;
		p2: ecompute_param;

//		eval @p1->output @p2->output code="(df1,df2) => {
//		}";
	}
};


ecompute_param: feature {
	ep:  object
       data_length=(@ep->output | geta "length")
       {{
          datafiles: find-objects-bf features="df56" | arr_map code="(v) => v.getPath()+'->output'";

          x-param-combo
           name="input_link" 
           values=@datafiles->output;

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
      //data56:;
      link from=@ep->input_link to="@ep->output";
    };
};


esync: feature {
	visual_process
	sibling_types=["esync1"] 
    sibling_titles=["Синхронизировать все процессы"]
    title="Синхронизация"
    ;
};

esync1: feature {
	es1: 
	esync project=@..

	gui={
		column ~plashka {
		  render-params @es1;
	  };
	}
	{{
		x-param-string name="synced_param_name";
		x-param-label name="synced_param_value";
		x-param-label name="processes-found";
	}}
	processes-found=(@synced_processes | geta "length")
	{
	  synced_processes: (find-objects-bf features="visual-process" root=@es1->project recursive=false);
	    
	    @synced_processes | x-modify {
	      x-set-param name=@es1->synced_param_name value=@es1->synced_param_value;
        m-on (+ "param_" @es1->synced_param_name "_changed") "(es1,obj,param_value) =>
         {
          // console.log('see param change', obj.getPath())
          es1.setParam('synced_param_value',param_value);
         }" @es1;
	    };

/*
      @synced_processes | insert_children {
        link from=(join (@es1 | geta "getPath") "->synced_param_value")
             to=(join ".->" @es1->synced_param_name) 
                 tied_to_parent=true manual_mode=true
                 {{ console_log_life }}
                 ;

        link to=(join (@es1 | geta "getPath") "->synced_param_value")
             from=(join ".->" @es1->synced_param_name)
                 tied_to_parent=true manual_mode=true;
      };
*/      

	};
};	