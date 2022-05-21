apply_by_hotkey "c" {
  console_log_apply "test";
};

// визуальный процесс "Возвращение"
// надо с терминами разобраться. это даж не визуальный процесс а процесс вида отображения.
// причем это часть вида отображения, хоть и существенная. потому что потом мы их комплексируем всяко.
// ну ладно главное нАчать

// load "view56";
// load "view56/vp/universal-vp.cl"; todo

find-objects-bf features="render_project_right_col" recursive=false 
|
insert_children { manage_landing; };

feature "manage_landing" {
  ma: 
      project=@..->project
      curview=@..->active_view

  collapsible "Проект Landing" {
    column plashka {
      text "Добавить:";
      button_add_object "Новые данные" 
         add_to=@ma->project 
         add_type="landing-file"
         {{
           created_add_to_current_view curview=@ma->curview;
         }};
      button_add_object "Новый образ" 
         add_to=@ma->project 
         add_type="landing-view-base"
         {{
           created_add_to_current_view curview=@ma->curview;
         }};         
    };
  };
};

feature "landing-file" {
  view: visual_process 
    title="Файл с данными ракеты" 
    visible=true 
    output=@loaded_data->output

  gui={
    column plashka {
        text "Укажите текстовый файл с данными";
        render-params  input=@fileparams;
    };
  }
  gui3={
    render-params @view;
  }
  {
    fileparams: {
      //f1_info: param_label "Укажите текстовый файл с данными";
      f1:  param_file value=(resolve_url "../2021-10-phase.txt");
      lines_loaded: param_label (@loaded_data->output | get name="length");

      loaded_data: load-file file=@fileparams->f1
             | parse_csv separator="\s+";

      // on изменение в выборе файла - перейти в вид1
      // но опять же - при старте программы это изменение тоже происходит.. 

    };

  }
};

feature "landing-view" 
{
  aview: title="Задача приземления ракеты"  // visual_process вроде как не надо
    visible=true 
    scene1=@lv1 
    scene2=@lv2
    top_visual_process
    // todo: scenes-info
    subprocesses=(@aview | get_children_arr | arr_filter_by_features features="visual_process" )
    {{ x-param-string name="title" }}
    gui={
      render_layers_inner title="Подпроцессы" expanded=true
           root=@aview
           items=[ { "title":"Подпроцессы", 
                     "find":"visual_process",
                     "add":"landing-view-base",
                     "add_to": "@aview->."
                   } ];
   }

   gui3={
     //button "Добавить подпроцесс";
     button_add_object "Добавить подпроцесс" add_to=@aview add_type="landing-view-base";
     render-params @aview;
   }

  {
    lv1: landing-view-1;
    lv2: landing-view-2;

    lv_t_cur: landing-view-base title="Вывод T" scene2d_items={ curtime; };
    lv_t_select: landing-view-base title="Вывод переменных" scene2d_items={ selectedvars; };

    // фича синхронизации.. может быть ее стоит по ифу сделать
    // или в универсальные блоки вытащить

    @aview->subprocesses | insert_children {
      link from="@aview->time_index" to=".->external_time_index" tied_to_parent=true manual_mode=true;
      link to="@aview->time_index" from=".->time_index" tied_to_parent=true manual_mode=true;
      };
    
  };
};  

feature "landing-view-1" {
	landing-view-base title="Приземление, общий вид"
	  scene3d_items={
	      linestr 
             data_adjust="traj";

        ptstr radius=2 
             data_adjust="traj";

        models 
             data_adjust="curtime";

        // вроде как не нужны - смотрелкой добавляются.. axes;
        axes;
        pole;
        kvadrat;
        // Иван сказал не надо столбик - есть уже оси известных размеров.
        //stolbik;
	  };
};

feature "landing-view-2" {
	landing-view-base title="Приземление, вид на объект"
    file_params_modifiers={
      xx: x-set-params project_x=true project_y=true project_z=true scale_y=false;
    }
	  scene3d_items={
        models 
             data_adjust="curtime";

        // вроде как не нужны - смотрелкой добавляются.. axes;
        setka;
        axes;
	  }
	  scene2d_items={
	  	//selectedvars;
	  }
	  ;
};

