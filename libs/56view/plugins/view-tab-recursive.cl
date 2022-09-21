// "Универсальный" вид аля Паравью

find-objects-bf features="the_view_types" recursive=false 
|
insert_children {
  value="the_view_recursive" title="Общий экран (рекурсивный)"; 
};

/*
feature "walk_objects" {
  k: output=(m_eval "(root_obj,subitms_param) => {
      function walk()
    }" @k->0 @k->1);
}
*/

// 0 корневой объект 1 имя параметра с "детьми" depth глубина
// возвращает массив записей о найденных детях
feature "walk_objects" {
   k: 
     output=(concat @my_result @my_items_result)
     depth=0
     {
      let my_result = (m_eval 
         "(obj,title,depth) => 
         { return {id:obj.$vz_unique_id,
                   title:'-'.repeat(depth)+title,
                   obj: obj} }" 
         @k->0 (@k->0 | geta "title") @k->depth);
      let my_items = (data (@k->0 | geta @k->1 default=[]));
      // console-log "k=" @k.getPath "k.0=" @k.0?.getPath? "found items=" @my_items;
      
      let my_items_result=(
        @my_items | repeater {
          w: walk_objects @w->input @k->1 depth=(@k->depth + 1);
        } 
        | map_geta "output" default=null | geta "flat" | arr_compact);
     }
};

feature "the_view_recursive"
{
  tv: the-view 
    show_view={ // это экран
      show_visual_tab_recursive input=@tv;
    }
    show_view_gui={ // это контролы слева
      show_visual_tab_recursive_gui input=@tv;
    }
    active_area = null
    gui={ // это контролы для диалога
      render-params @tv;

      cb: combobox values=(@tv->list_of_areas | map_geta "id") 
                   titles=(@tv->list_of_areas | map_geta "title")
                   index=0 dom_size=5
      ;

      let selected_object = (@tv->list_of_areas | geta @cb->index default=null | geta "obj");

      @tv | get-cell "active_area" | set-cell-value @selected_object;

      //render-params @curobj;

     co: column ~plashka style_r="position:relative; overflow: auto;"  
      {
        column {
          //text "Параметры";
          //text ()
          insert_children input=@.. list=(@selected_object | geta "gui" default=null);
        };

        button "x" style="position:absolute; top:0px; right:0px;" 
        {
          lambda @selected_object code=`(obj) => { obj.removedManually = true; obj.remove(); }`;
        };

     };

    }
    //primary_container=(find-objects-bf features="recursive_area" recursive=false root=@tv {{ console_log_params "PCO"}})
    // верхний контейнер
    primary_container=(@tv | get_children_arr | arr_filter_by_features features="recursive_area" | geta 0 default=null)
    list_of_areas=(walk_objects @tv->primary_container "subitems")
    /* уберем - давайте ка руками это вставлять все..  
    {{ insert_children input=@tv manual=true active=(is_default @tv) 
        list={
          area_3d;
        };
    }}
    */
    
    {{ x-param-option name="append_process" option="visible" value=false }}
    {{ x-add-cmd name="append_process" code=(m_lambda `(active_area,first_cont_area,proc) => {
        if (active_area && active_area.append_process)
            active_area.append_process( proc )
           else   
        if (first_cont_area && first_cont_area.append_process)
            first_cont_area.append_process( proc )
           else 
           {
             console.warn("no active area nor content area - process is not appended");
           }

      }` @tv->active_area (find-objects-bf features="area_content" root=@tv | geta 0 default=null));
    }}
    // перебьем стандартные sources от the-view на поиск сурсов от контентных областей
    sources=(find-objects-bf features="area_content" root=@tv 
        | map_geta "sources" default=[]
        | arr_flat
        | arr_uniq )
   ;
};
/* тодо очень не хватает что-то типа cond.. мб жуж-подход..
      }` (cond {
              (@tv->active_area | geta "append_process") @tv->active_area)
              ]};
*/

