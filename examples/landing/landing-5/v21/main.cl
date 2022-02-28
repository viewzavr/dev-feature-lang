load files="lib3dv3 csv params io gui render-params df scene-explorer-3d 12chairs.cl landing.cl gui4.cl";


register_feature name="visual_tasks_and_windows" {
  root: 
    gui={
      render-layers input=(get_children_arr input=@layers) for=@root;
    }
   {
    // вопрос а зачем это в форме такой? может быть достаточно в форме инфы для render-layers сразу?
    layers: {
      layer_v1 title="Задачи" 
        find="** visual_task_thing" 
        new={visual_task_thing};
      layer_v1 title="Окна" 
        find="** windows" 
        new={data_visual_layer screen=@root->screen};
    };

   };
};

register_feature name="visual_task_thing" {
  dv: create_by_user_type 
    list=(find-objects pattern="** visual_task")
    mapping={
        channel="body" target=@tasks_place;
    };
};

// это корень программы
programma: visual_tasks_and_windows;
// сюда кладем задачи
tasks_place: alfa=5 {};

///////////////////////////////////////
/////////////////////////////////////// задача
///////////////////////////////////////

//sol: landing-sol scene=@r1 screen=@extra_screen_things;
//sol2: landing-sol scene=@r2 screen=@extra_screen_things2;

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

      paint_kskv_gui input=@programma;
    };
    

    extra_screen_things: column {
    };

  }; // row

  v1: view3d style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2";

  dom style="position: absolute; right: 20px; bottom: 20px; width:500px; height: 200px; z-index: 5; border: 1px solid grey;"
  {
    v2: view3d style="z-index: -2; width:100%; height: 100%;";
    extra_screen_things2: column style="z-index: 2; position:absolute; top: 5px; left: 10px;" {};
  }
    
  
};



debugger_screen_r;