// здесь третья система плагинов

load files="lib3dv3 csv params io gui render-params df scene-explorer-3d 12chairs.cl";

///////////////////////////////////////
/////////////////////////////////////// главные параметры
///////////////////////////////////////

mainparams: {
  //f1:  param_file value="phase_yScaled2.csv";
  f1:  param_file value="http://viewlang.ru/assets/other/landing/2021-10-phase.txt";

  y_scale_coef: param_slider min=1 max=200 value=1;

  time: param_combo values=(@_dat | df_get column="T") 
     index=@time_slider->value;
  // todo исследовать time: param_combo values=(@dat | df_get column="T");
  time_slider: param_slider min=0 max=(@time->values | arr_length | compute_output code=`return env.params.input-1`) step=1 
     value=@time->index;

  step_N: param_slider value=10 min=1 max=100;

  lines_loaded: param_label value=(@dat0 | get name="length");
};

///////////////////////////////////////
/////////////////////////////////////// данные
///////////////////////////////////////

dat0: load-file file=@mainparams->f1 
       | parse_csv separator="\s+";

_dat: @dat0 | df_set X="->x[м]" Y="->y[м]" Z="->z[м]" T="->t[c]"
              RX="->theta[град]" RY="->psi[град]" RZ="->gamma[град]"
            | df_div column="RX" coef=57.7
            | df_div column="RY" coef=57.7
            | df_div column="RZ" coef=57.7;


dat: @_dat | df_div column="Y" coef=@mainparams->y_scale_coef;       

dat_prorej: @dat | df_skip_every count=@mainparams->step_N;

dat_cur_time: @dat | df_slice start=@time->index count=1;
dat_cur_time_orig: @dat0 | df_slice start=@time->index count=1;


///////////////////////////////////////
/////////////////////////////////////// интерфейс пользователя
///////////////////////////////////////

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

    layers_gui layer={data_visual_layer} pattern="data_visual_layer" title="Визуализация данных";

    layers_gui layer={static_visual_layer} pattern="static_visual_layer" title="Дополнительные образы";

    layers_gui layer={screen_layer} pattern="screen_layer" title="Надписи";

    // то есть по большому счету эта штука превратилась в добавлялку
    // а все самое интересное происходит в addon_layer... ну и хорошо же.
    // layers_gui target=@r1 layer={ adhoc mesh positions=[0,10,20, 30,15,15, 0,0,0 ]; } pattern="** adhoc" title="Проверка";

  };

  extra_screen_things: column {};

  }; // row

  v1: view3d style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2";

  //v2: view3d style="position: absolute; right: 20px; bottom: 20px; width:500px; height: 200px; z-index: 5;";
  
};

///////////////////////////////////////
/////////////////////////////////////// визуальные слои
///////////////////////////////////////

register_feature name="df_column_ref" {
  //param_ref crit_fn="(obj) => obj.colnames || []";
  crit_fn="(obj) => obj.colnames || []";
};

register_feature name="df_ref" {
  crit_fn="(obj) => {
    return obj.getParamsNames().filter( (v) => obj.getParam(v)?.isDataFrame );
  }";
};

register_feature name="data_visual_layer" {
  dv: {
    pc: param_combo name="input_data" 
          titles=["Траектория","Прореженная траектория","Текущее положение"]
          values=["@dat->output","@dat_prorej->output","@dat_cur_time->output"]
     ;

    //param_ref df_ref name="input";
    link to="@al->input" from=@pc->value;
    
    al: addon_layer 
        list=@t1
        include_gui_inline
        mapping={
            channel="render3d-items" target=@r1;
            channel="screen-items"   target=@extra_screen_things;
        };

      };
};

register_feature name="static_visual_layer" {
  addon_layer 
    list=@t2
    mapping={
        channel="render3d-items" target=@r1;
        channel="screen-items"   target=@extra_screen_things;
    };
};

register_feature name="screen_layer" {
  addon_layer 
    list=@t3
    mapping={
        channel="render3d-items" target=@r1;
        channel="screen-items"   target=@extra_screen_things;
    };
};

addons_place: {
    data_visual_layer selected_show="axes";
    static_visual_layer selected_show="ptstr";
}; //  todo fix addons_place:; or even addons_place: {};

debugger_screen_r;

load files="visual-layers.cl";
t1:  data_visual_layers output=@.;
t2:  static_visual_layers output=@.;
t3:  screen_layers output=@.;

