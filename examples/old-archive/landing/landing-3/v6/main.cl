// здесь третья система плагинов

load files="lib3dv3 csv params io gui render-params df scene-explorer-3d";

load files="v-data-config.cl" ;

//traj_projej: @dat | skip

r1: render3d 
      bgcolor=[0.1,0.2,0.3]
      target=@v1
  {
    camera3d pos=[0,0,100] center=[0,0,0];
    orbit_control;

    //axes_box size=100;
    //@dat | points;

    //@dat | df_filter code=`(line) => line.TEXT?.length > 0` | text3d myvisual size=0.1 visible=@cb1->value; // color=[0,1,0];


  };

mainscreen: screen auto-activate {
  row style="z-index: 3; position:absolute;  color: white;" { 
  column style="background-color:rgba(200,200,200,0.2); overflow-y: scroll; max-height: 90vh;" 
    padding="0.3em" margin="0.7em"
    {
    dom tag="h3" innerText="Параметры" style="margin-bottom: 0.3em;"
    {{ dom_event name="click" cmd="@rp->trigger_visible" ;}};

    rp: column gap="0.5em" padding="0em" {
      render-params object_path="@mainparams";
    };


    dom tag="h3" innerText="Визуальные слои";

      button text="+ Добавить слой" style="margin-bottom:1em;" {
        creator target=@addons_place input={
          visual_layer;
        } {{ onevent name="created" code=`args[0].manuallyInserted=true;` }};
      };

      column gap="0.1em" {
        cb: combobox values=(@fo->output | arr_map code=`(r,index) => (1+index).toString()`)
               index=(@fo->output | compute_output code=`return (env.params.input?.length || 1)-1` | console_log text="EEEEEEEE");
        //cb: combobox values=(@fo->output | monitor_params params=["gui_title"] | arr_map code=`(r,index) => (1+index).toString() + " - " + (r.params.gui_title || r.ns.name)`);

        fo: find-objects pattern="** visual_layer";
        cobj: value=(@fo->output | get name=@cb->index);
        render-guis-nested2 input=@cobj->value; 
      };


    dom tag="h3" innerText="Экранные слои";

      button text="+ Добавить слой" style="margin-bottom:1em;" {
        creator target=@addons_place input={
          screen_layer;
        } {{ onevent name="created" code=`args[0].manuallyInserted=true;` }};
      };

      column gap="0.1em" {
        cb: combobox values=(@fo->output | arr_map code=`(r,index) => (1+index).toString()`)
               index=(@fo->output | compute_output code=`return (env.params.input?.length || 1)-1` | console_log text="EEEEEEEE");
        //cb: combobox values=(@fo->output | monitor_params params=["gui_title"] | arr_map code=`(r,index) => (1+index).toString() + " - " + (r.params.gui_title || r.ns.name)`);

        fo: find-objects pattern="** screen_layer";
        cobj: value=(@fo->output | get name=@cb->index);
        render-guis-nested2 input=@cobj->value; 
      };      

  };

  extra_screen_things: column {

  };

  }; // row

  v1: view3d style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2";

  //v2: view3d style="position: absolute; right: 20px; bottom: 20px; width:500px; height: 200px; z-index: 5;";
  
};

addons_place: {

    visual_layer selected_show="axes" gui_title="Оси";
    visual_layer selected_show="ptstr" gui_title="Траектория";

}; //  todo fix addons_place:; or even addons_place: {};

debugger_screen_r;

register_feature name="visual_layer" {
   addon_layer variants=@t1;
};

register_feature name="screen_layer" {
   addon_layer variants=@t1s;
};

// вход: variants - объект содержащий список типов добавок.

register_feature name="addon_layer" {
  vlayer: 
    gui_title=( @t1 | get child=@selected_show->value | get param="title")
    variants_list=(@.->variants | get_children_arr | arr_filter code=`(c) => c.params.title`)
  {

    //gui_title: param_string;

    selected_show: param_combo 
       values=(@vlayer->variants_list | arr_map code=`(c) => c.ns.name`)
       titles=(@vlayer->variants_list | arr_map code=`(c) => c.params.title`);

    deploy_many_to target=@r1 
       input=( @vlayer->variants | get child=@selected_show->value | get param="render3d-items" )
       include_gui_from_output 
       {{ keep_state }}; // keep_state сохраняет состояние при переключении типов объектов

    deploy_many_to target=@extra_screen_things 
       input=( @vlayer->variants | get child=@selected_show->value | get param="screen-items" )
       include_gui_from_output 
       {{ keep_state }}; // keep_state сохраняет состояние при переключении типов объектов   

  };
};

