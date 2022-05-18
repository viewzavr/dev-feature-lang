load "gui5.cl";

// вот идея - хорошо бы все-таки это под локальным именем бы экспортировалось
// а на уровне load можно было бы указать таки X и затем говорить X.view например фича
// ну или объект.. но на с.д. надо и фичу и объект, кстати..

view1: feature text="Общий вид" { root: dom_group {

  ////// основные параметры

      mainparams:
      {
        time_slider: param_slider 
           min=0 
           max=(@time->values | arr_length | compute_output code=`return env.params.input-1`) 
           step=1 
           value=@time->index;

        //f1:  param_file value="phase_yScaled2.csv";
        f1:  param_file value="https://viewlang.ru/assets/other/landing/2021-10-phase.txt";

        y_scale_coef: param_slider min=1 max=200 value=50;

        time: param_combo values=(@_dat | df_get column="T")
           index=@time_slider->value;
        // todo исследовать time: param_combo values=(@dat | df_get column="T");
        

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

  dat_cur_time: @dat       | df_slice start=@time->index count=1;

  dat_cur_time_orig: @dat0 | df_slice start=@time->index count=1; 
   // оригинальная curr time до изменения имен колонок и прочих преобьразований
   // требуется для вывода на экран исходных данных

   dat_cur_time_zero: @dat | df_slice start=@time->index count=1 | df_set X=0 Y=0 Z=0;


   ////////////////////////////////////
   ////// сцена
   ////////////////////////////////////

        r1: render3d 
              bgcolor=[0.1,0.2,0.3]
              target=@v1
        {
            camera3d pos=[0,0,100] center=[0,0,0];
            orbit_control;

            show_vis;

            show_static_vis vis_type="pole";
            show_static_vis vis_type="axes";

            //@dat | ptstr;
            //@dat | linestr;

/*
            axes;
            pole;
            kvadrat;
            stolbik;
*/            

        };

   ////////////////////////////////////
   ////// интерфейс
   ////////////////////////////////////

          row style="z-index: 3; color: white;" 
              class="vz-mouse-transparent-layout" align-items="flex-start" // эти 2 строчки решают проблему мышки
          {
            collapsible text="Основные параметры" style="min-width:250px;" padding="10px"
            {

              //paint_kskv_gui input=@sol;
              render-params  input=@mainparams;
            };

            extra_screen_things: column {};

          }; // row

          //render_layers root=@sol style="position:absolute; right: 10px; top: 10px;";

          column style="position:absolute; right: 20px; top: 10px;" {


            collapsible text="Визуальные объекты" 
            style="min-width:250px" 
            style_h = "max-height:90vh;"
            body_features={ set_params style_h="max-height: inherit;"}
            {
             s: switch_selector_column items=["Объекты данных","Статичные","Текст"] style="width:200px;";

             button "Добавить" margin="1em" {
                //creator target=@r1 input={show_vis}
                creator target=@r1 input=(output={show_vis;show_static_vis;show_text} | console_log "UUU" | get @s->index)
                  {{ onevent name="created" code=`
                     args[0].manuallyInserted=true; 
                     
                     console.log("created",args[0])` 
                  }};
             };

             find-objects-bf (list "guiblock datavis" "guiblock staticvis" "guiblock screenvis" | get @s->index) 
                             recursive=false
             | repeater {
                     co: column plashka style_r="position:relative;" {
                       //text (@co->input);
                       column {
                         deploy_many input=(@co->input | get_param name="gui");
                       };
                       //render-params input=@co->input;

/*
                       repeater input=(@co->input | get_param "extra-params") {{ console_log_params "EEEE"}}
                       {
                            render-params;
                       };
*/

                       button "x" style="position:absolute; top:0px; right:0px;" 
                       {
                         lambda @co->input code=`(obj) => obj.remove();`;
                       };  
                     };
                  };

                show_one 
                  index=@s->index 
                  style_h="max-height: inherit;"
                {
                  
                  render_layers root=@sol->l1;
                  render_layers root=@sol->l2;
                  render_layers root=@sol->l3;


                };
            };  
          };

          v1: view3d style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2" extra=@extra_screen_things;

    }
};

view2: feature text="Ракета" {
    dom_group {
        v1: view3d style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2";
    };
};

///////////////////////////
///////////////////////////
/////////////////////////// наполнение

linestr: feature {
        main: linestrips guiblock datavis
          gui={ render-params input=@main ; }
        {
        };
};

ptstr: feature {
        main: points gui={ render-params input=@main ; } guiblock datavis;
};
    
    // вход input это dataframe
models: feature {
      root: node3d gui={ render-params input=@root; } guiblock datavis
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

show_vis: feature {
  root: guiblock datavis node3d gui={
     render-params input=@root;
     //render-params input=@nf->output list-filter;
     render-params-list object=@nf->output list=(@nf->output | get-params-names | arr_filter code="(val,index) => val != 'visible'");
  } {
      input_data: param_combo values=["@dat->output","@dat_prorej->output","@dat_cur_time->output"]
         titles=["Траектория","Прореженная","Текущее время"]
         ;
      vis_type: param_combo values=["ptstr","linestr","models"] titles=["Точки","Линия","Модель"];

      //data: output=(read @root->input_data) ну я пока read такой не сделал )))

      //data: output=(link from=@input_data->value to="@.->output");
      data: q=1;
      link to="@data->output" from=@input_data->value tied_to_parent=true;

      nf: one-of index=@vis_type->index {
        points input=@data->output;
        linestrips input=@data->output;
        models input=@data->output;
      }; 
  };
};

/////////////////////////// визуальные статические образы

show_static_vis: feature {
  root: guiblock staticvis node3d gui={
     render-params input=@root;
     //render-params input=@nf->output list-filter;
     render-params-list object=@nf->output list=(@nf->output | get-params-names | arr_filter code="(val,index) => val != 'visible'");
  } {

      vis_type: param_combo values=["axes","pole","kvadrat","stolbik"] titles=["Оси","Земля","Квадрат","Масштабный столбик"];

      nf: one-of index=@vis_type->index {
            axes;
            pole;
            kvadrat;
            stolbik;
      };
  };
};

////