// по сути то экран..
feature "recursive_area" 
{
  it:  object
       title="Область"
       project=@..->project
       view=@..
       visible=true
       effective_visible=@it.visible // надстройка над визиблом
       {{ x-param-string name="title" }}
       {{ x-param-checkbox name="visible" }}
       {{ x-param-slider name="weight" min=0.1 max=5 step=0.1; }}
       weight=1
        {{ x-add-cmd2 "split-horiz" (split-screen @it 'area_container_horiz') }}
        {{ x-add-cmd2 "split-vert" (split-screen @it 'area_container_vert') }}
        {{ x-param-option name="split-horiz" option="visible" value=false }}
        {{ x-param-option name="split-vert" option="visible" value=false }}       

       ;
};

feature "area_container" {
  it: recursive_area
       sibling_types=["area_container_horiz","area_container_vert","area_container_one_switch", "area_container_join", "area_container_opacity_switch"] 
       sibling_titles=["Горизонтальный","Вертикальный","Выбор одного", "Совместный", "Выбор по прозрачности"]
       subitems=(@it | get_children_arr 
                     // | restart_input ( @it | get_children_arr | get-cell "feature-applied-recursive-area" | get-cell-value)
                     | arr_filter_by_features features="recursive_area")
        {{
           // console-log "me=" @it.getPath "subitems=" @it.subitems "charr=" (@it | get_children_arr);
           //x-param-slider name="ratio";
        }}
        gui={
           object_change_type text="тип:"
              input=@it
              types=@it->sibling_types
              titles=@it->sibling_titles;

          render-params @it;

          param_field name="Разделить" {
           button "Горизонтально" cmd=@it->split-horiz;
           button "Вертикально" cmd=@it->split-vert;
          };

          button_add_object "Добавить область" add_to=@it add_type="area_empty";  
        }
        ;
};

feature "area_container_horiz" {
   it: area_container title="Горизонтальный"
   show={
      show_area_container_horiz input=@it;
   }
};

feature "area_container_vert" {
   it: area_container title="Вертикальный"
   show={
      show_area_container_vert input=@it;
   }
};

feature "area_container_join" {
   it: area_container title="Совместный"
   show={
      show_area_container_join input=@it;
   }
};

feature "area_container_opacity_switch" {
   it: area_container title="Выбор прозрачности"
   opacity_coef=0.0
   {{ x-param-slider name="opacity_coef" min=0.0 max=1.0 step=0.01 }}
   show={
      show_area_container_opacity_switch input=@it opacity_coef=@it->opacity_coef;
   }
};

feature "area_container_one_switch" {
   it: area_container title="Выбор одного"
   selected=0
   {{ x-param-slider name="selected" min=0 max=(@it.subitems?.length - 1) step=1 }}
   show={
      show_area_container_one_switch input=@it selected=@it.selected;
   }
   show_gui={
     ssr: switch_selector_row 
             index=@it.selected
             items=(@it.subitems | map_geta "title" default=".")
             on_user_change=(m_lambda "(it,value) => { it.setParam('selected',value); }" @it)
             {{ hilite_selected }}
             ;
     // варианты красоты:        
     // @it | get-cell "selected" | set-cell-value (@ssr | get-cell "user_change" | get-cell-value);
     // bind-cells @ssr "user_change" @it "selected";
     // bind-cells (@ssr | get-cell "user_change") (@it | get-cell "selected");
     // bind-cells (get-cell @ssr "user_change") (get-cell @it "selected");
     // bind-cells @ssr=>user_change @it=>selected; // тут мы вводим синтаксис => как доступ к ячейкам
     // bind-cells @ssr.cells.user_change @it.cells.selected;
     // bind-cells @ssr.cells.user_change "(val) => scope.it.setParam('selected',value)"
     // c-on @ssr.cells.user_change "(val) => scope.it.setParam('selected',value)"

     render-params-list object=@it list=["selected"]; 

     dom style="height: 1em";

   }
   {{
     @it.subitems? | get-cell "visible" | m_eval "(cells,selected) => {
        if (!Array.isArray(cells)) return;
        for (let i=0; i<cells.length; i++)
          cells[i].set( i == selected ? true : false );
     }" @it.selected;
   }}
};

