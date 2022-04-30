load "lib3dv3 csv params io gui render-params df scene-explorer-3d gui5.cl new-modifiers";

load "landing/landing-view-1.cl landing/test.cl universal/universal-vp.cl"; // отдельный вопрос

feature "addview" {
  column {
    button "Добавить вид"
  };
};

feature "visual_process" {
};

project: {
  v1: {
    axes-view;
    landing-view-1;
    landing-view-1;
  };
  v2: {
    landing-view-1;
  };
};

// отображение. тут и параметр как компоновать
// параметр - список визуальных процессов видимо.
// ну а может контейнер ихний. посмотрим
// input 

// так это уже конкретная показывалка - с конкретным методом комбинирования.
// мы потом это заоверрайдим чтобы было несколько методов комбинирования и был выбор у человека
// хотя это можно и как параметр этой хрени и как суб-компоненту сделать.
feature "show_visual_tab" {
   sv: dom_group {

    svlist: column {
      repeater input=@sv->input {
        mm: 
        dom tag="fieldset" style="border-radius: 5px; padding: 2px; margin: 2px;" {
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
          }
        };
      }; // repeater  

    }; // svlist

    scene_3d_view: view3d style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2";

    r1: render3d 
        bgcolor=[0.1,0.2,0.3]
        target=@scene_3d_view //{{ skip_deleted_children }}
        input=(@sv->input | map_param "scene3d") // кстати идея так-то сделать аналог и для 2д - до-бирать детей отсель
    {
        camera3d pos=[-400,350,350] center=[0,0,0];
        orbit_control;
        
    };

    extra_screen_things: 
    column style="padding-left:2em; min-width: 80vw; 
       position:absolute; bottom: 1em; left: 1em;" {
       dom_group 
         input=(@sv->input | map_param "scene2d");
       
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

screen1: screen auto-activate {
   column padding="1em" {
       ssr: switch_selector_row index=0 items=["Вид 1","Вид 2","Добавить"] 
                style_qq="margin-bottom:15px;" {{ hilite_selected }};
                
       of: one_of 
              index=@ssr->index
              list={ 
                show_visual_tab input=(get_children_arr input=@v1); // так то.. так то.. показывай просто текущий, согласно project[index].. но параметры сохраняй...
                show_visual_tab input=(get_children_arr input=@v2);
                addview;
              }
              {{ one-of-keep-state; one_of_all_dump; }}
              ;

   };          
};

debugger-screen-r;

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