load files="lib3dv3 csv params io gui render-params df scene-explorer-3d 12chairs.cl gui2.cl landing.cl";

///////////////////////////////////////
/////////////////////////////////////// задача
///////////////////////////////////////

sol: landing-sol scene=@r1 screen=@extra_screen_things;
sol2: landing-sol scene=@r2 screen=@v2;

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

      solution_gui sol=@sol;
      /*
      collapsible text="Приземление" {
        //solution_gui sol=@sol;
        //text text="aaa";
      };
      */

    };
    

    extra_screen_things: column {
    };

  }; // row

  v1: view3d style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2";

  v2: view3d style="position: absolute; right: 20px; bottom: 20px; width:500px; height: 200px; z-index: 5; border: 1px solid grey;";
  
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

// for - для кого рисуем. в этом "кто" будут сканироваться объекты для слоев и туда же будут создаваться новые
// input - список слоев
register_feature name="render-layers" {
  r: repeater {
    //button text="333";
    //co: collapsible text=(@co->input | get_param name="title") {
      co: layers_gui2 
            text=(@co->input | get_param name="title")
            layer=(@co->input | get_param name="new") 
            pattern=(@co->input | get_param name="find") 
            pattern_root=@r->for
            target=@r->for
            plashka;
  };
};

register_feature name="solution_gui" {
  rt: dom_group 
      layers=(@rt->sol | get_param name="layers") 
      params_obj=(@rt->sol | get_param name="params_obj") 
  {
    collapsible text="Основные параметры" {
       render-guis-nested2 input=@rt->params_obj;
    };
    render-layers input=@rt->layers for=@rt->sol;
  };
};

debugger_screen_r;