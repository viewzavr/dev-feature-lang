load files="lib3dv3 csv params io gui render-params df misc scene-explorer-3d";
// todo: уметь загружать lib3dv3/gltf-format

/// рендеринг 3D сцены

render3d bgcolor=[0.1,0.2,0.3] target=@view
{
    orbit_control;
    camera3d pos=[0,0,40] center=[0,0,0];

    model: render_gltf src="http://viewlang.ru/assets/models/Lake_IV_Heavy.glb" showparams dbg 
       rotations=@rall->output {{ scale3d coef=@rs->value; }} ;

    points positions=[0,0,0,50,0,0,0,50,0];
};

/// интерфейс пользователя gui

screen auto-activate {

  column padding="1em" style="z-index: 3; position:absolute;" {
    find-objects pattern="** showparams" | render-guis;

    r1: angle_slider text="rotate_x";
    r2: angle_slider text="rotate_y";
    r3: angle_slider text="rotate_z";

    text text="scale";
    rs: slider max=10 step=0.01 value=1;

    rall: compute_output r1=@r1->value r2=@r2->value r3=@r3->value code=`
      return [env.params.r1*Math.PI/180, env.params.r2*Math.PI/180, env.params.r3*Math.PI/180];
    `;
  };

  view: view3d style="position: absolute; width:100%; height: 100%; z-index:-2";

};

///////////////////// визуальная отладка

debugger_screen_r;


register_feature name="angle_slider" {
  gr: dom_group value=@sl->value {
    text text=@gr->text;
    sl: slider max=360 value=@gr->value;
  }
}