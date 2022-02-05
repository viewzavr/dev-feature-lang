load files="lib3dv3 csv params io gui render-params df
            scene-explorer-3d misc utils.cl
            ";

register_feature name="smotrelka" {

smotrelka: env {

  datahub: a=5;

  scene3d: node3d {
      axes_box size=10;
  };

  render: render3d 
      bgcolor=[0.1,0.2,0.3]
      target=@view1
      input=@scene3d->output
  {
    camera3d pos=[0,0,100] center=[0,0,0];
    orbit_control;


  };

  screen auto-activate padding="1em" {

    column gap="1em" {
      dom tag="h3" innerText="Смотрелка" style="margin-bottom: 0.3em;";
      button text="Добавить слой данных" {
        creator target=@datahub input={
          data_layer;
        } {{ onevent name="created" code=`args[0].manuallyInserted=true;` }};
      };

      column gap="0.5em" {
        find-objects pattern="** data_layer" | render-guis-nested;
      };

      button text="Добавить визуальный слой" {
        creator target=@scene3d input={
          visual_layer;
        } {{ onevent name="created" code=`args[0].manuallyInserted=true; args[0].historicalType='visual_layer';` }};
      };
      // вопросов много - если вызывать до, то что она запомнит в тип?
      // короче пока так

      column gap="0.5em" {
        find-objects pattern="** visual_layer" | render-guis-nested;
        /*
        find-objects pattern="** visual_layer" | repeater {
          column {
            button text="visual layer";
            column style="padding-left:1em" {
              button text="remove" cmd=;
            };
          };
        };
        */
      };
    };

    view1: view3d fill_parent below_others;
    //v2: view3d style="position: absolute; right: 20px; bottom: 20px; width:500px; height: 200px; z-index: 5;";

  };

 };
  
};

register_feature name="data_layer" {
  root: {
    param_file name="file";

    // читалка и парсер
    dat: load_file file=@root->file | parse_csv;
    dfenv: df_to_env input=@dat->output;
  };

};

register_feature name="visual_layer" {
  node3d {
    
    visualizer: mesh_visualizer include_gui;
  };
};

register_feature name="mesh_visualizer" {
   root: mesh input=@collected_df {

     collected_df: copy_params_to_obj {{dbg}} {
        link to=".->X" from=@input_data->X tied_to_parent=true;
        link to=".->Y" from=@input_data->Y tied_to_parent=true;
        link to=".->Z" from=@input_data->Z tied_to_parent=true;
     };

     connection object=@collected_df event_name="param_changed" root=@root code=`
       console.log("SEEEEEEE");
       if (env.params.root) {
         console.log("sending");
        env.params.root.signalTracked( "input" );
       }
     `;

     /*
     {
       call target=@root name="signalTracked"
       @root->signalTracked "input";
     }
     */

     input_data: include_gui {
       param_ref df_column_ref name="X";

       param_ref df_column_ref name="Y";
       param_ref df_column_ref name="Z";
     };
   };
};

register_feature name="params_to_df" {
  js code=`
    function refresh() {
       env.host.colnames = env.host.getParamsNames();
    }
    env.host.on('gui-added',refresh);
    refresh()
  `;
};

register_feature name="df_column_ref" {
  //param_ref crit_fn="(obj) => obj.colnames || []";
  crit_fn="(obj) => obj.colnames || []";
};

register_feature name="render-guis-nested" {
  rep: repeater opened=true {
    col: column {
          button 
            text=(compute_output object=@col->input code=`return env.params.object?.params.gui_title || env.params.object?.ns.name`) 
            cmd="@pcol->trigger_visible";

          pcol: column visible=true style="padding-left: 1em;" {
            render-params object=@col->input;

            find-objects pattern_root=@col->input pattern="** include_gui" 
               | render-guis;

            button text="Удалить" obj=@col->input {
              call target=@col->input name="remove";
            };
           };
         
        };
    };
};