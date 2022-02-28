/* получается данный "плагин задачи" внедряет в систему фичу, которая несет
   - перечень параметров для отрисовки
   - перечень слоев, в каждый из которых можно добавить 1 тип объекта
     (причем это хитрый тип - он предоставляет пользователю возможность выбора доп-типа)

   насчет слоев. нам надо передавать им аргументы, переданные в решение
   (это трехмерная сцена и экранная область)
   нам надо 1) уметь их найти, 2) понимать что вызывать чтобы создавать новое.
   вариант - сделать pattern и body. ну либо type и modifiers..

   при этом входом эта штука требует
    - экран, куда можно вписаться
    - 3д сцена, куды
*/

visual_task
  code="landing-sol" 
  title="Задача приземления" 
  body={
    root: 
      gui={
        render-params  input=@taskparams;
        paint_kskv_gui input=@ls;
        text text="lalala";

      }
    {
    taskparams:
    {
        target_for_3d: param_objref crit_fn=`(obj) => obj.is_feature_applied('render3d')`; // тут можно и node3d так-то произвольный поставить 
    };
      //landing-sol scene=@target_for_3d->value ; //{{ console_log_params text="landing-sol" }};
      // это не работает т.к. оно доходит до уровня lexicalParent.. и оттуда уже на поиски видимо не возвращается..
      // но тогда и @taskparams->target_for_3d не сработает..
      ls: landing-sol scene=@taskparams->target_for_3d {{ console_log_params text="landing-sol" }};
    };
  }
;

///////////////////////////////////////
/////////////////////////////////////// главные параметры
///////////////////////////////////////

// scene, screen
register_feature name="landing-sol" {

  root: 
    gui={
      render-params input=@mainparams;
      render-layers input=@layers;
      text text="lalala2";
    }
  {

  mainparams:
  {
    //f1:  param_file value="phase_yScaled2.csv";
    f1:  param_file value="https://viewlang.ru/assets/other/landing/2021-10-phase.txt";

    y_scale_coef: param_slider min=1 max=200 value=1;

    time: param_combo values=(@_dat | df_get column="T") 
       index=@time_slider->value;
    // todo исследовать time: param_combo values=(@dat | df_get column="T");
    time_slider: param_slider 
       min=0 
       max=(@time->values | arr_length | compute_output code=`return env.params.input-1`) 
       step=1 
       value=@time->index;

    step_N: param_slider value=10 min=1 max=100;

    lines_loaded: param_label value=(@dat0 | get name="length");
  };

  layers: {
      layer_v1 title="Визуализация" 
        find="** data_visual_layer" 
        new={data_visual_layer scene=@root->scene screen=@root->screen};

      layer_v1 title="Статичные образы"
        find="** static_visual_layer" 
        new={static_visual_layer scene=@root->scene screen=@root->screen};

      layer_v1 title="Надписи" 
        find="** screen_layer" 
        new={screen_layer scene=@root->scene screen=@root->screen};
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


  /////////////////////////////////////
  ///////////////////////////////////// начальная визуализация
  /////////////////////////////////////

  data_visual_layer   selected_show="ptstr" scene=@root->scene screen=@root->screen  {{ console_log_params text="inner-layer" }};
  static_visual_layer selected_show="axes" scene=@root->scene screen=@root->screen;
  static_visual_layer selected_show="pole" scene=@root->scene screen=@root->screen;

  };

};

///////////////////////////////////////
/////////////////////////////////////// визуальные слои
///////////////////////////////////////


register_feature name="data_visual_layer" {
  dv: active=true gui_title=(@pc->titles | get name=@pc->index) 
    //gui_title=@al->gui_title //(@pc->titles | get name=@input_data->index) 
    gui={
      render-params input=@dv;
      render-guis-inline input=@al;
    }
    {
    pc: param_combo name="input_data" 
          titles=["Траектория","Прореженная траектория","Текущее положение"]
          values=["@dat->output","@dat_prorej->output","@dat_cur_time->output"]
     ;

    //param_ref df_ref name="input";
    link to="@al->input" from=@pc->value;
    
    al: create_by_user_type 
        list=(find-objects pattern="** data_visual")
        active=@dv->active
        include_gui_inline
        mapping={
            channel="render3d-items" target=@dv->scene;
            channel="screen-items"   target=@dv->screen;
        };

      };
};

register_feature name="static_visual_layer" {
  dv: create_by_user_type 
    list=(find-objects pattern="** static_visual")
    mapping={
        channel="render3d-items" target=@dv->scene;
        channel="screen-items"   target=@dv->screen;
    };
};

register_feature name="screen_layer" {
  dv: create_by_user_type 
    list=(find-objects pattern="** screen_visual")
    mapping={
        channel="render3d-items" target=@dv->scene;
        channel="screen-items"   target=@dv->screen;
    };
};

load files="visual-layers.cl";