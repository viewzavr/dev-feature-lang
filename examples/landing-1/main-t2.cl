// здесь первая версия системы плагинов

load files="lib3dv3 csv params io gui render-params df scene-explorer-3d";

mainparams: {
  f1:  param_file value="http://viewlang.ru/assets/other/landing/2021-10-phase.txt";

  y_scale_coef: param_slider min=1 max=100 value=10;

  time: param_combo values=(@_dat | df_get column="T");
};

dat0: load-file file=@mainparams->f1 
       | parse_csv separator="\s+";

_dat: @dat0 | df_set X="->x[м]" Y="->y[м]" Z="->z[м]" T="->t[c]"
              RX="->theta[град]" RY="->psi[град]" RZ="->gamma[град]";

dat: @_dat | df_div column="Y" coef=@mainparams->y_scale_coef;
 
//traj_projej: @dat | skip

r1: render3d 
      bgcolor=[0.1,0.2,0.3]
      target=@v1
  {
    camera3d pos=[0,0,100] center=[0,0,0];
    orbit_control;

    axes_box size=100;

    @dat | points;

    //@dat | df_filter code=`(line) => line.TEXT?.length > 0` | text3d myvisual size=0.1 visible=@cb1->value; // color=[0,1,0];
  };

/*
  render3d bgcolor=[1,0,0] 
    camera=@r1->camera
    target=@v2
    // input=@r1->scene // scene= почему-то не робит
  {
    //camera3d pos=[0,100,0] center=[0,0,0];
    orbit_control;

    @dat | points radius=0.15 myvisual;
  };
*/  


mainscreen: screen auto-activate {
  column style="z-index: 3; position:absolute; background-color:rgba(200,200,200,0.2);" 
    padding="0.3em" margin="0.7em"
    {
    dom tag="h3" innerText="Параметры" style="margin-bottom: 0.3em;"
    {{ dom_event name="click" cmd="@rp->trigger_visible" ;}};

    rp: column gap="0.5em" padding="0em" {
      render-params object_path="@mainparams";
    };

    column gap="0.5em" padding="0em" {
      dom tag="h4" innerText="Визуальные объекты";
      
      find-objects pattern="** node3d" 
      | repeater {
        column {
          button text=@btntitle->output cmd="@pcol->trigger_visible";
          
          pcol: column visible=false {
            render-params object=@../..->modelData;
            btntitle: compute_output object=@../..->modelData code=`
              return env.params.object?.ns.name;
            `;
          }
          
        };
      };

      //cb1: checkbox text="Show text";
    };

      button text="Добавить слой" {
        creator target=@visualhub input={
          visual_layer;
        } {{ onevent name="created" code=`args[0].manuallyInserted=true;` }};
      };

      dom tag="h3" innerText="Визуальные слои" ;

      column gap="0.5em" {
        find-objects pattern="** visual_layer" | render-guis-nested;
      };

  };

  v1: view3d style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2";

  //v2: view3d style="position: absolute; right: 20px; bottom: 20px; width:500px; height: 200px; z-index: 5;";
  
  
};

visualhub: a=5; //  todo fix visualhub:;

debugger_screen_r;

register_feature name="visual_layer" {
  vlayer: {

    selected_show: param_combo 
       values=(@t1->list | arr_map code=`(c) => c.ns.name`)
       titles=(@t1->list | arr_map code=`(c) => c.params.title`);

    create_fprg_instance input=( @t1 | get child=@selected_show->value );
  };
};

// fprg = feature-program. здесь мы создаем экземпляр выбранной штуки
register_feature name="create_fprg_instance" {
  fpinstance: {
    r3d_f: deploy_many_to target=@r1         input=(@fpinstance->input | get_param name="render3d-items");
    ms_f:  deploy_many_to target=@mainscreen input=(@fpinstance->input | get_param name="mainscreen-items");

    // это фичи.. а у нас пока про детей речь
    //deploy_features input=@explr  features=(@rt->input | get_param name="explorer-features");
    //deploy_features input=@sgraph features=(@rt->input | get_param name="generator-features");
    };
};

t1: output=@. list=(@. | get_children_arr | arr_filter code=`(c) => c.params.title`) 
{
   linestr: linestr;
   ptstr: ptstr;
};

register_feature name="program_feature" {
  render3d-items={} mainscreen-items={};
};

register_feature name="linestr" {
  program_feature title="Показать линией"
    render3d-items={
      @dat | linestrips include_gui;
    }
  ;
};

register_feature name="ptstr" {
  program_feature title="Показать точками"
    render3d-items={
      @dat | points include_gui;
    }
  ;
};


register_feature name="render-guis-nested" {
  rep: repeater opened=true {
    col: column {
          button 
            text=(compute_output object=@col->input code=`return env.params.object?.params.gui_title || env.params.object?.ns.name`) 
            cmd="@pcol->trigger_visible";

          pcol: column visible=true style="padding-left: 1em;" {
            render-params object=@col->input;

            find-objects pattern_root=@col->input pattern="** include_gui" 
               | render-guis;

            button text="Удалить" obj=@col->input {
              call target=@col->input name="remove";
            };
           };
         
        };
    };
};