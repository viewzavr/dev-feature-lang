// действие - вставляет в указанный объект детей но только в случае если этот объект не настроен из дампа
// так-то можно сделать просто вычисление active для insert_children и не выделываться

// input - куды
// list - чиво
/*
  update жизнь сложнее там еще скопы надо создавать - короче в лес, юзаем insert_children и is-default

feature "insert_default_children" code=`

  //console.log("insert_default_children welcome screen",env.getPath())

  env.onvalues(["input","list"],(input,list) => {
     // также надо для целевого контейнера ставить force_dump=true
     input.setParam( "force_dump", true ); // это на будущее, шоб он уж точно попадал в дамп
     // а без этого его могут пропустить из дампирования и мы будем думать что там ничего нет
     // а там может быть есть - просто пользователь все решил вычистить (так бывает как выяснилось)

     vzPlayer.onvalue("dump_loaded",(dl) => {
        //console.log("see input and list, and dump-loaded is true",input.params.manual_restore_performed)
        if (input.params.manual_restore_performed) {
           //console.log("not doing job - there is data from dump")
        }
        else perform( input, list );
     });
  });

  function perform( input, list ) {
      //console.log("doing job",list,env.getPath());
        for (let edump of list) {
          edump.manual = true;
          edump.params.manual_features = Object.keys( edump.features ).filter( (f) => f != "base_url_tracing");
          //console.log("next child",edump,env.getPath());

          var p = env.vz.createSyncFromDump( edump,null,input,edump.$name,true );

          p.then( (child_env) => {
             child_env.manuallyInserted = true;
             //console.log("created child. dump is",child_env.dump(),env.getPath());
             //console.log("emitting local dump-loaded");
             //vzPlayer.getRoot().emit("dump-loaded");
          });
          
       };    
  }

`;
*/

// это вычисление поля active для обычного insert_children
// также надо для целевого контейнера ставить force_dump=true
feature "is_default" code=`
  env.setParam("output",false); // стопорнем для начала
  env.feature( "param_alias");
  env.addParamAlias( "input", 0 );
  env.onvalues(["input"],(input) => {
     vzPlayer.onvalue("dump_loaded",(dl) => {
        //console.log("is_default: see input and list, and dump-loaded is true. manual_restore_performed=",input.params.manual_restore_performed)
        if (input.params.manual_restore_performed) {
           //console.log("is_default: not doing job - there is data from dump")
        }
        else env.setParam("output",true);
     });
  });
`;

/*
recv @/ "dump-loaded" -> send @insert_children active=true
||
recv @.. "restoring" -> stop;
*/

/*
feature "user_template" {
  q: {
    x-modify input=@/ {
      x-on "dump-loaded" {
        i-call-js ""
        i-insert-children
      }
    }
    insert_children input=@q->input list=@q->list active=false manual=true;
  };
}
*/

// вход - scene3d, camera, scene2d (надписи)
// можно переделать будет на раздельное питание
feature "show_3d_scene" {
  scene_3d_view: 
    view3d style="width:100%; height:100%; " renderer=@r1 // тпУ
    camera_control={ orbit-control }
    { // max-height: 100vh;
      // max-height 100vh багфиксит грида
    
    // если вытащить его в хвост фичи (замкнуть view3d) то оно перестает видеть scene_3d_View почему-то
    r1: render3d
          bgcolor=[0.1,0.2,0.3]
          target=@scene_3d_view
          input=@scene_3d_view->scene3d // кстати идея так-то сделать аналог и для 2д - до-бирать детей отсель
          camera=@scene_3d_view->camera
          //{{ console_log_params "UUU" }}
      {
          //camera3d pos=[-400,350,350] center=[0,0,0];

          //orbit_control;
          @r1 | insert-children list=@scene_3d_view->camera_control;
      };
   };
   
};

