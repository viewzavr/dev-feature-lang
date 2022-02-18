load files="lib3dv3 csv params io gui render-params df scene-explorer-3d 12chairs.cl gui2.cl landing.cl";

///////////////////////////////////////
/////////////////////////////////////// задача
///////////////////////////////////////

sol: landing-sol scene=@r1 screen=@extra_screen_things;
sol2: landing-sol scene=@r2 screen=@extra_screen_things;

///////////////////////////////////////
/////////////////////////////////////// сцена
///////////////////////////////////////

r1: render3d 
      bgcolor=[0.1,0.2,0.3]
      target=@v1
{
    camera3d pos=[0,0,100] center=[0,0,0];
    orbit_control;
};

r2: render3d 
      bgcolor=[0.1,0.2,0.3]
      target=@v2
      camera=@r1->camera
{
    //camera3d pos=[0,0,100] center=[0,0,0];
    orbit_control;
};

///////////////////////////////////////
/////////////////////////////////////// плоский интерфейс
///////////////////////////////////////

mainscreen: screen auto-activate {
  row style="z-index: 3; position:absolute;  color: white;" 
      class="vz-mouse-transparent-layout" align-items="flex-start" // эти 2 строчки решают проблему мышки
  { 

    column padding="0.3em" margin="0.7em" gap="0.5em"
    {
      button text="Добавить";  
      //render-params object_path="@sol";
      collapsible text="Основные параметры" {
        render-guis-nested2 input=@sol->params_obj;
      };

      render-layers input=@sol->layers for=@sol;
    };

    extra_screen_things: column {
    };

  }; // row

  v1: view3d style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2";

  v2: view3d style="position: absolute; right: 20px; bottom: 20px; width:500px; height: 200px; z-index: 5;";
  
};


register_feature name="plashka" {
  style="background: rgba(99, 116, 137, 0.36);padding: 5px;";
  body_features={ set_params style="overflow-y: auto; max-height: 90vh; padding:0.2em 0.2em 0.2em 0.4em; gap: 0.2em;" }
  //body_features={ set_params dom_style_overflowY="auto" dom_style_maxHeight="90vh"; }
  each_body_features={
    set_params style="border-left: 8px solid #00000042;
                      border-bottom: 1px solid #00000042;
                      border-radius: 0px;
                      margin-bottom: 5px;
                     ";
  };
};

register_feature name="render-layers" {
  repeater {
    co: collapsible text=(@co->input | get_param name="title");
    //layers_gui2 layer={screen_layer} pattern="** screen_layer" text="Надписи" plashka;
  };
};