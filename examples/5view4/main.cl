load "lib3dv3 csv params io gui render-params df scene-explorer-3d gui5.cl new-modifiers imperative";
load "main-lib.cl";
load "landing3/landing-view.cl landing/test.cl universal/universal-vp.cl"; // отдельный вопрос

feature "setup_view" {
  column {
    button "Настройки"
  };
};

// подфункция реакции на чекбокс view_settings_dialog
// идея вынести это в метод вьюшки. типа вкл-выкл процесс.
feature "toggle_visprocess_view_assoc2" {
i-call-js 
  code="(cobj,val) => { // cobj объект чекбокса, val значение
    let view = env.params.view; // вид the_view
    //let view = cobj.params.view;
    console.log({view,cobj,val});
    view.params.sources ||= [];
    view.params.sources_str ||= '';
    if (val) { // надо включить
      let curind = view.params.sources.indexOf( env.params.process );
      if (curind < 0) {
        let add = '@' + env.params.process.getPathRelative( view.params.project );
        console.log('adding',add);
        let filtered = view.params.sources_str.split(',').filter( (v) => v.length>0)
        let nv = filtered.concat([add]).join(',');
        console.log('nv',nv)
        
        view.setParam( 'sources_str', nv, true);
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
      }
    };
  };";
};

feature "the_view" 
{
  tv: 
  gui={ 
    render-params @tv; 
    //console_log "tv is " @tv "view procs are" (@tv | geta "sources" | map_geta "getPath");

    qq: tv=@tv; // без этого внутри ссылка на @tv уже не робит..
    text "Включить:";

    @tv->project | geta "processes" | repeater //target_parent=@qoco 
    {
       i: checkbox text=(@i->input | geta "title") 
             value=(@qq->tv | geta "sources" | arr_contains @i->input)
          {{ x-on "user-changed" {
              toggle_visprocess_view_assoc2 process=@i->input view=@qq->tv;
          } }};
    };

  }
  {{
    x-param-string name="title";
    // дале чтобы сохранялось всегда даж для введенных в коде вьюшек
    x-param-option name="title" option="manual" value=true;
    x-param-option name="sources_str" option="manual" value=true;
  }}
  sibling_types=["the-view-mix3d","the-view-row", "the-view-small-big"] 
  sibling_titles=["Одна сцена","Слева на право", "Окно в окне"]
  sources=(find-objects-by-pathes input=@tv->sources_str root=@tv->project)
  project=@..
  {
  };
  
};

feature "the_view_mix3d" {
  tv: the-view
        camera=@cam
        show_view={ show_visual_tab_mix3d input=@tv; }
        scene3d=(@tv->sources | map_geta "scene3d")
        scene2d=(@tv->sources | map_geta "scene2d")
        {
          cam: camera3d pos=[-400,350,350] center=[0,0,0];
          // вот бы метод getCameraFor(i).. т.е. такое вычисление по запросу..
        };
};

feature "the_view_row"
{
  tv: the-view 
    show_view={ show_visual_tab_row input=@tv; }
    camera=@cam 
    {
      cam: camera3d pos=[-400,350,350] center=[0,0,0];
    };
};

feature "the_view_small_big"
{
  tv: the-view 
    show_view={ show_visual_tab_small_big input=@tv; }
    camera=@cam 
    camera2=@cam2 
    {
      cam: camera3d pos=[-400,350,350] center=[0,0,0];
      cam2: camera3d pos=[-400,350,350] center=[0,0,0];
    };
};

feature "visual_process" {
    output=@~->scene3d;
};

feature "pause_input" code=`
  env.feature("delayed");
  let pass = env.delayed( () => {
    env.setParam("output", env.params.input);
  },1000/30);

  env.onvalue("input",pass);
`;

project: active_view_index=1 
  //views=(get-children-arr input=@project | pause_input | arr_filter_by_features features="the-view")
  views=(find-objects-bf features="the-view" root=@project | sort_by_priority)
  
  //processes=(get-children-arr input=@project | arr_filter_by_features features="visual-process")
  processes=(find-objects-bf features="visual-process" root=@project recursive=false | sort_by_priority)
{

  insert_default_children input=@project list={
    lf: landing-file;
    lv: landing-view;
    //a1: axes-view size=100;
    //a2: axes-view title="Оси координат 2";

    v0: the-view-mix3d title="Данные" 
        sources_str="@lf";

    v1: the-view-mix3d title="Общий вид" 
        sources_str="@lv/lv1";

    v2: the-view-mix3d title="Вид на ракету" 
        sources_str="@lv/lv2";
  };

  /*
  v_setup: the-view title="Настройки" {
    //sync_params_process root=@project;
  }
  */
};

