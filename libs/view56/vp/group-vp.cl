// визпроцесс-группа


feature "group-vp" {
  gvp: visual_process
    title="Группа" 
    visible=true
  subprocesses=(@gvp | get_children_arr | arr_filter_by_features features="visual_process" )  
  {{
    @gvp->subprocesses | x-modify {
      x-set-params visible=@gvp->visible
    };
  }}
  //subprocesses=(@gvp | find-)
  scene3d=(@gvp->subprocesses | map_geta "scene3d" | arr_compact)  
  scene2d=(@gvp->subprocesses | map_geta "scene2d" | arr_compact)
  gui={
     column plashka {

      column {
        //@gvp->subprocesses | render-guis;
        show_sources_params input=@gvp->subprocesses;
      };

      //button "отладка" { console_log_apply @gvp };
      button "настроить..." {
         //i-call @setupdlg "apply";
         call target=@setupdlg name="apply";
      };


    }; // col plashka
  } // gui
  gui3={ 
      render-params @gvp;
  }
  {{ x-param-string name="title" }}
  //{{ x-add-cmd name="Настроить" code=(call target=@setupdlg name="apply")}}
  {

    setupdlg: dialog {
          column {     
            text "Добавить объекты:";
            find-objects-bf root=@gvp->project features="visual-process" recursive=false
            |
            repeater {
              b: button text=(@b->input | geta "title") {
                i-call-js @b->input @gvp code="(vp,g) => {
                    g.ns.appendChild( vp, vp.ns.name );
                    debugger;
                    // ссылки собьются, однако.. через combo то настроенные...

                }";
              } // кнопка
            }; // репитер
          }; // колонка
        }; // диалог

  };
};
