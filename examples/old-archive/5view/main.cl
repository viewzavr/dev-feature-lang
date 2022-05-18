load "lib3dv3 csv params io gui render-params df scene-explorer-3d gui5.cl new-modifiers imperative";

load "landing2/landing-view.cl landing/test.cl universal/universal-vp.cl"; // отдельный вопрос

feature "setup_view" {
  column {
    button "Настройки"
  };
};

feature "the_view" {
};

feature "visual_process" {
};

project: active_view_index=1 {
  v0: the-view title="Данные" {
    landing-file;
  };

  v1: the-view title="Общий вид" {
    landing-view-1;
    landing-view-1 title="Траектория 2" visible=false;
    axes-view size=100;
  };

  v2: the-view title="Вид на ракету" {
    landing-view-2;
    axes-view;
  };
  /*
  v_setup: the-view title="Настройки" {
    //sync_params_process root=@project;
  }
  */
};

screen1: screen auto-activate  {
  render_project @project active_view_index=1;
};

debugger-screen-r;

////////////////////////////////////////////////////////

// отображение. тут и параметр как компоновать
// параметр - список визуальных процессов видимо.
// ну а может контейнер ихний. посмотрим
// input 

// так это уже конкретная показывалка - с конкретным методом комбинирования.
// мы потом это заоверрайдим чтобы было несколько методов комбинирования и был выбор у человека
// хотя это можно и как параметр этой хрени и как суб-компоненту сделать.

// обновление. input это объект вида. the-view.
feature "show_visual_tab" {
   sv: dom_group 
   {

    row {

    svlist: column {
      repeater input=(@sv->input | get_children_arr) {
        mm: 
         row {
        //dom tag="fieldset" style="border-radius: 5px; padding: 2px; margin: 2px;" {
          collapsible text=(@mm->input | get_param "title" default="no title") 
            style="min-width:250px;" padding="2px"
            style_h = "max-height:80vh;"
            body_features={ set_params style_h="max-height: inherit; overflow-y: auto;"}          
          {
             insert_children input=@.. list=(@mm->input | get_param "gui");
             // вот мы вставили гуи
          };

          cbv: checkbox value=(@mm->input | get_param "visible");
          x-modify input=@mm->input {
            x-set-params visible=@cbv->value ;
            x-on "show-settings" {
              lambda @extra_settings_panel code="(panel,obj,settings) => {
                 // console.log('got x-on show-settings',obj,settings)
                 // todo это поведение панели уже..
                 // да и вообще надо замаршрузизировать да и все будет.. в панель прям
                 // а там типа событие или тоже команда
                 if (panel.params.list == settings)
                   panel.setParam('list',[]);
                 else  
                   panel.setParam('list',settings);
                 
              };
              ";
            };
          };
        }; // fieldset
      }; // repeater

    }; // svlist

    extra_settings_panel_outer: row gap="2px" {
      extra_settings_panel: 
      column // style="position:absolute; top: 1em; right: 1em;" 
      {
         insert_children input=@.. list=@extra_settings_panel->list;
      };
      button "&lt;" style_h="height:1.5em;" visible=(eval @extra_settings_panel->list code="(list) => list && list.length>0") 
      {
        setter target="@extra_settings_panel->list" value=[];
      };
    }; // extra_settings_panel_outer

    }; // row

    scene_3d_view: view3d style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2";

    r1: render3d 
        bgcolor=[0.1,0.2,0.3]
        target=@scene_3d_view //{{ skip_deleted_children }}
        input=(@sv->input | get_children_arr | map_param "scene3d") // кстати идея так-то сделать аналог и для 2д - до-бирать детей отсель
    {
        camera3d pos=[-400,350,350] center=[0,0,0];
        orbit_control;
    };

    extra_screen_things: 
    column style="padding-left:2em; min-width: 80vw; 
       position:absolute; bottom: 1em; left: 1em;" {
       dom_group 
         input=(@sv->input | get_children_arr | map_param "scene2d");
    };

    // думаю нет ничего плохого если мы этим скажим рисоваться сюды
    x-modify input=@sv->input {
      //x-set-params slice_scene3d=@scene_3d_view slice_renderer=@r1 scene2d=@extra_screen_things;
      //x-set-params scene2d=@extra_screen_things;
    };

   }; // domgroup

};

/* не ну это интрига. говорить - инсерт чилдрен таба из его гуи.. хм..
feature "oneview" {
  ov: gui={
  }
}
*/

//lv1: landing-view-1;

feature "render_project" {
   rend: column padding="1em" project=@.->0 active_view_index=0 {
       ssr: switch_selector_row 
               index=@rend->active_view_index
               items=(@rend->project | get_children_arr | map_param "title")
                //items=["Вид 1","Вид 2","Настройки"] 
                style_qq="margin-bottom:15px;" {{ hilite_selected }}
                /*
                {{ link to="@rend->active_view_index" from="@.->index" manual=true }}
                
                {{ x-on "param_index_changed" {
                     i-call-block {
                       args: i-args;
                       setter target="@rend->active_view_index" value=@args->1 manual_mode=true;
                       //i-set-param target=@rend param="index" value=@args->1;
                       i-console-log "done" @args->0 @args->1;
                     };  
                  };
                }}
                */
                
                ;

       //show_visual_tab input=(@screen1->project | get_children_arr | get index=@ssr->index);

       of: one_of 
              index=@ssr->index
              list={ 
                show_visual_tab input=(@rend->project | get_children_arr | get 0); // так то.. так то.. показывай просто текущий, согласно project[index].. но параметры сохраняй...
                show_visual_tab input=(@rend->project | get_children_arr | get 1);
                show_visual_tab input=(@rend->project | get_children_arr | get 2);
                show_visual_tab input=(@rend->project | get_children_arr | get 3);
                show_visual_tab input=(@rend->project | get_children_arr | get 4);
              }
              {{ one-of-keep-state; one_of_all_dump; }}
              ;

   };  
}



/*
  of: one_of 
              index=@ssr->index
              list={ 
                oneview {
                  collapsible text="Траектория возвращения" style="min-width:250px;" padding="5px"
                  {
                    //render-params input=@lv1;
                    insert_children input=@.. list=@lv1->gui;
                  };
                  collapsible text="Траектория возвращения 2" style="min-width:250px;" padding="5px"
                  {
                    //render-params input=@lv1;
                    insert_children input=@.. list=@lv1->gui;
                  };
                };
                oneview;
                addview;
              }
              {{ one-of-keep-state; one_of_all_dump; }}
              ;

*/