load files="lib3dv3 csv params io gui render-params df misc scene-explorer-3d";
// todo: уметь загружать lib3dv3/gltf-format

/// рендеринг 3D сцены

render3d bgcolor=[0.1,0.2,0.3] target=@view
{
    orbit_control;
    camera3d pos=[0,0,40] center=[0,0,0];

    dat: load_file_binary file="https://viewlang.ru/assets/lava2/ParticleData_Fluid_1192.vtk" | parse_vtk_points;

    @dat | points showparams dbg 
       {{ scale3d coef=0.05 showparams; 
          rotate3d showparams;
          color3d color=[0,1,0] showparams;
       }};

    points positions=[0,0,0,50,0,0,0,50,0];
};

/// интерфейс пользователя gui

screen auto-activate {

  column padding="1em" style="z-index: 3; position:absolute;" {
    find-objects pattern="** showparams" | render-guis with_features=true;

    bt: button text="get csv" {
      func {
        //setter target="@bt->dom_style_backgroundColor" value="cyan";
        //setter target="@bt->text" value="cyan";
        generate_csv input=(@dat | vtk_points_to_normalized_df) | download_file_to_user filename="lava.csv";
        //setter target="@bt->dom_style_backgroundColor" value="";
      };
    };
  };

  view: view3d style="position: absolute; width:100%; height: 100%; z-index:-2";

};

///////////////////// визуальная отладка

debugger_screen_r;