feature "landing-view-base" 
{

  view: visual_process title="Проект Landing" visible=true 
  
  //time_index=@timeparams->time_index

  scene3d=( if ( > @scene->object3d_count 0) then={@scene->output} )
  //scene3d=@scene2->output
  scene2d=@screen_space

  gui3={ render-params @view }
  {{ x-param-string name="title" }}

  {{ x-param-option "scene2d_items" "internal" true }}

  //route "set_time_index" to=@timeparams;
  //{{ x-add-cmd name="set_time_index" code=(i-set-param target="@timeparams->time_index"}
  //{{ x-add-cmd name="set_time_index" code=(i-call-js code=("(val)" => console.log))}}
  /*
  add_cmd "set_time_index" {
    setter target="@timeparams->time_index";
  }
  */

  gui={
	
  	column plashka {
      text "";
      render-params  input=@timeparams;
    };

    collapsible text="Данные"
    {
		  column plashka {
		    render-params  input=@fileparams;
	    };
	  };

    button "Настройки объектов" {
      //emit_event object=@view
      lambda @view @view->gui2 code="(obj,g2) => { obj.emit('show-settings',g2) }";
    };

   }
   
   gui2={ 
   	render_layers_inner title="Визуальные объекты" expanded=true
           root=@view
           items=[ { "title":"Объекты данных", 
                     "find":"datavis",
                     "add":"linestr",
                     "add_to": "@scene->."
                   },

                   {"title":"Статические",
                    "find":"staticvis",
                    "add":"axes",
                    "add_to": "@scene->."
                   },

                   {"title":"Текст",
                    "find":"screenvis",
                    "add":"curtime",
                    "add_to":"@screen_space->."
                   }
                 ]
           ;

  }

  {

	timeparams: {
    link from="@timeparams->time_index" to="@view->time_index";
    link to="@timeparams->time_index" from="@view->external_time_index" manual_mode=true;
    

	  time_index: param_slider
	           min=0 
	           max=(@internal_columns_dat->output | get "length" | @.->input - 1)
	           step=1 
	           value=@time->index
	           ;

	      time: param_combo 
	           values=(@internal_columns_dat->output | df_get column="T")
	           index=@timeparams->time_index
	           ;

	   //visible: param_checkbox;        
	};

	fileparams: scale_y=true y_scale_coef=50
  {{
        datafiles: find-objects-bf features="landing-file" | arr_map code="(v) => v.getPath()+'->output'";

        x-modify {
          insert_children input=@.. list=@view->file_params_modifiers;
        };

        x-param-combo
         name="input_link" 
         values=@datafiles->output;

        x-param-option
         name="input_link"
         option="priority"
         value=10; 

        x-param-checkbox name="project_x";
        x-param-checkbox name="project_y";
        x-param-checkbox name="project_z";

        x-param-checkbox name="scale_y";
        x-param-slider name="y_scale_coef" min=1 max=200;
        x-param-option name="y_scale_coef" option="visible" value=@fileparams->scale_y;
    }}
  {
	  loaded_data: ;
    link from=@fileparams->input_link to="@loaded_data->output";
	};


	data_compute:
	{

	  internal_columns_dat: @loaded_data->output | df_set X="->x[м]" Y="->y[м]" Z="->z[м]" T="->t[c]"
	                RX="->theta[град]" RY="->psi[град]" RZ="->gamma[град]"
	              | df_div column="RX" coef=57.7
	              | df_div column="RY" coef=57.7
	              | df_div column="RZ" coef=57.7;

    // привели, ок.

    compute_pipe: pipe input=@internal_columns_dat->output {
        if (output=@fileparams->project_x) then={
          df_set X=0;
        };
        if (output=@fileparams->project_y) then={
          df_set Y=0;
        };
        if (output=@fileparams->project_z) then={
          df_set Z=0;
        };
        if (output=@fileparams->scale_y) then={
          df_div column="Y" coef=@fileparams->y_scale_coef;
        };
    };

    /*
    @compute_pipe->. | x-modify {
      insert_children {
        if (@fileparams->project_x) {
          df_set X=0;
        };
      };  
    };
    */

    dat: output=@compute_pipe->output;

	  dat_cur_time_orig: @loaded_data->output | df_slice start=@timeparams->time_index count=1; 	              
    // dat_cur_time_orig - по идее рисовалки текста сами себе могли бы выдирать данные
    // но да ладно уж
	};

  find-objects-bf root=@scene features="datavis" | x-modify { 
      x-set-params
        time_index=@timeparams->time_index
        df=@dat->output
        ;
    };

  find-objects-bf root=@screen_space features="screenvis" | x-modify { 
      x-set-params
        time=@timeparams->time
        df=@dat_cur_time_orig->output
        ;
    };

    // по идее это далее не надо - можно просто массивы наружу выдавать
    // но нет надо, визуальный редактор занимается тем что потом добавляет доп объекты
    // именно вот в эти объекты-контейнеры (scene и проч)

    //insert_children input=@scene list=@view->scene3d_items;
    //insert_children input=@scene list=@view->scene3d_items active=(is_default @scene) manual=true;
    insert_default_children input=@scene list=@view->scene3d_items;

    scene: node3d visible=@view->visible force_dump=true
    {
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

linestr: feature {
  main: linestrips datavis 
     gui={ 
       render-params input=@main;
      };
};

ptstr: feature {
  main: points datavis gui={ render-params input=@main };
};
    
    // вход input это dataframe
models: feature {
    root: node3d datavis gui={ render-params input=@root  }
          {
            //monitor_params input=(list @root) params=["input"] | debugger "input of models changed";

            param_slider name="radius" min=1 max=10 value=3;
            param_color  name="hilight_color" value=[0,0,0];
            param_label  name="count" value=(@rep->input | get name="length");

            @root->input | df_slice count=100 | df_to_rows | rep: repeater {
              gltf:
                render_gltf
                src=(resolve_url "../Lake_IV_Heavy.glb")
                positions=(@gltf->input | df_combine columns=["X","Y","Z"])
                rotations=(@gltf->input | df_combine columns=["RX","RY","RZ"])
                
                {{ scale3d coef=@root->radius ; }}
                color=@root->hilight_color;
            };
        };
};

feature "axes"  {
       //main: axes_box size=100 staticvis; 
       // таким образом тут используется визуальный процесс
       // но пока ему нужна метка staticvis..
       axes-view size=100 staticvis;
};

feature "pole" {
        main: mesh gui={ render-params input=@main; } staticvis
          positions=[
           -1000,-0.5,-1000,  1000,-0.5,-1000, -1000,-0.5,1000,
           -1000,-0.5,1000,   1000,-0.5,-1000,  1000,-0.5,1000
          ]
          color=[0,0.25,0]
        ;
};

feature "setka" {
        main: lines gui={ render-params input=@main; } staticvis
          color=[0.7, 0.7, 0.8]
          positions=(eval code="() => {
            let step=100;
            let k = 10;
            let d = k*step;
            let acc=[];
            for (let i=-k; i<=k; i++) {
              acc.push( i*step, 0, -d );
              acc.push( i*step, 0, +d );
            };
            for (let i=-k; i<=k; i++) {
              acc.push( -d, 0, i*step );
              acc.push( +d, 0, i*step );
            };
            return acc;
          }")
        ;
};

feature "kvadrat" {
        main: mesh gui={ render-params input=@main; } staticvis
          positions=[
           -30,0,-30, 30,0,-30,  -30,0,30,  
           -30,0,30,  30,0,-30,  30,0,30
          ]
          color=[0.4, 0.4, 0.4]
        ; // todo: polygon offset modifier
    };

feature "stolbik" {
      main: 
        lines gui={ render-params input=@main; } staticvis
          positions=(compute_output h=@.->h code=`
            return [-30,0,-30, -30, env.params.h,-30 ]
          `)
          color=[1,1,1] 
          {
            param_slider name="h" min=5 max=100 value=5;
          };
    };


/////////////////////////////// надписи для экрана
// todo опора на vroot
// 

// параметр: time
feature "curtime" {
  sv: screenvis dom tag="h2" style="color: white; margin: 0;"
        innerText=(eval @sv->time code="(t) => 'T='+(t || 0).toFixed(3)");
};

// параметр: df - датафрейм для вывода данных. выводится 1я строка.
feature "allvars" {
  sv: screenvis 
        dom style="color: white; display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
                   min-width: 400px; font-size: larger"
        innerHTML=(eval @sv->df code="(df) => {
           
           let str='';
           df ||= {};
           
           for (let n of (df.colnames || [])) {
             let val = df[n][0];
             if (isFinite(val)) {
                 val = val.toFixed(3);
                 str += `<span>${n}=${val}</span>`;
             }
           }
           
           return str;
        }");
};

// параметр: df - датафрейм для вывода данных. выводится 1я строка.
feature "selectedvars" {
  sv: screenvis       
        dom 
        style="color: white; display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
                   min-width: 300px; font-size: larger"
        innerHTML=@qq->output 
        gui={ render-params input=@selected; } 
        {

          selected: gui_title="Выбрать" 
             {{ 
             x-on name="param_changed" cmd="@qq->recompute";
             x-on name="gui-added" cmd="@qq->recompute";
             }}
          {

              @sv->df | get name="colnames" | repeater 
              {
                param_checkbox name=@.->input value=true;
              };

              qq: eval @sv->df @selected code="(df,selected) => {
               let str='';
               df ||= {};
               if (!selected) return '';
               
               for (let n of (df.colnames || [])) {
                 let f = selected.getParam( n );
                 if (!f) continue;
                 let val = df[n][0];
                 if (isFinite(val)) {
                     val = val.toFixed(3);
                     str += `<span>${n}=${val}</span>`;
                 }    
               }
               return str;
               }";

              
          };
        }
    };

/////////////////////////// суммарная информация

feature "compute_title" {
  r: output=@q->output {
    q: eval @r->key @r->types @r->titles code="(t,a,b) =>
       {
          
          let ind = a.indexOf(t); 
          return b[ind];
       }";
  };
};

datavis: feature {
  rt: 
    input=@pipe->output
    sibling_types=["linestr","ptstr","models"] 
    sibling_titles=["Линии","Точки","Модели"]
    //title=(@rt->sibling_types | get name=(detect_type @rt @rt->sibling_types))
    title=(join 
              (compute_title key=@rt->data_adjust
                         types=@da->values
                         titles=@da->titles)
              " - "
              (compute_title key=(detect_type @rt @rt->sibling_types) 
                         types=@rt->sibling_types 
                         titles=@rt->sibling_titles)
          )
    step_N=25
  {{

    da: x-param-combo
         name="data_adjust" 
         titles=["Траектория","Текущее время","Прореженная траектория"]
         values=["traj","curtime","prorej"];
         
    x-param-option
         name="data_adjust"
         option="priority"
         value=10;

    pipe: pipe /*input=@rt->df*/ {
        // todo - воткнуть как-то по умолчанию curtime что ли.. 
        // короче  до моделей долетают данные которые фильтры еще не успели активироваться
        if (@rt->data_adjust == "curtime") then={
          df_slice start=@rt->time_index count=1;         
        };
        if (@rt->data_adjust == "prorej") then={
          df_skip_every count=@rt->step_N;
        };
    };


    if (timeout 15) then={ //qqq
      x-modify input=@pipe { x-set-params input=@rt->df; };
    };

    x-param-slider name="step_N" min=1 max=100;
    x-param-option name="step_N" option="priority" value=12;
    x-param-option name="step_N" option="visible" value=(@rt->data_adjust == "prorej");

    //x-param-string name="title";
  }}
};

staticvis: feature {
  rt: sibling_types=["axes","pole","kvadrat","stolbik","setka"] 
      sibling_titles=["Оси","Земля","Квадрат","Масштабный столбик","Сетка"]
      title=(compute_title key=(detect_type @rt @rt->sibling_types) 
                         types=@rt->sibling_types 
                         titles=@rt->sibling_titles)
      ;
};

screenvis: feature {
  rt: sibling_types=["curtime","allvars","selectedvars"] 
      sibling_titles=["Текущее время","Все переменные","Переменные по выбору"]
      title=(compute_title key=(detect_type @rt @rt->sibling_types) 
                         types=@rt->sibling_types titles=@rt->sibling_titles)
      ;
};