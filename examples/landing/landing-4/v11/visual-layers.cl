register_feature name="data_visual_layers"
{
  title="Визуальные слои" {
    linestr: title="Линия" render3d-items={
        main: linestrips include_gui_inline;
    };

    ptstr: title="Точки" render3d-items={
        main: points include_gui_inline;
    };
    
    current_pos: title="Модель" render3d-items={
        gltf: 
          render_gltf src="https://viewlang.ru/assets/models/Lake_IV_Heavy.glb" include_gui_inline
          //positions=(@dat_cur_time | df_combine columns=["X","Y","Z"])
          //rotations=(@dat_cur_time | df_combine columns=["RX","RY","RZ"])
          {{ scale3d coef=@gltf->uscale; }}
          {{ param_slider name="uscale" min=1 max=10 value=1 }}
          ;
    };
  };
};

register_feature name="static_visual_layers"
{
  title="Визуальные слои" {
    
    axes: title="Оси координат" render3d-items={ 
       axes_box include_gui_inline size=100; 
    };

    pole: title="Земля 4кв км" render3d-items={
        main: mesh include_gui_inline 
          positions=[
           -1000,-0.5,-1000,  1000,-0.5,-1000, -1000,-0.5,1000,
           -1000,-0.5,1000,   1000,-0.5,-1000,  1000,-0.5,1000
          ]
          color=[0,0.25,0]
        ;
    };
    
    kvadrat: title="Квадрат места" render3d-items={
        main: mesh include_gui_inline 
          positions=[
           -30,0,-30, 30,0,-30,  -30,0,30,  
           -30,0,30,  30,0,-30,  30,0,30
          ]
          color=[0.4, 0.4, 0.4]
        ; // todo: polygon offset modifier
    };

    stolbik: title="Столбик места" render3d-items={
      main: 
        lines include_gui_inline 
          positions=(compute_output h=@.->h code=`
            return [-30,0,-30, -30, env.params.h,-30 ]
          `)
          color=[1,1,1] 
          {
            param_slider name="h" min=5 max=100 value=5;
          }
        ;
    };
  };
};

// todo: автоматом include_gui_inline и подавать @dat

register_feature name="screen_layers" 
{
  title="Надписи" {
    curtime: title="Текущее время" screen-items={
      
        dom tag="h2" style="color: white"
        innerText=(compute_output t=@mainparams->time code="
           return 'T='+(env.params.t || 0).toFixed(3);
        ");
    };
    allvars: title="Все переменные" screen-items={
      
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

    selectedvars: title="Переменные по выбору" screen-items={
      
        dom 
        style="color: white; display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
                   min-width: 300px; font-size: larger"
        innerHTML=@qq->output {

          selected: include_gui gui_title="Выбрать" {{ 
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
  };
};