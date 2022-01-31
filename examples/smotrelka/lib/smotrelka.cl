load files="lib3dv3 csv params io gui render-params df
            scene-explorer-3d misc
            ";

register_feature name="smotrelka" {

smotrelka: env {

  r1: render3d 
      bgcolor=[0.1,0.2,0.3]
      target=@view1
  {
    camera3d pos=[0,0,100] center=[0,0,0];
    orbit_control;
  };

  screen auto-activate padding="1em" {

    column {
      dom tag="h3" innerText="Смотрелка" style="margin-bottom: 0.3em;";
      button text="123";
    };

    view1: view3d fill_parent below_others;
    //v2: view3d style="position: absolute; right: 20px; bottom: 20px; width:500px; height: 200px; z-index: 5;";

  };    

 };
  
};