screen1: screen auto-activate  {
  render_project @project active_view_index=1;
};

debugger-screen-r;

////////////////////////////////////////////////////////

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
  sv: dom_group {
    ic: insert_children input=@sv list=(@sv->input | get_param "show_view");
    
    //@ic->output | x-modify { x-set-params input=@sv->input };
  };
};
/*
.. короче я тут начал подтягивать из вьюшек тип отображения
.. а при этом считаю что будет меняться этот тип отображения во вьюшках
.. например за счет смены типа вьюшек через методу render_layers_inner
.. которую я покажу рядом с кнопкой таблицы настройки видов
*/

feature "show_visual_tab_mix3d" {
   svt: dom_group 
   {
    show_sources_params input=@svt->input;
    show_3d_scene 
       scene3d=(@svt->input | geta "scene3d") 
       scene2d=(@svt->input | geta "scene2d")
       camera=(@svt->input | geta "camera") 
       style_k="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2";
    ;
   }; // domgroup
}; // show vis tab

feature "show_visual_tab_row" {
   svr: dom_group
   {

    show_sources_params input=@svr->input;

    rrviews: row style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2;
        justify-content: center;" 
    {
      repa: repeater input=(@svr->input | geta "sources") {
        src: dom style="flex: 1 1 0;" {
          show_3d_scene 
            scene3d=(@src->input | geta "scene3d") 
            scene2d=(@src->input | geta "scene2d")
            camera=(@svr->input | geta "camera") 
            style="width:100%; height:100%;";
        };
      };
    };

   }; // domgroup

}; // show vis tab

// todo: по клику на окно увеличить размер / и обратно
// понять как визпроцессу повлиять на камеру (типа вид на объект ближе к)
feature "show_visual_tab_small_big" {
   svsm: dom_group
   {

    show_sources_params input=@svsm->input;

    show_3d_scene 
       scene3d=(@svsm->input | geta "sources" 0 "scene3d") 
       scene2d=(@svsm->input | geta "sources" 0 "scene2d")
       camera=(@svsm->input | geta "camera") 
       style_k="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-3";

    rrviews: row style="position: absolute; bottom: 30px; right: 30px; height: 30%; z-index:-2;
        justify-content: flex-end; gap: 1em;" 
    {
      repa: repeater input=(@svsm->input | geta "sources" "slice" 1) {
        src: dom style="flex: 0 0 350px;" {
          show_3d_scene 
            scene3d=(@src->input | geta "scene3d") 
            scene2d=(@src->input | geta "scene2d")
            camera=(@svsm->input | geta "camera2") 
            style="width:100%; height:100%;";
        };
      };
    };

   }; // domgroup

}; // show vis tab

// подфункция реакции на чекбокс view_settings_dialog
feature "toggle_visprocess_view_assoc" {
i-call-js 
  code="(cobj,val) => { // вот какого ежа тут js, где наш i-код?
    let obj = cobj.params.input;
    console.log({obj,cobj,val});
    obj.params.sources ||= [];
    if (val) {
      let curind = obj.params.sources.indexOf( env.params.src );
      if (curind < 0)
        obj.setParam( 'sources', obj.params.sources.concat([env.params.src]));
        // видимо придется как-то к кодам каким-то прибегнуть..
        // или к порядковым номерам, или к путям.. (массив objref тут так-то)
    }
    else
    {
      let curind = obj.params.sources.indexOf( env.params.src );
      if (curind >= 0) {
        //obj.params.sources.splice( curind,1 );
        //obj.signalParam( 'sources' );
        let nv = obj.params.sources.slice();
        nv.splice( curind,1 );
        obj.setParam( 'sources', nv);
      }
    };
  };";  
};