// рисует боковушку - параметры визпроцессов...
// input - список процессов
feature "show_sources_params"
{
  sv: row auto_expand_first=true style='pointer-events: none !important;' {
    svlist: column style='align-items: flex-start; pointer-events: none !important;' {
      repeater input=@sv->input {
        mm: 
         row style='pointer-events: all !important;' {
        //dom tag="fieldset" style="border-radius: 5px; padding: 2px; margin: 2px;" {
          collapsible text=(@mm->input | get_param "title" default="no title") 
            style="min-width:250px;" padding="2px"
            style_h = "max-height:80vh;"
            body_features={ set_params style_h="max-height: inherit; overflow-y: auto;"}
            expanded=( (@mm->input_index == 0) and @sv->auto_expand_first)
          {
             insert_children input=@.. list=(@mm->input | get_param "gui");
             // вот мы вставили гуи
          };

          cbv: checkbox value=(@mm->input | geta "visible") visible=@sv->show_visible_cb?;

          x-modify input=@mm->input {
            x-set-params visible=@cbv->value? __manual=true;
            x-on "show-settings" {
              lambda @extra_settings_panel code="(panel,obj,settings) => {
                 //console.log('got x-on show-settings',obj,settings)
                 // todo это поведение панели уже..
                 // да и вообще надо замаршрузизировать да и все будет.. в панель прям
                 // а там типа событие или тоже команда
                 if (panel.params.list == settings)
                   panel.setParam('list',[]);
                 else  
                   panel.setParam('list',settings);
                 
              };
              ";
            };
          };
        }; // fieldset
      }; // repeater

      //@repa->output | render-guis;
      //render-params @rrviews;

    }; // svlist  


    extra_settings_panel_outer: row gap="2px" style='pointer-events: all !important;' 
        visible=(m_eval "(list) => {
            return list && list.length>0 ? true: false;}" 
            @extra_settings_panel->list? allow_undefined=true) 
    {
      extra_settings_panel: 
      column // style="position:absolute; top: 1em; right: 1em;" 
      {
         insert_children input=@.. list=@extra_settings_panel->list?;
      };
      bt: button "&lt;" style_h="height:1.5em;" 
      {
         setter target="@extra_settings_panel->list" value=[];
         //m_lambda "() => console.log('clocled');"
      };
    }; // extra_settings_panel_outer

    }; // row    
};

// подфункция реакции на чекбокс view_settings_dialog
// идея вынести это в метод вьюшки. типа вкл-выкл процесс.
feature "toggle_visprocess_view_assoc2" {
i-call-js 
  code="(cobj,val) => { // cobj объект чекбокса, val значение
    let view = env.params.view; // вид the_view
    //let view = cobj.params.view;
    // console.log({view,cobj,val});
    view.params.sources ||= [];
    view.params.sources_str ||= '';
    if (val) { // надо включить
      let curind = view.params.sources.indexOf( env.params.process );
      if (curind < 0) {
        let add = '@' + env.params.process.getPathRelative( view.params.project );
        //console.log('adding',add);
        let filtered = view.params.sources_str.split(',').filter( (v) => v.length>0)
        let nv = filtered.concat([add]).join(',');
        //console.log('nv',nv)
        
        view.setParam( 'sources_str', nv, true);

        //env.params.process.emit('view-attached',view);
      }
        // видимо придется как-то к кодам каким-то прибегнуть..
        // или к порядковым номерам, или к путям.. (массив objref тут так-то)
    }
    else
    {
        // надо выключить
      let curind = view.params.sources.indexOf( env.params.process );
      //debugger;
      if (curind >= 0) {
        //obj.params.sources.splice( curind,1 );
        //obj.signalParam( 'sources' );
        let arr = view.params.sources_str.split(',').map( x => x.trim());
        arr = [...new Set(arr)]; // унекальнозть
        let p = '@' + env.params.process.getPathRelative( view.params.project );
        let curind_in_str = arr.indexOf(p);
        if (curind_in_str >= 0) {
          arr.splice( curind_in_str,1 );
          view.setParam( 'sources_str', arr.join(','), true)
        };

        env.params.process.emit('view-detached',view);
      }
    };
  };";
};

//////////////////////////////////////////////////////// рендеринг проекта

// отображение. тут и параметр как компоновать
// параметр - список визуальных процессов видимо.
// ну а может контейнер ихний. посмотрим
// input 

// так это уже конкретная показывалка - с конкретным методом комбинирования.
// мы потом это заоверрайдим чтобы было несколько методов комбинирования и был выбор у человека
// хотя это можно и как параметр этой хрени и как суб-компоненту сделать.

// обновление. input это объект вида. the-view.
// у вью ожидаются - параметр sources - массив где каждый элемент
// имеет записи gui, scene2d, scene3d

feature "show_visual_tab" {
  sv: dom_group 
        screenshot_dom=(@ic->output | pause_input | geta 0 | geta "screenshot_dom") 
  {
    ic: insert_children input=@sv list=(@sv->input | get_param "show_view")
    ;
  };
};

/*
.. короче я тут начал подтягивать из вьюшек тип отображения
.. а при этом считаю что будет меняться этот тип отображения во вьюшках
.. например за счет смены типа вьюшек через методу render_layers_inner
.. которую я покажу рядом с кнопкой таблицы настройки видов
*/

//global_modifiers: render_project_right_col={};
// render_project_right_col_modifier: x-modify {};

feature "render_project_right_col";

