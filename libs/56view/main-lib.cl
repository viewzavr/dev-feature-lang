// это вычисление поля active для обычного insert_children
// также надо для целевого контейнера ставить force_dump=true
// todo - в случае если это программно управляется вещь, то у нее is-default срабатывает..
feature "is_default" code=`
  env.setParam("output",false); // стопорнем для начала
  env.feature( "param_alias");
  env.addParamAlias( "input", 0 );
  env.onvalues(["input"],(input) => {
     vzPlayer.onvalue("dump_loaded",(dl) => {
        // console.log("is_default: see input and list, and dump-loaded is true. manual_restore_performed=",input.params.manual_restore_performed)
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
    view3d style="width:100%; height:100%; " 
    renderer=@r1 // тпУ
    camera_control={ orbit-control }
    { // max-height: 100vh;
      // max-height 100vh багфиксит грида
    
    // если вытащить его в хвост фичи (замкнуть view3d) то оно перестает видеть scene_3d_View почему-то
    r1: render3d
          bgcolor=[0.1,0.2,0.3]
          target=@scene_3d_view
          input=@scene_3d_view->scene3d // кстати идея так-то сделать аналог и для 2д - до-бирать детей отсель
          camera=@scene_3d_view->camera
          //{{ console_log_params "UUURRR" }}
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
  sv: row 
    auto_expand_first=true 
    show_visible_cb=true 
    style='pointer-events: none !important;' 
    show_settings_gui={ |code| show_settings_panel list=@code }
    settings_gui=[]
    {
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

          cbv: checkbox value=(@mm->input | geta "visible") visible=@sv->show_visible_cb;

          //@sv->input | get-event-cell "remove" | m_eval "(evt,ch) => console.log(333); " (@sv | get-cell "settings_gui" );

          x-modify input=@mm->input {
            x-set-params visible=@cbv->value? __manual=true;
            x-on "hide-settings" {
              lambda (@sv | get-cell "settings_gui" ) code="(gui_channel,obj,settings) => {
                //if (gui_channel.get() == settings)
                   gui_channel.set([]);
                };
              ";
            };
            x-on "show-settings" {
              lambda (@sv | get-cell "settings_gui" ) code="(gui_channel,obj,settings) => {
                 // console.log('got x-on show-settings',obj,settings)
                 // todo это поведение панели уже..
                 // да и вообще надо замаршрузизировать да и все будет.. в панель прям
                 // а там типа событие или тоже команда
                 if (gui_channel.get() == settings)
                   gui_channel.set([]);
                 else  
                   gui_channel.set(settings);
              };
              ";
            };
            /*
            x-on "remove" {
              lambda (@sv | get-cell "settings_gui") code="(gui_channel,obj,settings) => {
                console.log(`rrrr`);
                if (gui_channel.get() == settings)
                   gui_channel.set([]);
                };
              ";   
            };
            */
          };
        }; // fieldset
      }; // repeater

    }; // svlist  

    // show_settings_panel list=@sv.settings_gui;

    if (@sv.settings_gui.length? > 0) then={
      let g = (create-objects input=@sv.show_settings_gui @sv.settings_gui | set-parent @sv);
      read @g | get-event-cell "close" | get-cell-value | m_eval "(evt,c) => { console.log(333,evt); c.set([]); } " (@sv | get-cell "settings_gui" );

      // console-log "panel opened" @sv.show_settings_gui @sv.settings_gui;

      // insert_children input=@sv list=@sv.show_settings_gui @sv.settings_gui;

      // create-objects input=@sv.show_settings_gui @sv.settings_gui;
      // computing-env code=@sv.show_settings_gui @sv.settings_gui dom_generator=true;
      // repeater input=(list @sv.settings_gui) list=@sv.show_settings_gui
    };

    }; // row
};

feature "show_settings_panel" {
   extra_settings_panel: 
        row gap="2px" style='pointer-events: all !important;'
        list=@.->0
    {
      column // style="position:absolute; top: 1em; right: 1em;" 
      {
         insert_children input=@.. list=@extra_settings_panel->list?;
      };

      // ну типа соединили каналы.. это примерно как написать row close=@bt->click; хм...
      read @extra_settings_panel | get-event-cell "close" | set-cell-value (@bt | get-event-cell "click" | get-cell-value);

      bt: button "&lt;" style_h="height:1.5em;" 
      {
         //extra_settings_panel | get-event-cell "close" | set-cell-value

         // setter target="@extra_settings_panel->list" value=[];
         //m_lambda "() => console.log('clocled');"
      };
    }; // extra_settings_panel_outer
};

feature "show_settings_dialog" {
   extra_settings_panel: 
        dialog 
        gap="2px" style='pointer-events: all !important;padding: 0px;border: 0px; background: transparent;'
        list=@.->0
    {
      @extra_settings_panel | get-cmd-cell "apply" | set-cell-value 1;

      column
      {
         insert_children input=@.. list=@extra_settings_panel->list?;
      };
      
    }; // extra_settings_panel_outer
};


// подфункция реакции на чекбокс view_settings_dialog
// идея вынести это в метод вьюшки. типа вкл-выкл процесс.
// ВАЖНО: все пути здесь считаются относительно проекта
feature "toggle_visprocess_view_assoc2" {
i-call-js 
  code="(cobj,val) => { // cobj объект чекбокса, val значение
    let view = env.params.view; // вид the_view

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
        //screenshot_dom=(@ic->output | pause_input | geta 0 | geta "screenshot_dom") 
  {
    ic: insert_children input=@sv list=(@sv->input | geta "show_view");
    ic2: insert_children input=@sv.rend list=(@sv->input | geta "show_view_gui");
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
            screenshot_dom=@rrviews_group.dom

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

               row  style_qq="margin-bottom:15px;" {
                 top_row: row {
                  @top_row | insert_children list=@rend.top_row_items?;
                 }; 

               ssr: switch_selector_row 
                 index=@rend->active_view_index
                 items=(@rend->sorted_views | map_geta "title")
                 {{ hilite_selected }}
                  ;
               };

/*
       xtra_items: render_project_right_col 
         project=@rend->project
         active_view=@rend->active_view
         active_view_tab=@of->output
         render_project=@rend;
         */

       right_col: column // {{ set_dom_children list=(@xtra_items | get_children_arr | sort_by_priority) }}
         style="padding-left:2em; min-width: 80px; position:absolute; right: 1em; top: 1em; gap: 0.2em;"
         style_fit_h="max-height: 80vh; overflow-y: auto"
         {{ sort_dom_children }}

         ~render_project_right_col 
         project=@rend->project
         active_view=@rend->active_view
         active_view_tab=@of->output
         render_project=@rend
         ;


       // теперь надо рендерер. как выяснилось он таки один должен быть даже на все экраны, иначе падает браузер 


      // это сделано родителем one-of чтобы можно было делать скриншоты
      rrviews_group: 
        column style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2;"
                 class="view56_visual_tab"
        {

        main_render_area: show_3d_scene_main subrenderers=(find-objects-bf "subrenderer" root=@rend)
            style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2";

        // хитро. надо прописать renderer всем вьюшкам 3д, чтобы они могли это передавать в визуальные процессы..
        find-objects-bf "show_3d_scene_r" root=@rend 
        | x-modify { x-set-params renderer = @main_render_area->renderer };
      ;
      
       of: one_of 
              index=@ssr->index
              list={ 
                show_visual_tab rend=@rend input=(@rend->project | geta "views" | geta 0 default=null); // так то.. так то.. показывай просто текущий, согласно project[index].. но параметры сохраняй...
                show_visual_tab rend=@rend input=(@rend->project | geta "views" | geta 1 default=null);
                show_visual_tab rend=@rend input=(@rend->project | geta "views" | geta 2 default=null);
                show_visual_tab rend=@rend input=(@rend->project | geta "views" | geta 3 default=null);
                show_visual_tab rend=@rend input=(@rend->project | geta "views" | geta 4 default=null);
                show_visual_tab rend=@rend input=(@rend->project | geta "views" | geta 5 default=null); // так то.. так то.. показывай просто текущий, согласно project[index].. но параметры сохраняй...
                show_visual_tab rend=@rend input=(@rend->project | geta "views" | geta 6 default=null);
                show_visual_tab rend=@rend input=(@rend->project | geta "views" | geta 7 default=null);
                show_visual_tab rend=@rend input=(@rend->project | geta "views" | geta 8 default=null);
                show_visual_tab rend=@rend sinput=(@rend->project | geta "views" | geta 9 default=null);
              }
              {{ one-of-keep-state; one_of_all_dump; }}
              ;

      }; // group


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
   findsource: object
      //data_length=(@findsource->output | geta "length")
      input_link=@datafiles_vals.output.0
      features="df56"
      {{
          datafiles: find-objects-bf features=@findsource->features;
                        //| arr_map code="(v) => [ v.getPath()+'->output', v.params.title || v.getPath() ]";
                        
          datafiles_vals: read @datafiles->output 
                      | arr_map code="(v) => v.getPath()+'->output'";
          datafiles_titles: read @datafiles->output 
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
  s: object
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
  it: object 
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