feature "area_empty" {
    area_content;
};

feature "area_content" {
  it:  recursive_area 
       title="Пустой"
       sibling_types=["area_empty","area_3d","area_3d_list"] 
       sibling_titles=["Пустой","3d","3d list"]
       effective_visible=(and @it.visible (@it.visible_sources?.length? > 0))

       subitems=[]
       sources_str=""
       //sources_str_2="" // используется для автогенерации
       
       //sources=(find-objects-by-pathes input=(+ @it->sources_str @it->sources_str2) root=@it->project)
       sources=(find-objects-by-pathes input=@it->sources_str root=@it->project)
       visible_sources = (@it->sources | filter_geta "visible")

       show={
          show_area_empty input=@it;
       }
       gui={
        
           object_change_type text="Укажите тип:"
              input=@it
              types=@it->sibling_types
              titles=@it->sibling_titles;

           param_field name="Разделить" {
             button "Горизонтально" cmd=@it->split-horiz;
             button "Вертикально" cmd=@it->split-vert;
           };
        
       }

       {{ x-param-option name="sources_str" option="manual" value=true }}
       {{ x-param-option name="append_process" option="visible" value=false }}
       {{ x-add-cmd name="append_process" code=(m_lambda `(view,val) => {
            view.params.sources ||= [];
            view.params.sources_str ||= '';
            if (!val) return;
            
            let curind = view.params.sources.indexOf( val );
            if (curind >= 0) return;

            let project = view.params.project;
            let add = '@' + val.getPathRelative( project );
            
            let filtered = view.params.sources_str.split(',').filter( (v) => v.length>0 && v.trim() != add)
            let nv = filtered.concat([add]).join(',');
            view.setParam( 'sources_str', nv, true);
          }` @it);
       }}

};

feature "split-screen" {
  k: output=(m_lambda "(obj,newtype) => {
       //let v='area_container_horiz';
       let v=newtype;
       let origparent = obj.ns.parent;
       let pos = origparent.ns.getChildren().indexOf( obj );
       let newcontainer = obj.vz.createObj();
       
       origparent.ns.appendChild( newcontainer,'container',true,pos );
       //let newcontainer = obj.vz.createObj({parent: origparent});

       Promise.allSettled( newcontainer.manual_feature( v ) ).then( () => {
           newcontainer.manuallyInserted=true;    
           newcontainer.ns.appendChild( obj,'area' ); // переезд в новый контейнер

           // теперь добавим новое
           if (!obj.is_feature_applied('area_3d_list')) // кривокосо внедрились - не создавать подобласти если идет операция над списком
           {
             let newcontent = obj.vz.createObj({parent: newcontainer}); 
             Promise.allSettled( newcontent.manual_feature( 'area_empty' ) ).then( () => {
                newcontent.manuallyInserted=true;    
             });
           }''
       });
    }" @k->0 @k->1);
};

// вид области которая формирует список областей из своих источников
feature "area_3d_list" {
  it: area_content
  title="3d list"
  subitems=@r->output
  show={
    //show_areas target=@area_rect input=(@area_rect->input | get_children_arr);
    dom_group { // наличие тут domgroup обеспечивает что области рисуются в прав порядке по сравнению с соседними
      @r->output | repeater { |a|
        show_area_3d input=@a;
      }
    };
  }
  gui={
           object_change_type text="тип:"
              input=@it
              types=@it->sibling_types
              titles=@it->sibling_titles;

            param_field name="Разделить" {
              button "Горизонтально" cmd=@it->split-horiz;
              button "Вертикально" cmd=@it->split-vert;
            };

            render-params-list object=@it list=["visible"];

            text "Включить процессы:";

            column {

              @it->project | geta "processes" | repeater //target_parent=@qoco 
              {
                 i: checkbox text=(@i->input | geta "title") 
                       value=(@it | geta "sources" | arr_contains @i->input)
                    {{ x-on "user-changed" {
                        toggle_visprocess_view_assoc2 process=@i->input view=@it;
                    } }};
              };

            };

            render-params-list object=@it list=["title","weight"];
  }   // gui
  {
    @it->sources |
    r: repeater { |s|
      area_3d sources=(list @s)
    };
  };
};

