load files="lib3dv3 csv params io gui render-params df scene-explorer-3d 12chairs.cl landing.cl gui4.cl";

///////////////////////////////////////
/////////////////////////////////////// задача Ракета вид отображения 1
///////////////////////////////////////

views: list=(list @view1 @view2);

// кстати вот тут можно было бы из фич городить
// фича преобразовывает параметры main и screen, дополняя их
// но в целом это напомнило бы вещи в духе newobj().add_thing1(params1..).add_thing2(params2..) 
view2:
  title="Ракета" 
  code="free"
  view1
  main={
        sol: 
        landing-sol scene=@r1 screen=@extra_screen_things {
            data_visual_layer   selected_show="models";
            static_visual_layer selected_show="axes";
        };

        r1: render3d 
              bgcolor=[0.1,0.2,0.3]
              target=@v1
        {
            camera3d pos=[0,0,100] center=[0,0,0];
            orbit_control;
        };

  };

view1:
  title="Общий вид"
  code="view1"
  main={
        sol: 
        landing-sol scene=@r1 screen=@extra_screen_things {
            data_visual_layer   selected_show="ptstr";
            static_visual_layer selected_show="axes";
            static_visual_layer selected_show="pole";  
        };

        r1: render3d 
              bgcolor=[0.1,0.2,0.3]
              target=@v1
        {
            camera3d pos=[0,0,100] center=[0,0,0];
            orbit_control;
        };

  }

  screen={

          row style="z-index: 3; position:absolute;  color: white;" 
              class="vz-mouse-transparent-layout" align-items="flex-start" // эти 2 строчки решают проблему мышки
          {
            collapsible text="Основные параметры" style="min-width:250px;" padding="10px"
            {

              paint_kskv_gui input=@sol;
            };

            extra_screen_things: column {};

          }; // row

          //render_layers root=@sol style="position:absolute; right: 10px; top: 10px;";

          column style="position:absolute; right: 10px; top: 10px;" {
            collapsible text="Визуальные объекты" 
            style="min-width:250px" 
            style_h = "max-height:90vh;"
            body_features={ set_params style_h="max-height: inherit;"}
            {
             s: switch_selector_column items=["Объекты данных","Статичные","Текст"] style="width:200px;";

                show_one 
                  index=@s->index 
                  style_h="max-height: inherit;"
                {
                  
                  render_layers root=@sol->l1;
                  render_layers root=@sol->l2;
                  render_layers root=@sol->l3;

                };
            };  
          };

          v1: view3d style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2" extra=@extra_screen_things;

  }; // screen




///////////////////////////////////////
/////////////////////////////////////// точка входа
///////////////////////////////////////

main: {};

mainscreen: screen auto-activate {

   column style="width:100%;" {

     view_selector: switch_selector_row padding="1em" items=(@al->list | map_param "title" );

     al: create_by_user_type index=@view_selector->index 
          list=@views->list
          mapping={
              channel="main" target=@main;
              channel="screen" target=@viewscreen;
          };

     viewscreen: dom;

   }
    
};

/////////////////////////////////////////////////
/////////////////////////////////////////////////
/////////////////////////////////////////////////
/////////////////////////////////////////////////


//debugger_screen_r;


// вход: root
register_feature name="render_layers" {
        main: column style="max-height:inherit;" gap="0.5em" {
          if condition=@main->back {
             button text="назад" {
                func main=@main code=`
                    
                    let pop = env.params.main.params.back_stack.pop();
                    let nb = env.params.main.params.back_stack.slice(-1)[0];
                    env.params.main.setParam("root", pop );
                    env.params.main.setParam("back", nb ? true : false );
                    //include_root
                `;
             };
          };

          // содержимое этого слоя - то бишь объекты в нем

/*
          if condition=(@main->root | get_param name="title") {
            text tag="h2" text=(@main->root | get_param name="title");
          };
*/        

          if condition=(@main->root | get_param name="new") {

            button text="Добавить" {
             creator target=(@main->root | get_param name="for") 
                     input=(@main->root | get_param name="new")
              {{ onevent name="created" code=`
                 args[0].manuallyInserted=true; 
                 console.log("created",args[0])` 
              }};
           };
          };

          if condition=(@main->root | get_param name="find") {
            co: layers_gui3 input=@main->root
              text=(@co->input | get_param name="title")
              layer=(@co->input | get_param name="new")
              pattern=(@co->input | get_param name="find")
              pattern_root=(@co->input | get_param name="for")
              target=(@co->input | get_param name="for")
              style_qq="max-height: 100vh; overflow-y: auto;";
          };
            

          // колонка с перечнем слоев
          column gap="5px" {

            find-objects-bf features="layer_v1" root=@main->root include_root=false debug=true recurvsive=false
            
            | repeater {
                rt: column style="background: rgba(99, 116, 137, 0.36);padding: 5px; border-radius: 5px;" {
                  button text=(@rt->input | get_param name="title") {
                    func main=@main input=@rt->input code=`
                      
                      env.params.main.setParam("back_stack", (env.params.main.back_stack || []).concat( [env.params.main.params.root] ) );
                      env.params.main.setParam("back", true );
                      env.params.main.setParam("root", env.params.input );

                      //include_root
                    `;
                  } 
                  //q_render_layers root=@rt->input include_root=false;

                };
              }; // repeater

          }; // inner column



        }; // main column
}; // feature

// collapsible с active-флажком
register_feature name="panel3" {
  cola:
  column
  {
    shadow_dom {
      row {
        btn: text text=@cola->text cmd="@pcol->trigger_visible" flex=1;
        cba: checkbox value=@cola->active cola=@cola {{
          onevent name="user-changed" {
            emit_event object=@cola name="user-changed-active";
          };
        }};
      };

      pcol:
      column {{ use_dom_children from=@cola; }};

      deploy_features input=@btn  features=@cola->button_features;
      deploy_features input=@pcol features=@cola->body_features;
    };

  };
};

register_feature name="layers_gui3" {

  lgui: column gap="0.4em" 
  {
    
    find-objects pattern=@lgui->pattern pattern_root=@lgui->pattern_root
//     | arr_reverse
     | repeater {
        coco: column 
          text=(@.->input | get_param name="gui_title") 
          body_features=@lgui->each_body_features
          active=(@.->input | get_param name="active")
          fon
          rounded
        {{
          connection event_name="user-changed-active" code=`
            env.host.params.input.setParam("active",args[0]);
          `;
        }}
        {
          paint_kskv_gui input=@coco->input;
          button text="Удалить" input=@coco->input code=`env.params.input.remove();`;
        };
     };
 
  };

};