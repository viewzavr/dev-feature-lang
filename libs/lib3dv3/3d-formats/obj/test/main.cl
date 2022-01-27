load files="lib3dv3 csv params io gui render-params df misc scene-explorer-3d";
// todo: уметь загружать lib3dv3/gltf-format

/// рендеринг 3D сцены

render3d bgcolor=[0.1,0.2,0.3] target=@view
{
    orbit_control;
    camera3d pos=[0,0,40] center=[0,0,0];

    dat: load_file file="http://viewlang.ru/assets/models/lava/rb_data_0_1.obj" | parse_obj;

    @dat | mesh showparams dbg 
       {{ scale3d  showparams coef=0.05; 
          rotate3d showparams;
          color3d color=[0,1,0] showparams;
       }} material = @me1->output_material;

    points positions=[0,0,0,50,0,0,0,50,0];
};

/// интерфейс пользователя gui

screen auto-activate {

  column padding="1em" style="z-index: 3; position:absolute;" {
    find-objects pattern="** showparams" | render-guis with_features=true;

    
  };

  view: view3d style="position: absolute; width:100%; height: 100%; z-index:-2";

};

///////////////////// визуальная отладка

debugger_screen_r;