feature "view_settings_dialog" {
    d: dialog {
     dom style_1=(eval (@rend->project | get_param "views" | arr_length) 
           code="(len) => 'display: grid; grid-template-columns: repeat('+(1+len)+', 1fr);'") 
     {
        text "/";
        dom_group {
          repeater input=(@rend->project | get_param "views") 
          {
            rr: text (@rr->input | get_param "title"); 
          };
        };
        dom_group { // dom_group2
          repeater input= (@rend->project | get_param "processes") {
            q: dom_group {
              text (@q->input | get_param "title");
              repeater input=(@rend->project | get_param "views") 
              {
                i: checkbox value=(@i->input | get_param "sources" | arr_contains @q->input)
                  {{ x-on "user-changed" {toggle_visprocess_view_assoc src=@q->input;} }}
                ;
              };
            };
          }; // repeater2
        }; // dom_group2 
      }; // dom grid  

    }; // dlg
};

/*
feature "view_settings_dialog" {
    d: dialog {
     row style_1="flex-wrap: wrap;" {
      column {
        repeater input= (@rend->project | get_param "processes") {
                checkbox;
             };
      }
      repeater input=(@rend->project | get_param "views") {
        rr: column {
          text (@rr->input | get_param "title");
          column {
             repeater input= (@rend->project | get_param "processes") {
                checkbox;
             };
          };
        };
       };
     };

    };
};
*/

/* не ну это интрига. говорить - инсерт чилдрен таба из его гуи.. хм..
feature "oneview" {
  ov: gui={
    
  }
}
*/

//lv1: landing-view-1;

feature "render_project" {
   rend: column padding="1em" project=@.->0 active_view_index=0 
            active_view=(@rend->project|geta "views"|geta @ssr->index){

       ssr: switch_selector_row 
               index=@rend->active_view_index
               items=(@rend->project | get_param "views" | sort_by_priority | map_param "title")
               style_qq="margin-bottom:15px;" {{ hilite_selected }}
                ;

       right_col: 
       column style="padding-left:2em; min-width: 80px; 
       position:absolute; right: 1em; top: 1em;" {
         button "Настройка соответствий" {
            view_settings_dialog project=@rend->project;
         };
         collapsible "Настройка экрана" {

           co: column plashka style_r="position:relative;"
            input=@rend->active_view 
            {

              column {
                object_change_type text="Способ отображения:"
                   input=@co->input
                   types=(@co->input | get_param "sibling_types" )
                   titles=(@co->input | get_param "sibling_titles");
              };

              column {
                insert_here list=(@co->input | get_param name="gui");
              };

              button "Удалить экран" //style="position:absolute; top:0px; right:0px;" 
              {
                lambda @co->input code=`(obj) => { obj.removedManually = true; obj.remove(); }`;
              };
           };

           

/*
           render_layers_inner title="Виды" expanded=true
           root=@rend->project
           items=[ { "title":"Виды", 
                     "find":"the-view",
                     "add":"the-view",
                     "add_to": "@rend->project"
                   } ];
*/                   
         };          

       button_add_object "Добавить экран" add_to=@rend->project add_type="the-view-mix3d";  

       }; // column справа

       of: one_of 
              index=@ssr->index
              list={ 
                show_visual_tab input=(@rend->project | get_param "views" | get 0); // так то.. так то.. показывай просто текущий, согласно project[index].. но параметры сохраняй...
                show_visual_tab input=(@rend->project | get_param "views" | get 1);
                show_visual_tab input=(@rend->project | get_param "views" | get 2);
                show_visual_tab input=(@rend->project | get_param "views" | get 3);
                show_visual_tab input=(@rend->project | get_param "views" | get 4);
              }
              {{ one-of-keep-state; one_of_all_dump; }}
              ;

   };  
}



/*
  of: one_of 
              index=@ssr->index
              list={ 
                oneview {
                  collapsible text="Траектория возвращения" style="min-width:250px;" padding="5px"
                  {
                    //render-params input=@lv1;
                    insert_children input=@.. list=@lv1->gui;
                  };
                  collapsible text="Траектория возвращения 2" style="min-width:250px;" padding="5px"
                  {
                    //render-params input=@lv1;
                    insert_children input=@.. list=@lv1->gui;
                  };
                };
                oneview;
                addview;
              }
              {{ one-of-keep-state; one_of_all_dump; }}
              ;

*/