load files="visual-layers.cl";
t1:  visual_layers output=@.;
t1s: screen_layers output=@.;

// идеи:
// t1: load_item from="visual-layers.cl";
// t1: {{ load_children from="visual-layers.cl" }};

// вход - input, список объектов чьи гуи нарисовать
register_feature name="render-guis-nested" {
  rep: repeater opened=true {
    col: column {
          button 
            text=(compute_output object=@col->input code=`return env.params.object?.params.gui_title || env.params.object?.ns.name`) 
            cmd="@pcol->trigger_visible";

          pcol: column visible=true style="padding-left: 1em;" {
            render-params object=@col->input;

            find-objects pattern_root=@col->input pattern="** include_gui_inline"
               | 
               repeater {
                 render-params object=@.->input;
               };

            find-objects pattern_root=@col->input pattern="** include_gui"
               | render-guis;

            button text="Удалить" obj=@col->input {
              call target=@col->input name="remove";
            };
           };
         
        };
    };
};

// вход - input, объект чьу гуи нарисовать
register_feature name="render-guis-nested2" {
  col: column visible=true style="padding-left: 1em;" {

      column {

        render-params object=@col->input;

        find-objects pattern_root=@col->input pattern="** include_gui_inline"
             | 
             repeater {
               render-params object=@.->input;
             };

        find-objects pattern_root=@col->input pattern="** include_gui"
           | render-guis;

        // соберем из объектов созданных в каналах (render3d-items и т.п.)  
        find-objects pattern_root=@col->input pattern="** include_gui_from_output"
           | repeater {
               subr: column { // здесь input это каждый найденный объект в полях output

                  @subr->input | get param="output" | repeater {
                        find-objects pattern_root=@.->input pattern="** include_gui_inline"
                          | 
                           repeater {
                             render-params object=@.->input;
                           };
                   };

                  @subr->input | get param="output" | repeater {
                        find-objects pattern_root=@.->input pattern="** include_gui"
                          | render-guis;
                      };
                   };
               };

       };

       column {
         render-guis input=@extra;
       };

       extra: gui_title = "Настройки" {
          param_string name="title" value=(@col->input | get param="gui_title")
          {{
             onevent name="param_value_changed" tgt=@col->input in=@extra->title code=`
               if (env.params.tgt)
                   env.params.tgt.setParam("gui_title", env.params.in );
             `;
          }};
          param_cmd name="удалить слой" {
            call target=@col->input name="remove";
          };
        };

/*
       button text="[x]" style="position: absolute; right: 0px; bottom: 0px;" {
            call target=@col->input name="remove";
       };
*/       
         
   };
};


register_feature name="keep_state" {
  ksroot: {
    connection object=@ksroot->.host event_name="before_deploy" vlayer=@ksroot code=`
          console.log("EEEE0 args=",args,"object=",env.params.object);
          let envs = args[0] || [];
          let existed_env = envs[0];
          
          if (!existed_env) return;
          
          let dump = existed_env.dump();
          console.log("EEEE generated dump",dump);

          //if (!env.params.vlayer) return;
          env.params.vlayer.setParam("item_state", dump);
        `;

        //onevent name="after_deploy" vlayer=@vlayer code=`
        // выглядит что проще добавить в onevent тоже обработку object, и уметь делать ссылки на хост.. @env->host
        // ну или уже сделать параметр такой..
    connection object=@ksroot->.host event_name="after_deploy" vlayer=@ksroot code=`
          //console.log("UUUU0",args);
          let envs = args[0] || [];
          let tenv = envs[0];
          
          if (!tenv) return;

          let dump = env.params.vlayer.getParam("item_state");
          console.log("UUUU0 using dump",dump);

          if (!dump) return;
          
          //dump.keepExistingChildren = true;
          //dump.keepExistingParams = true;
          dump.manual = true;
          tenv.restoreFromDump( dump, true );
        `;     
  };
};