feature "area_3d" {  
  it: area_content 
      title="3d"
      show_fps=false
      {{ x-param-checkbox name="show_fps" title="Показать FPS"}}
      show_stats=false
      {{ x-param-checkbox name="show_stats" title="Показать статистику"}}
      {{ x-param-slider name="opacity_3d" min=0.0 max=1.0 step=0.01 }}
      opacity_3d=1.0
  show={
      show_area_3d input=@it;
  }
  {{ x-param-objref-3 name="camera" values=(@it->project | geta "cameras"); }}

       gui={
           object_change_type text="Укажите тип:"
              input=@it
              types=@it->sibling_types
              titles=@it->sibling_titles;

            param_field name="Разделить" {
              button "Горизонтально" cmd=@it->split-horiz;
              button "Вертикально" cmd=@it->split-vert;
            };

            render-params-list object=@it list=["visible","opacity_3d","camera"];

            text "Включить процессы:";

            column {

              @it->project | geta "processes" | repeater //target_parent=@qoco 
              {
                 i: checkbox text=(@i->input | geta "title") 
                       value=(@it | geta "sources" | arr_contains @i->input)
                    {{ x-on "user-changed" {
                        toggle_visprocess_view_assoc2 process=@i->input view=@it;
                    } }};
              };

            };

            render-params-list object=@it list=["title","weight","show_fps","show_stats"];
       }
       {
         //def_camera;
       }

       ;

};

///////////////////////// 
///////////////////////// показывалки
///////////////////////// 

feature "show_areas" {
  q: output=@ic->output {
    ic: insert_children input=@q->target list=(@q->input | map_geta "show" default=null | arr_flat | arr_compact) 
  };
};

feature "show_area_base" {
  k: x-set-params
     style=(m_eval "(r) => `flex: ${r} 1 0; position: relative;`" (@k->input | geta "weight"))
     //visible=(@k->input | geta "visible")
     // фишка - не показываем область если в ней нет ассоциированных источников..
     // ну посмотрим.. может быть это и спорно.. может по другому будем делать..
     // а если приживется то вынести мб в effective_visible выражение в область k->input
     //effective_visible=(and @k.input.visible (@k.input.visible_sources?.length? > 0))
     visible=@k.input.effective_visible?
     
     //{{ @k | get-cell "attach" | c-on "(env) => {debugger};"}}
  ;

  // ыдея
  //k: style=(subst "flex: ${@k->ratio} 1 0; position: relative;")
};

feature "show_area_container_horiz" {
  area_rect: row {{ show_area_base input=@area_rect->input }}
  {
     show_areas target=@area_rect input=(@area_rect->input | get_children_arr);
     //@area_rect | get_children_arr | console-log-input "ARECT C";
     //insert_children input=@area_rect list=(@area_rect->input | get_children_arr | map_geta "show")
  };
};

feature "show_area_container_vert" {
  area_rect: column {{ show_area_base input=@area_rect->input }}
  {
     show_areas target=@area_rect input=(@area_rect->input | get_children_arr);
     //insert_children input=@area_rect list=(@area_rect->input | get_children_arr | map_geta "show")
  };
};

feature "show_area_container_join" {
  area_rect: dom {{ show_area_base input=@area_rect->input }}
  {
     ars: show_areas target=@area_rect input=(@area_rect->input | get_children_arr);
     @ars->output | x-modify { x-set-params style_w="width:100%; height:100%; position: absolute !important; top: 0px; left: 0px;"; };
     // перетащим 2д в первую область..
     @ars->output | m_eval "(arr) => {
        for (let i=1; i<arr.length; i++) {
            arr[i].setParam('scene2d_tgt', arr[0].params.scene2d_tgt );
        }
     }";
     
     //insert_children input=@area_rect list=(@area_rect->input | get_children_arr | map_geta "show")
  };
};

