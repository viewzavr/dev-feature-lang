// здесь третья система плагинов

load files="lib3dv3 csv params io gui render-params df scene-explorer-3d 12chairs.cl";

load files="v-data-config.cl" ;

r1: render3d 
      bgcolor=[0.1,0.2,0.3]
      target=@v1
{
    camera3d pos=[0,0,100] center=[0,0,0];
    orbit_control;
};

mainscreen: screen auto-activate {
  row style="z-index: 3; position:absolute;  color: white;" 
      class="vz-mouse-transparent-layout" align-items="flex-start" // эти 2 строчки решают проблему мышки
  { 

  column style="background-color:rgba(200,200,200,0.2); overflow-y: scroll; max-height: 90vh;" 
         padding="0.3em" margin="0.7em"
    {
    dom tag="h3" innerText="Параметры" style="margin-bottom: 0.3em;"
    {{ dom_event name="click" cmd="@rp->trigger_visible" ;}};

    rp: column gap="0.5em" padding="0em" {
      render-params object_path="@mainparams";
    };

    layers_gui layer={visual_layer} pattern="** visual_layer" title="Визуальные слои";

    layers_gui layer={screen_layer} pattern="** screen_layer" title="Надписи";

    // то есть по большому счету эта штука превратилась в добавлялку
    // а все самое интересное происходит в addon_layer... ну и хорошо же.
    layers_gui target=@r1 layer={ adhoc mesh positions=[0,10,20, 30,15,15, 0,0,0 ]; } pattern="** adhoc" title="Проверка";

  };

  extra_screen_things: column {};

  }; // row

  v1: view3d style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2";

  //v2: view3d style="position: absolute; right: 20px; bottom: 20px; width:500px; height: 200px; z-index: 5;";
  
};

register_feature name="visual_layer" {
  addon_layer 
    list=@t1
    mapping={
        channel="render3d-items" target=@r1;
        channel="screen-items"   target=@extra_screen_things;
    };
};

register_feature name="screen_layer" {
  addon_layer 
    list=@t1s
    mapping={
        channel="render3d-items" target=@r1;
        channel="screen-items"   target=@extra_screen_things;
    };
};

addons_place: {
    visual_layer selected_show="axes";
    visual_layer selected_show="ptstr";
}; //  todo fix addons_place:; or even addons_place: {};

debugger_screen_r;

load files="visual-layers.cl";
t1:  visual_layers output=@.;
t1s: screen_layers output=@.;