feature "render_project" {
   // прикидывается колонкой чтобы стыковать левую колонку экрана с кнопками экранов
   rend: column padding="1em" project=@.->0 
            class='vz-mouse-transparent-layout'
            active_view_index=0 
            active_view=(@rend->project|geta "views"|geta @ssr->index default=null) 

            {{ x-add-cmd name="goto_next_view" code=(i-call-js ssr=@ssr code=`(val) => {
              let ssr = env.params.ssr;
              let len = ssr.params?.items?.length || 0;
              if (len > 0)
                 ssr.setParam( "index", (ssr.params.index+1) % len );
            }`);
            }}

            // приделаем реакцию на событие activate у экранов
            {{
                @rend->project | x-modify {
                  m-on "activate_view" "(allviews,ssr,project,view) => {
                     let index = allviews.indexOf( view );
                     //console.log('activate signal catched, index=',index)
                     if (index >= 0)
                         ssr.setParam('index',index);
                  }" @rend->sorted_views @ssr;
                };
            }}

            sorted_views=(@rend->project | geta "views" | sort_by_priority)
            {

       ssr: switch_selector_row 
               index=@rend->active_view_index
               items=(@rend->sorted_views | map_geta "title")

               style_qq="margin-bottom:15px;" {{ hilite_selected }}
                ;

       right_col: 
       
       column render_project_right_col 
         style="padding-left:2em; min-width: 80px; position:absolute; right: 1em; top: 1em; gap: 0.2em;"
         style_fit_h="max-height: 80vh; overflow-y: auto" 
         project=@rend->project
         //render_project=@rend
         active_view=@rend->active_view
         active_view_tab=@of->output
         render_project=@rend
         //{{ x-modify list=@render_project_right_col_modifier }}
        {
        }; // column справа

       of: one_of 
              index=@ssr->index
              list={ 
                show_visual_tab input=(@rend->project | get_param "views" | geta 0); // так то.. так то.. показывай просто текущий, согласно project[index].. но параметры сохраняй...
                show_visual_tab input=(@rend->project | get_param "views" | geta 1 default=null);
                show_visual_tab input=(@rend->project | get_param "views" | geta 2 default=null);
                show_visual_tab input=(@rend->project | get_param "views" | geta 3 default=null);
                show_visual_tab input=(@rend->project | get_param "views" | geta 4 default=null);
                show_visual_tab input=(@rend->project | get_param "views" | geta 5 default=null); // так то.. так то.. показывай просто текущий, согласно project[index].. но параметры сохраняй...
                show_visual_tab input=(@rend->project | get_param "views" | geta 6 default=null);
                show_visual_tab input=(@rend->project | get_param "views" | geta 7 default=null);
                show_visual_tab input=(@rend->project | get_param "views" | geta 8 default=null);
                show_visual_tab input=(@rend->project | get_param "views" | geta 9 default=null);
              }
              {{ one-of-keep-state; one_of_all_dump; }}
              ;


   };
};

feature "auto_activate_view" code=`
  env.feature("delayed");
  env.timeout( () => {
    //console.log("sending activate to project with arg ",env)
    env.ns.parent.emit("activate_view", env)
  },5);
`;

feature "add-to-current-view" code=`
  env.feature("delayed");
  env.timeout( () => {
    //console.log("sending activate to project with arg ",env)
    env.ns.parent.emit("add_visprocess_to_current_view", env)
  },5);
`;



// объект который дает диалог пользвателю 
// а в output выдает найденный dataframe отмеченный меткой df56
// todo предикат ф-ю
feature "find-data-source" {
   findsource: 
      //data_length=(@findsource->output | geta "length")
      input_link=(@datafiles_vals->output | geta 0)
      features="df56"
      {{
          datafiles: find-objects-bf features=@findsource->features;
                        //| arr_map code="(v) => [ v.getPath()+'->output', v.params.title || v.getPath() ]";
                        
          datafiles_vals: @datafiles->output 
                      | arr_map code="(v) => v.getPath()+'->output'";
          datafiles_titles: @datafiles->output 
                      | map_geta "title" default=null;

          x-param-combo
           name="input_link" 
           values=@datafiles_vals->output 
           titles=@datafiles_titles->output 
           ;

          x-param-option
           name="input_link"
           option="priority"
           value=10;

           x-param-option
           name="data_length"
           option="priority"
           value=12;

           //x-param-label-small name="data_length";
      }}
    {
      link from=@findsource->input_link to="@findsource->output";
    };
};

// input - dfка
// output - колонка (т.е. массив данных)
feature "select-source-column" {
  s: 
  {{ x-param-combo name="selected_column" values=@s->columns }}
  columns=(@s->input | geta "colnames")
  selected_column=""
  output=( @s->input | geta @s->selected_column default=[])
};

// вход:
// init_input - начальное значение (адрес вида /obj/path->paramname)
// выход:
// output - выбранная колонка (т.е. массив)
feature "find-data-source-column" {
  it:
  gui={
    render-params @s1 visible=@it->show_input;
    render-params @s2;
  }
  show_input=true
  selected_column=""
  output=@s2->output
  output_column_name=@s2->selected_column
  source_df=@s1->output?
  {
     s1: find-data-source input_link=@it->init_input?;
     s2: select-source-column input=@it->source_df selected_column=@it->selected_column;
  };
};