feature "show_area_container_one_switch" {
  area_rect: column {{ show_area_base input=@area_rect->input }}
  {
     //render-params-list object=@area_rect.input list=["selected"];
     // показываем всех. будем им visible менять.
      show_areas target=@area_rect input=(@area_rect->input | get_children_arr);
     
     //show_areas target=@area_rect input=(list (@area_rect.input.subitems | geta @area_rect.input.selected));
  };
};

// короче это работает но... дальше уже глючит 3d..
feature "show_area_container_opacity_switch" {
  area_rect: dom tag="div" {{ show_area_base input=@area_rect->input }}
  {
     ars: show_areas target=@area_rect input=(@area_rect->input | get_children_arr);

     @ars->output | x-modify { x-set-params style_w="width:100%; height:100%; position: absolute !important; top: 0px; left: 0px;"; };
     // перетащим 2д в первую область..
     @ars->output | m_eval "(arr) => {
        for (let i=1; i<arr.length; i++) {
            arr[i].setParam('scene2d_tgt', arr[0].params.scene2d_tgt );
        }
     }";

     m_eval "(opcoef, opcells) => {
       //debugger;
       if (!opcells) return;
       if (opcells.length == 0) return;
       if (opcells.length == 1) return opcells[0].set(1);
       let d = 1.0 / (opcells.length-1);
       for (let i=0; i<opcells.length; i++) {
          let md = i * d;
          let mt = 0; // вычисляем лесенку
          if (opcoef >= md-d && opcoef <= md+d) { // мы в области опреления
            let q = (opcoef-(md-d)) / (d);
            // это доля от 0 до 2 где апогей должен быть в 1
            // проще всего синус чем доли мучать
            mt = Math.sin( Math.PI * q / 2);
          }
          // console.log(i,mt)
          opcells[i].set(mt);
       };
     }" @area_rect.input.opacity_coef 
        (@area_rect->input | get_children_arr | arr_filter_by_features features="area_content" | get-cell "opacity_3d");
     //insert_children input=@area_rect list=(@area_rect->input | get_children_arr | map_geta "show")
  };
};


///////////////////////////////////////////////////////// главное и неглавное рендеринг

feature "show_3d_scene_main" {
  scene_3d_view: 
    view3d style="width:100%; height:100%; " 
    renderer=@r1 // тпУ
    camera_control={ orbit-control }
    scene3d=[]
    { // max-height: 100vh;
      // max-height 100vh багфиксит грида
    
    // если вытащить его в хвост фичи (замкнуть view3d) то оно перестает видеть scene_3d_View почему-то
    r1: render3d
          bgcolor=[0.1,0.2,0.3]
          target=@scene_3d_view
          //input=@scene_3d_view->scene3d // кстати идея так-то сделать аналог и для 2д - до-бирать детей отсель
          //camera=@scene_3d_view->camera
          subrenderers=@scene_3d_view->subrenderers
          //{{ console_log_params "UUURRR" }}
      {
          //camera3d pos=[-400,350,350] center=[0,0,0];

          //orbit_control;
          //@r1 | insert-children list=@scene_3d_view->camera_control;
      };
   };

   ////
   /* может это явно зато?
   connections {
    scene3d_view->subrenders => renderes->subrenderers;
   }
   */
   
};

// вход - scene3d, camera, scene2d (надписи)
// можно переделать будет на раздельное питание
feature "show_3d_scene_r" {
  scene_3d_view: 
    dom style="width:100%; height:100%;" tag="div"
    // renderer=@r1 // тпУ
    private_camera=@r1->private_camera // это на выход
    camera_control={ orbit-control }
    { // max-height: 100vh;
      // max-height 100vh багфиксит грида
    
    // если вытащить его в хвост фичи (замкнуть view3d) то оно перестает видеть scene_3d_View почему-то
    r1: subrenderer
          bgcolor=[0.1,0.2,0.3]
          target=@scene_3d_view
          input=@scene_3d_view->scene3d // кстати идея так-то сделать аналог и для 2д - до-бирать детей отсель
          camera=@scene_3d_view->camera
          //{{ console_log_params "UUURRR" }}
      {
          //camera3d pos=[-400,350,350] center=[0,0,0];

          //orbit_control;
          let camera_control = (@r1 | insert-children list=@scene_3d_view->camera_control | geta 0);
          
          /* да это красиво. но оно трясется -- изза обратной связи с объектом камеры похоже.
             и плюс изза одновременной работы нескольких update. тут надо крепко поработать пока не приоритено.
          @r1 | get-cell "frame" | c-on "(eventargs,threejs_control) => { 
          if(threejs_control?.update) threejs_control.update(); }" @camera_control.threejs_control;
          */
      };
   };
   
};

