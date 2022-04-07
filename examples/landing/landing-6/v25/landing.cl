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
  title="Движение ракеты"
  body={
    root: 
      gui={
        render-params  input=@taskparams;
        paint_kskv_gui input=@ls;
      }
    {
    taskparams:
    {
        target_for_3d: param_objref 
          value=(find-objects-bf features="render3d" root=@/ | get index=0)
          crit_fn=`(obj) => obj.is_feature_applied('render3d')`;
          //value=
         //{{ auto_select_first_variant; }} ; // тут можно и node3d так-то произвольный поставить 
    };
      //landing-sol scene=@target_for_3d->value ; //{{ console_log_params text="landing-sol" }};
      // это не работает т.к. оно доходит до уровня lexicalParent.. и оттуда уже на поиски видимо не возвращается..
      // но тогда и @taskparams->target_for_3d не сработает..
      ls: landing-sol scene=@taskparams->target_for_3d screen=(@.->scene | get_param name="target" | get_param name="extra");
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
      render-layers input=(get_children_arr input=@layers) for=@root;
    }
    l1=@l1 l2=@l2 l3=@l3
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
      l1: layer_v1 title="Визуализация" 
        find="** data_visual_layer" 
        for=@root
        new={data_visual_layer scene=@root->scene screen=@root->screen};

      l2: layer_v1 title="Статичные образы"
        find="** static_visual_layer" 
        for=@root
        new={static_visual_layer scene=@root->scene screen=@root->screen};

      l3: layer_v1 title="Надписи" 
        find="** screen_layer" 
        for=@root
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

  data_visual_layer   selected_show="ptstr" scene=@root->scene screen=@root->screen;
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
      paint_kskv_gui input=@al;
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

///////////////////////////
///////////////////////////
/////////////////////////// наполнение

data_visual code="linestr" title="Линия" render3d-items={
        main: linestrips 
          gui={ render-params input=@main; }
        {
        };
};

data_visual code="ptstr" title="Точки" render3d-items={
        main: points gui={ render-params input=@main; };
};
    
    // вход input это dataframe
data_visual code="models" title="Модель" render3d-items={
      root: node3d gui={ render-params input=@root; } {
        param_slider name="scale" min=1 max=10 value=1;
        param_color  name="hilight_color" value=[0,0,0];
        param_label  name="count" value=(@rep->input | get name="length");

        @root->input | df_slice count=100 | df_to_rows | rep: repeater {
          gltf:
            render_gltf
            src="https://viewlang.ru/assets/models/Lake_IV_Heavy.glb" 
            positions=(@gltf->input | df_combine columns=["X","Y","Z"])
            rotations=(@gltf->input | df_combine columns=["RX","RY","RZ"])
            
            {{ scale3d coef=@root->scale; }}
            color=@root->hilight_color;
            
        };
      };
};

    
static_visual code="axes" title="Оси координат" render3d-items={ 
       main: axes_box size=100; 
};

static_visual code="pole" title="Земля 4кв км" render3d-items={
        main: mesh gui={ render-params input=@main; } 
          positions=[
           -1000,-0.5,-1000,  1000,-0.5,-1000, -1000,-0.5,1000,
           -1000,-0.5,1000,   1000,-0.5,-1000,  1000,-0.5,1000
          ]
          color=[0,0.25,0]
        ;
};
    
static_visual code="kvadrat" title="Квадрат места" render3d-items={
        main: mesh gui={ render-params input=@main; }  
          positions=[
           -30,0,-30, 30,0,-30,  -30,0,30,  
           -30,0,30,  30,0,-30,  30,0,30
          ]
          color=[0.4, 0.4, 0.4]
        ; // todo: polygon offset modifier
    };

static_visual code="stolbik" title="Столбик места" render3d-items={
      main: 
        lines gui={ render-params input=@main; }  
          positions=(compute_output h=@.->h code=`
            return [-30,0,-30, -30, env.params.h,-30 ]
          `)
          color=[1,1,1] 
          {
            param_slider name="h" min=5 max=100 value=5;
          }
        ;
    };


// todo: автоматом include_gui_inline и подавать @dat


screen_visual code="curtime" title="Текущее время" screen-items={
      
        dom tag="h2" style="color: white"
        innerText=(compute_output t=@mainparams->time code="
           return 'T='+(env.params.t || 0).toFixed(3);
        ");
    };

screen_visual code="allvars" title="Все переменные" screen-items={
      
        dom style="color: white; display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
                   min-width: 400px; font-size: larger"
        innerHTML=(compute_output df=@dat_cur_time_orig->output code="
           let str='';
           let df = env.params.df || {};
           
           for (let n of (df.colnames || [])) {
             let val = df[n][0];
             if (isFinite(val)) {
                 val = val.toFixed(3);
                 str += `<span>${n}=${val}</span>`;
             }    
           }
           return str;
        ");
    };

// это все очень крышесносно. необходимо с этим разобраться! вот с телом этой штуки.
// может быть вынести selected, или еще что.. мне теперь вовсе непонятно, что же это все такое..
// потратил ать времени, чтобы дошло.. упаковочка конечно...
screen_visual code="selectedvars" title="Переменные по выбору" screen-items={
      
        dom 
        style="color: white; display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
                   min-width: 300px; font-size: larger"
        innerHTML=@qq->output 
        gui={ render-params input=@selected; } 
        {

          selected:  gui_title="Выбрать" {{ 
             onevent name="param_changed" cmd="@qq->recompute";
             onevent name="gui-added" cmd="@qq->recompute";
             }}
          {

              qq: compute_output df=@dat_cur_time_orig->output selected=@selected code="
               let str='';
               let df = env.params.df || {};
               let selected = env.params.selected;
               if (!selected) return '';
               
               for (let n of (df.colnames || [])) {
                 let f = selected.getParam( n );
                 if (!f) continue;
                 let val = df[n][0];
                 if (isFinite(val)) {
                     val = val.toFixed(3);
                     str += `<span>${n}=${val}</span>`;
                 }    
               }
               return str;
               ";

              @dat0->output | get name="colnames" | repeater 
              {
                param_checkbox name=@.->input value=true;
              };

          };
        }
    };


screen_visual code="curtime_sl" title="Управление временем на экране" screen-items={

        slider value=@time_slider->value max=@time_slider->max {
          link to="@time_slider->value" from="..->value";
        };
};
