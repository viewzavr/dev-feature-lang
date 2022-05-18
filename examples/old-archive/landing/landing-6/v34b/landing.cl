load "gui5.cl lib.cl ban-deleted3.cl set-params";

feature "guiblock" {}; feature "include-gui" {};

// вот идея - хорошо бы все-таки это под локальным именем бы экспортировалось
// а на уровне load можно было бы указать таки X и затем говорить X.view например фича
// ну или объект.. но на с.д. надо и фичу и объект, кстати..

// вход: loaded_data, time_index, time_params
view1: feature text="Общий вид" { 
  vroot: dom_group {

  ////// основные параметры

  mainparams: 
  {

    see_lines: param_label value=(@_dat | get name="length");

    // todo исследовать time: param_combo values=(@dat | df_get column="T");

    y_scale_coef: param_slider min=1 max=200 value=50;

    step_N: param_slider value=10 min=1 max=100;
  };

  ///////////////////////////////////////
  /////////////////////////////////////// данные
  ///////////////////////////////////////

  _dat: df_set input=@vroot->loaded_data;
  dat0: df_set input=@vroot->loaded_data0;
  //_dat: output=(@vroot->loaded_data | get_param name="output");

  dat: @_dat | df_div column="Y" coef=@mainparams->y_scale_coef;

  dat_prorej: @dat | df_skip_every count=@mainparams->step_N;

  dat_cur_time: @dat       | df_slice start=@vroot->time_index count=1;

  dat_cur_time_orig: @dat0 | df_slice start=@vroot->time_index count=1; 
  // оригинальная curr time до изменения имен колонок и прочих преобьразований
  // требуется для вывода на экран исходных данных

   // dat_cur_time_zero: @dat | df_slice start=@vroot->time_index count=1 | df_set X=0 Y=0 Z=0;

  datavis_data_info: 
      titles=["","Траектория","Прореженная","Текущее время"] 
      values=["","@dat->output","@dat_prorej->output","@dat_cur_time->output"];

   ////////////////////////////////////
   ////// сцена
   ////////////////////////////////////

    r1: render3d 
          bgcolor=[0.1,0.2,0.3]
          target=@v1 {{ skip_deleted_children }}
    {
        camera3d pos=[0,0,100] center=[0,0,0];
        orbit_control;

        linestr 
             input_link="@dat->output";

        ptstr radius=2 
             input_link="@dat->output";

        models 
             input_link="@dat_cur_time->output";

        axes;
        pole;
        kvadrat;
        stolbik;

    };

   ////////////////////////////////////
   ////// интерфейс
   ////////////////////////////////////

   v1: view3d style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2" extra=@extra_screen_things;

   render_interface
       left={
          column plashka {
            text "";
            render-params  input=@vroot->time_params;
          };

          collapsible text="Параметры отображения" style="min-width:250px;" padding="10px"
          {
            render-params  input=@mainparams plashka;
          };

       }
       middle={
         extra_screen_things: column;
       }
       right={
        render_layers title="Визуальные объекты" 
           root=@vroot
           items=[ { "title":"Объекты данных", 
                     "find":"datavis",
                     "add":"linestr"
                   },

                   {"title":"Статичные","find":"staticvis","add":"axes"},
                   {"title":"Текст","find":"screenvis","add":"select-t"}
                 ]
           before_each={
              cb: combobox titles=@datavis_data_info->titles 
                       values=@datavis_data_info->values
                       value=(@cb->obj_input | get_param name="input_link")
                  ;
           }
           ;
       };

    }; //vroot
};