feature "show_area_3d" {
  area_rect: dom style_k="border: 1px solid grey;" 
     scene2d_tgt=@dg
             {{ show_area_base input=@area_rect->input }}
  {
    process_rect: show_3d_scene_r
        //camera_control={ map-control }
        // renderer - установим снаружи..

        scene3d=(@area_rect.input.sources 
            | map_geta "scene3d" default=[] 
            | repeater target_parent=@area_rect { |code|
                computing_env code=@code @process_rect @area_rect.input.opacity_3d;
            }
            | map_geta "output" default=null 
              // уберем содержимое сцены если область экрана отключена
            | pass_input_if (@area_rect->input | geta "visible") default=null
            )
        camera=(@area_rect->input | geta "camera")
        style="width:100%; height:99%;"
        // {{ @area_rect->input | geta "sources" | get-cell "show-view-attached" | set-cell-value @process_rect }}
    ;

    extra_screen_things: 
        column style="padding-left:0em; position:absolute; bottom: 1em; left: 1em;" 
        class='vz-mouse-transparent-layout extra-screen-thing'
        {
             dg: dom_group
             {
               @area_rect->scene2d_tgt | insert_children list=(@area_rect.input.sources | map_geta "scene2d" default=[] | arr_flat);

               if (@area_rect->input | geta "show_fps" default=false) then={
                 show_render_fps renderer=@process_rect->renderer;
               };               
               if (@area_rect->input | geta "show_stats" default=false) then={
                 show_render_stats renderer=@process_rect->renderer;
               };
             }
        };

 }; // area-rect
};

feature "show_area_empty" {
  area_rect: dom style="flex: 1 1 0; position: relative;"
  {
           object_change_type text="Укажите тип:"
              input=@area_rect->input
              types=(@area_rect->input | geta "sibling_types")
              titles=(@area_rect->input | geta "sibling_titles");
  }; // area-rect
};

feature "show_visual_tab_recursive" {
   svr: dom_group
   {
    rrviews: 
    row style="position: absolute; top: 0; left: 0; width:100%; height: 100%; 
        justify-content: center;"
    {
      show_areas input=(list (@svr->input | geta "primary_container")) target=@rrviews;
    }; // global row rrviews
   }; // domgroup
}; // show vis tab

feature "show_visual_tab_recursive_gui" {
   svr: dom_group
      //screenshot_dom = @rrviews_group->dom
   {
    containers_params: column; 

    insert-children input=@containers_params list=@svr.input.primary_container.show_gui?;
         //list=(find-objects-bf features="area_container" root=@svr->input | map_geta "show_gui");
    /*
    insert-children input=@containers_params 
         list=(find-objects-bf features="area_container" root=@svr->input | map_geta "show_gui");
         */
    // подумать быть может отдать им в управление и пусть там сами ходят по своим visible-subitems...
    // и вовсе быть может отдать им также в управленрие show-sources-params
    // ну т.е. сейчас мы как бы вытащили оное все.. а теперь хотим взад..
    // либо поступить как с 3д - через computing env пусть добавляют что хотят..

    actions_co: column visible=(@svr->input | geta "actions" default=null) 
    ;
    insert_children input=@actions_co list=(@svr->input | geta "actions" default=null);

    show_sources_params input=(@svr->input | geta "sources") auto_expand_first=false;
   }; // domgroup

}; // show vis tab
