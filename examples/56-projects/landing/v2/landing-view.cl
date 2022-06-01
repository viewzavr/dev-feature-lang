
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
      button_add_object "Новый файл данных" 
         add_to=@ma->project 
         add_type="landing-file"
         {{
           created_add_to_current_view curview=@ma->curview;
         }};
      button_add_object "Новый образ с нуля" 
         add_to=@ma->project 
         add_type="landing-view-base"
         {{
           created_add_to_current_view curview=@ma->curview;
         }};
      button_add_object "Новый образ с траекторией" 
         add_to=@ma->project 
         add_type="landing-view-1"
         {{
           created_add_to_current_view curview=@ma->curview;
         }};
      button_add_object "Новый образ с ракетой в центре" 
         add_to=@ma->project 
         add_type="landing-view-2"
         {{
           created_add_to_current_view curview=@ma->curview;
         }};
    };
  };
};

// маркер поставщика данных df
feature "df56";

feature "landing-file" {
  view: visual_process df56
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
      //f1:  param_file value=(resolve_url "../2021-10-phase.txt");
      f1:  param_file value="https://viewlang.ru/assets/other/landing/2021-10-phase.txt";
      lines_loaded: param_label (@loaded_data->output | get name="length");

      loaded_data: load-file file=@fileparams->f1
             | parse_csv separator="\s+";

      // on изменение в выборе файла - перейти в вид1
      // но опять же - при старте программы это изменение тоже происходит.. 

    };

  }
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

	timeparams: time_index=0 {
    link from="@timeparams->time_index" to="@view->time_index";
    link to="@timeparams->time_index" from="@view->time_index" manual_mode=true;
    //link to="@timeparams->time_index" from="@view->external_time_index" manual_mode=true;
    

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

	  internal_columns_dat: @loaded_data->output 
                | df_set X="->x[м]" Y="->y[м]" Z="->z[м]" T="->t[c]"
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

add_sib_item @datavis "linestr" "Линии";

// @datavis->items | arr_push {"linestr":"Линии"};
// @datavis->items | arr_eval "push" {"line"}
// eval_this @datavis->items "push" {"linestr":"Линии"};
// @datavis->items | geta "push" {"linestr":"Линии"};

ptstr: feature {
  main: points datavis 
   gui={ render-params input=@main; manage_addons input=@main container=@xxx; } 
   //addons={ effect3d_additive }
   addons=(@xxx | get_children_arr)
   {{
     xxx: { effect3d_additive; }; 
     x-modify-list input=@main list=(@xxx | get_children_arr | filter_geta "active" );
   }}
   {
     //insert_features input=@main list
   }
  ;
};
add_sib_item @datavis "ptstr" "Точки";

// визуальное управление добавками (фичьями)
// операции: добавить, удалить, ммм... поменять тип?
// input, channel
feature "manage_addons" {
  ma: collapsible "Добавки" {
    render_layers_inner "Добавки"
         root=@ma->container
         items=[ {"title":"Эффекты отображения", "find":"geffect3d","add":"effect3d_blank","add_to":"@ma->container"}
               ]
         ;
  };
};

geffect3d: feature {
  ef: sibling_titles=@geffect3d->sibling_titles
      sibling_types=@geffect3d->sibling_types
      title=(compute_title key=(detect_type @ef @ef->sibling_types) 
                         types=@ef->sibling_types 
                         titles=@ef->sibling_titles)
  {{ x-param-checkbox "active" }}
  active=true
  ;
};

add_sib_item @geffect3d "effect3d-blank" "-";

feature "effect3d_blank" {
  geffect3d;
};

add_sib_item @geffect3d "effect3d-additive" "Аддитивный рендеринг";
feature "effect3d_additive" {
  ea: geffect3d gui={render-params @ea; }
  x-patch-r code=`(tenv) => {
    tenv.onvalue('material',(m)=> {
      //m.blending = additive ? THREE.AdditiveBlending : THREE.NormalBlending;
      m.blending = THREE.AdditiveBlending;
    });
    return () => {
        if (tenv.params.material)
            tenv.params.material.blending = THREE.NormalBlending;
    };    
  }  
  `
  ;
};

add_sib_item @geffect3d "effect3d-opacity" "Прозрачность";
feature "effect3d_opacity" {
  eo: geffect3d
    {{ x-param-slider name="value" min=0 max=1 step=0.01; }}
    value=1
    gui={render-params @eo; }
    x-patch-r code=`(tenv) => {
          tenv.onvalue('material',(m)=> {
            m.transparent = true;
              m.opacity = env.params.value;
            });
            return () => {
                if (tenv.params.material)
                  tenv.params.material.transparent = false;
            };
          }
    `;
  ;
};
    
    // вход input это dataframe
models: feature {
    root: node3d gui={ render-params input=@root } datavis
          {
            //monitor_params input=(list @root) params=["input"] | debugger "input of models changed";

            param_slider name="radius" min=1 max=10 value=3;
            param_color  name="hilight_color" value=[0,0,0];
            param_label  name="count" value=(@rep->input | get name="length");

            @root->input | df_slice count=100 | df_to_rows | rep: repeater {
              gltf:
                render_gltf
                //src=(resolve_url "../Lake_IV_Heavy.glb")
                src="https://viewlang.ru/assets/models/Lake_IV_Heavy.glb" 
                positions=(@gltf->input | df_combine columns=["X","Y","Z"])
                rotations=(@gltf->input | df_combine columns=["RX","RY","RZ"])
                
                {{ scale3d coef=@root->radius ; }}
                color=@root->hilight_color;
            };
        };
};
add_sib_item @datavis "models" "Модели";

add_sib_item @staticvis "axes" "Оси";
feature "axes"  {
       //main: axes_box size=100 staticvis; 
       // таким образом тут используется визуальный процесс
       // но пока ему нужна метка staticvis..
       axes-view size=100 staticvis;
};

add_sib_item @staticvis "pole" "Земля";
feature "pole" {
        main: mesh gui={ render-params input=@main; } staticvis
          positions=[
           -1000,-0.5,-1000,  1000,-0.5,-1000, -1000,-0.5,1000,
           -1000,-0.5,1000,   1000,-0.5,-1000,  1000,-0.5,1000
          ]
          color=[0,0.25,0]
        ;
};

add_sib_item @staticvis "setka" "Сетка";
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

add_sib_item @staticvis "kvadrat" "Квадрат";
feature "kvadrat" {
        main: mesh gui={ render-params input=@main; } staticvis
          positions=[
           -30,0,-30, 30,0,-30,  -30,0,30,  
           -30,0,30,  30,0,-30,  30,0,30
          ]
          color=[0.4, 0.4, 0.4]
        ; // todo: polygon offset modifier
    };

add_sib_item @staticvis "stolbik" "Масштабный столбик";
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
add_sib_item @screenvis "curtime" "Текущее время"; 
feature "curtime" {
  sv: screenvis dom tag="h2" style="color: white; margin: 0;"
        innerText=(eval @sv->time code="(t) => 'T='+(t || 0).toFixed(3)");
};

// параметр: df - датафрейм для вывода данных. выводится 1я строка.
add_sib_item @screenvis "allvars" "Все переменные";
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
add_sib_item @screenvis "selectedvars" "Переменные по выбору";
feature "selectedvars" {
  sv: screenvis       
        dom 
        style="color: white; display: flex; flex-direction: row; gap: 1em;
                   min-width: 300px; font-size: larger;"
        innerHTML=@qq->output 
        gui={ render-params input=@selected; } 
        {

          selected: gui_title="Выбрать" 
             //columns=(@sv->df | geta "colnames" | arr_join with=",")
             columns="время,t[c]
место,x[м],y[м],z[м],
ускорение, Vx[м/с],Vy[м/с],Vz[м/с], Vx1[м/с],Vy1[м/с],Vz1[м/с],
omega_x1[град/с],omega_y1[град/с],omega_z1[град/с],q0[ед.],q1[ед.],q2[ед.],q3[ед.],
theta[град],psi[град],gamma[град],
delta1[град],delta2[град],delta3[град],delat4[град]"

             {{ 
               x-param-text name="columns";
               x-param-option name="columns" option="hint" 
                 value=(+ "Укажите данные для вывода на экран. 
                 Одна строка = одна колонка. В строке разделитель запятая, а # - символ комментария. 
                 Доступные имена колонок: <br/><br/><span style='background: #9cb6e7;'>" (@sv->df | geta "colnames" | arr_join with=", ") "</span>");
               //x-param-label name="columns_info" value=(@sv->df | geta "colnames");

               x-on name="param_changed" cmd="@qq->recompute";
               x-on name="gui-added" cmd="@qq->recompute";
             }}
          {

              qq: eval @sv->df @selected->columns code="(df,selected) => {
               df ||= {};
               if (!selected) return '';

               let str = ``;
               
               selected.split('\n').forEach( line => {
                  str += `<div style='display: flex; flex-direction: column;'>`;
                  line = line.split('#')[0].trim();

                  line.split(',').forEach( item => {
                     let rec = item.trim();
                     if (rec.length == 0) return;

                     if (df[rec]) {
                        let val = df[rec][0];
                        if (isFinite(val)) {
                          val = val.toFixed(3);
                          str += `<span>${rec}=${val}</span>`;
                        }    
                     } else
                     {
                        str += `<span>${rec}</span>`;  
                     } 
                  });

                  str = str + '</div>';
               })

               return str;
               }"; // qq eval

              
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
    sibling_types=@datavis->sibling_types
    sibling_titles=@datavis->sibling_titles
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

    pipe: pipe /*input=@rt->df*/ df56 {
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
  rt: 
      sibling_types=@staticvis->sibling_types
      sibling_titles=@staticvis->sibling_titles
      title=(compute_title key=(detect_type @rt @rt->sibling_types) 
                         types=@rt->sibling_types 
                         titles=@rt->sibling_titles)
      ;
};

screenvis: feature {
  rt: sibling_types=@screenvis->sibling_types
      sibling_titles=@screenvis->sibling_titles
      title=(compute_title key=(detect_type @rt @rt->sibling_types) 
                         types=@rt->sibling_types titles=@rt->sibling_titles)
      ;
};