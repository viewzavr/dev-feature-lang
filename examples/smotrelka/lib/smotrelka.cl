load files="lib3dv3 csv params io gui render-params df
            scene-explorer-3d misc utils.cl visual-layers.cl
            ";

register_feature name="smotrelka" {

smotrelka: env {

  datahub: a=5;

  scene3d: node3d {
      //axes_box size=10;
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

///////////////////////////////////////////////////

t0: output=@. list=(@. | get_children_arr | arr_filter code=`(c) => c.params.title`) {
  file: title="File input" feature={ show: file_data include_gui; };
  file_many: title="Multi-file input" feature={ show: multi_file_data include_gui; };
  text_csv: title="CSV text" feature={ show: text_csv_data include_gui; };
};

t0_parser: output=@. list=(@. | get_children_arr | arr_filter code=`(c) => c.params.title`) {
  csv: title="CSV" feature={ show: parse_csv include_gui; };
  vtk: title="Vtk binary" feature={ show: parse_vtk_points include_gui; };
};

register_feature name="data_layer" {
  root: {

    selected_show: param_combo 
       values=(@t0->list | arr_map code=`(c) => c.ns.name`)
       titles=(@t0->list | arr_map code=`(c) => c.params.title`);

    deploy_many input=( @t0 | get child=@selected_show->value | get param="feature" );
  };

};

register_feature name="multi_file_data" {
  root: 
    file=(@root->files | get name=@root->current_index)
    {{dbg}}
  {
    files: param_files;
    current_index: param_slider min=0 max=@files->max value=0 step=1;

    // читалка и парсер
    dat: load_file file=@root->file | parse_csv;
    //dfenv: df_to_env input=@dat->output;    
  };
};

register_feature name="file_data" {
  root: {
    param_file name="file";

    // читалка и парсер
    dat: load_file file=@root->file | parse_csv;
    //dfenv: df_to_env input=@dat->output;    
  };
};

register_feature name="text_csv_data" {
  troot: {
    param_text name="content";

    // читалка и парсер
    dat: @troot->content | parse_csv;
    //dfenv: df_to_env input=@dat->output;    
  };
};

///////////////////////////////////////////////////

t1: output=@. list=(@. | get_children_arr | arr_filter code=`(c) => c.params.title`) {
  mesh: title="Mesh show" feature={ show: mesh_visualizer include_gui; };
  points: title="Points show" feature={ show: points_visualizer include_gui; };
  axes: title="Axes" feature={ show: axes_box size=10 include_gui; };
};

register_feature name="visual_layer" {
  vlayer: node3d {

    selected_show: param_combo 
       values=(@t1->list | arr_map code=`(c) => c.ns.name`)
       titles=(@t1->list | arr_map code=`(c) => c.params.title`);

    deploy_many input=( @t1 | get child=@selected_show->value | get param="feature" ) 
      {{ keep_state }};
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
          //console.log("EEEE generated dump",dump);

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
          //console.log("UUUU0-dump",dump);

          if (!dump) return;
          
          //dump.keepExistingChildren = true;
          //dump.keepExistingParams = true;
          dump.manual = true;
          tenv.restoreFromDump( dump, true );
        `;     
  };
};