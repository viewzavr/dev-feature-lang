data_visual code="linestr" title="Линия" render3d-items={
        main: linestrips include_gui_inline {
           param_cmd name="dbg" code=`
             debugger;
           `;
        };
};

data_visual code="ptstr" title="Точки" render3d-items={
        main: points include_gui_inline;
};
    
    // вход input это dataframe
data_visual code="models" title="Модель" render3d-items={
      root: node3d include_gui_inline {
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
       axes_box include_gui_inline size=100; 
};

static_visual code="pole" title="Земля 4кв км" render3d-items={
        main: mesh include_gui_inline 
          positions=[
           -1000,-0.5,-1000,  1000,-0.5,-1000, -1000,-0.5,1000,
           -1000,-0.5,1000,   1000,-0.5,-1000,  1000,-0.5,1000
          ]
          color=[0,0.25,0]
        ;
};
    
static_visual code="kvadrat" title="Квадрат места" render3d-items={
        main: mesh include_gui_inline 
          positions=[
           -30,0,-30, 30,0,-30,  -30,0,30,  
           -30,0,30,  30,0,-30,  30,0,30
          ]
          color=[0.4, 0.4, 0.4]
        ; // todo: polygon offset modifier
    };

static_visual code="stolbik" title="Столбик места" render3d-items={
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


screen_visual code="curtime_sl" title="Управление временем на экране" screen-items={

        slider value=@time_slider->value max=@time_slider->max {
          link to="@time_slider->value" from="..->value";
        };
};