view2: feature text="Ракета в центре координат" { 
  vroot: dom_group {

  ////// основные параметры
  
  ///////////////////////////////////////
  /////////////////////////////////////// данные
  ///////////////////////////////////////

  _dat: df_set input=@vroot->loaded_data;
  dat0: df_set input=@vroot->loaded_data0;

  dat_cur_time_zero: @_dat | df_slice start=@vroot->time_index count=1 | df_set X=0 Y=0 Z=0;
  dat_cur_time_orig: @dat0 | df_slice start=@vroot->time_index count=1;

  //data_variants: names=["Основное положение"] titles=""
  datavis_data_info: 
      titles=["","Текущее положение"] 
      values=["","@dat_cur_time_zero->output"];

   ////////////////////////////////////
   ////// сцена
   ////////////////////////////////////

    r1: render3d 
          bgcolor=[0.1,0.2,0.3]
          target=@v1 {{ skip_deleted_children }}
    {
        camera3d pos=[0,100,100] center=[0,0,0];
        orbit_control;

        //models input_data="@dat_cur_time_zero->output";
        models input_link="@dat_cur_time_zero->output";

        axes;
        pole;

    };

   ////////////////////////////////////
   ////// интерфейс
   ////////////////////////////////////

   v1: view3d style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2" extra=@extra_screen_things;

   render_interface
       left={
          column plashka {
            text "";
            render-params  input=@vroot->time_params;
          };
       }
       middle={
         extra_screen_things: column;
       }
       right={
        render_layers title="Визуальные объекты" 
           root=@vroot
           items=[ {"title":"Объекты данных", "find":"datavis","add":"linestr"},
                   {"title":"Статичные","find":"staticvis","add":"axes"},
                   {"title":"Текст","find":"screenvis","add":"select-t"}
                 ];
       };

    }; //vroot
};

///////////////////////////
///////////////////////////
/////////////////////////// наполнение

linestr: feature {
  main: linestrips datavis gui={ render-params input=@main; };
};

ptstr: feature {
  main: points datavis gui={ render-params input=@main; };
};
    
    // вход input это dataframe
models: feature {
    root: node3d datavis gui={ render-params input=@root; }
          {
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

feature "axes"  {
       main: axes_box size=100 guiblock staticvis; 
};

feature "pole" {
        main: mesh gui={ render-params input=@main; } guiblock staticvis
          positions=[
           -1000,-0.5,-1000,  1000,-0.5,-1000, -1000,-0.5,1000,
           -1000,-0.5,1000,   1000,-0.5,-1000,  1000,-0.5,1000
          ]
          color=[0,0.25,0]
        ;
};

feature "kvadrat" {
        main: mesh gui={ render-params input=@main; } guiblock staticvis
          positions=[
           -30,0,-30, 30,0,-30,  -30,0,30,  
           -30,0,30,  30,0,-30,  30,0,30
          ]
          color=[0.4, 0.4, 0.4]
        ; // todo: polygon offset modifier
    };

feature "stolbik" {
      main: 
        lines gui={ render-params input=@main; } guiblock  staticvis
          positions=(compute_output h=@.->h code=`
            return [-30,0,-30, -30, env.params.h,-30 ]
          `)
          color=[1,1,1] 
          {
            param_slider name="h" min=5 max=100 value=5;
          };
    };

/////////////////////////// визуальные 3д образы

dfffff: feature {
  x-modify {
     //x-set-params gui={ render-params input=@. {{ console_log_params text=">>>>>>>>>>>>>>" }}; }
     //x-patch code=`(env) => env.feature('datavis');`;
  };
};

select_input_view1: feature {
  rt: {
      input_data:
        param_combo values=["","@dat->output","@dat_prorej->output","@dat_cur_time->output"]
           titles=["","Траектория","Прореженная","Текущее время"]
           ;
      link to="@rt->input" from=@input_data->value tied_to_parent=true soft_mode=true;

      //vis_type: param_combo values=["ptstr","linestr","models"] titles=["Точки","Линия","Модель"];  
  };
};


select_input: feature {
  root: {
      input_data:
        param_combo values=@root->values titles=@root->titles;
      link to="@rt->input" from=@input_data->value tied_to_parent=true soft_mode=true;
  };
};

select_input_view111: feature {
  select_input 
    values=["","@dat->output","@dat_prorej->output","@dat_cur_time->output"]
    titles=["","Траектория","Прореженная","Текущее время"];
};

datavis: feature {
  rt: 
      sibling_types=["linestr","ptstr","models"] 
      sibling_titles=["Линии","Точки","Модели"] 
      {
        input_link:
          param_combo values=@datavis_data_info->values titles=@datavis_data_info->titles;        
        link to="@rt->input" from=@rt->input_link tied_to_parent=true soft_mode=true;
      }
};

staticvis: feature {
  rt: sibling_types=["axes","pole","kvadrat","stolbik"] 
      sibling_titles=["Оси","Земля","Квадрат","Масштабный столбик"];
};

