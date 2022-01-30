load files="lib3dv3 csv params io gui render-params df misc scene-explorer-3d";
// todo: уметь загружать по спецификатору lib3dv3/gltf-format

////////////////// главные параметры

lavaparams: showparams {
      ptradius: param_slider min=0.0001 max=1 value=0.05 step=0.0001;
      slice_delta: param_float value=5;
      
      vtkfile: param_file value="http://127.0.0.1:8080/vis-data/lava/src/1_3_v0/ParticleData_Fluid_3370.vtk"
        ;
        // value="http://127.0.0.1:8080/vis-data/lava/src/05_1_v100/ParticleData_Fluid_5000.vtk";
        // "https://viewlang.ru/assets/lava2/ParticleData_Fluid_1192.vtk" 
      objfile: param_file value="http://127.0.0.1:8080/vis-data/lava/src/obj/rb_data_0_1.obj"
        ;
        // "http://viewlang.ru/assets/models/lava/rb_data_0_1.obj"
};

////////////////////////// данные
dat: load_file_binary file=@lavaparams->vtkfile | parse_vtk_points | compute_magnitude_col;
obj: load_file file=@lavaparams->objfile | parse_obj;

/// рендеринг 3D сцены

rend: render3d bgcolor=[0.1,0.2,0.3] target=@view
{
    orbit_control;
    camera3d pos=[0,40,40] center=[0,0,0];

    text3d_one text="loading..." showparams;

    ////////////////////////////////////// лава
    lavacontainer: node3d {{ stack_children }} 
    {
      @dat | vtk_points_layer gui_title="Visual layer" showparams2;
    };

    ////////////////////////////////////// вулкан

    @obj | mesh showparams 
       {{ auto_scale size=100 input=@rend->output; }}
       {{ 
          rotate3d showparams;
          color3d color=[0,0.5,0] showparams;
       }};// material = @me1->output_material;    
};




/// интерфейс пользователя gui


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
           };
         
        };
    };
};

screen auto-activate {

  column padding="1em" style="
    z-index: 3; 
    position:absolute;
    background: rgba(255,255,255,0.5);
    overflow-y: scroll; max-height: 100%;" 
   {

    find-objects pattern="** showparams" | render-guis;

    find-objects pattern="** showparams2" | render-guis-nested;

    bt: button text="get csv" {
      func {
        generate_csv input=(@dat | vtk_points_to_normalized_df) | download_file_to_user filename="lava.csv";
      };
    };

    // text text="Select material for surface";
    // me1: material_generator_gui text="Surface look";
  };

  view: view3d fill_parent below_others;

};

///////////////////// визуальная отладка

debugger_screen_r;

//////////////////// доп-ы

load files="utils.cl";