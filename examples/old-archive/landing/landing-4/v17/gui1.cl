/////////////////////////////////////////////////////
//////////////////////////////////////// гуи версия 1
/////////////////////////////////////////////////////

// вход - input, список объектов чьи гуи нарисовать
register_feature name="render-guis-nested" {
  rep: repeater opened=true {
    col: column {
          button 
            text=(compute_output object=@col->input code=`return env.params.object?.params.gui_title || env.params.object?.ns.name`) 
            cmd="@pcol->trigger_visible";

          pcol: column visible=true style="padding-left: 1em;" {
            render-params object=@col->input;

            find-objects pattern_root=@col->input pattern="** include_gui_inline"
               | 
               repeater {
                 render-params object=@.->input;
               };

            find-objects pattern_root=@col->input pattern="** include_gui"
               | render-guis;

            button text="Удалить" obj=@col->input {
              call target=@col->input name="remove";
            };
           };
         
        };
    };
};

// вход - input, объект чьу гуи нарисовать
register_feature name="render-guis-nested2" {
  col: column {

    if condition=@col->input {
      column {

      column {

        render_params_of_input: render-params object=@col->input;

        find-objects pattern_root=@col->input pattern="** include_gui_inline"
             | 
             repeater {
               render_params_inline: render-params object=@.->input;
             };

        find-objects pattern_root=@col->input pattern="** include_gui"
           | render_guis_includ: render-guis;

        // соберем из объектов созданных в каналах (render3d-items и т.п.)  
        find-objects pattern_root=@col->input pattern="** include_gui_from_output"
           | repeater {
               subr: column { // здесь input это каждый найденный объект в полях output

                  @subr->input | get param="output" | repeater {
                        find-objects pattern_root=@.->input pattern="** include_gui_inline"
                          | 
                           repeater {
                             g_from_output_rp_inline: render-params object=@.->input;
                           };
                   };

                  @subr->input | get param="output" | repeater {
                        find-objects pattern_root=@.->input pattern="** include_gui"
                          | g_from_output_rp_includ: render-guis;
                      };
                   };
               };

       };

       column {
         render-guis input=@extra render-guis-extra;
       };

       extra: gui_title = "Настройки" {
          param_string name="title" value=(@col->input | get param="gui_title")
          {{
             onevent name="param_value_changed" tgt=@col->input in=@extra->title code=`
               if (env.params.tgt)
                   env.params.tgt.setParam("gui_title", env.params.in );
             `;
          }};
          param_cmd name="удалить слой" {
            call target=@col->input name="remove";
          };
        };

/*
       button text="[x]" style="position: absolute; right: 0px; bottom: 0px;" {
            call target=@col->input name="remove";
       };
*/       
      }; // common column
         
     }; // if
   };
};

// вход: list - окружение со списоком описаний добавок.
//       mapping - соответствие каналов добавок объектам приложения (куды добавлять)
register_feature name="layers_gui" {

  lgui: column target=@. {

      row align-items="baseline" {
        
        button text="+" {
            creator target=@lgui->target input=@lgui->layer
              {{ onevent name="created" code=`args[0].manuallyInserted=true;` }};
        };

        dom tag="h3" innerText=@lgui->title;
      };  

      tabview {
        @myobjects->output | repeater {
          tab text=@.->inputIndex {
            render-guis-nested2 input=@..->input;
          };  
        };
      };
      myobjects: find-objects pattern=@lgui->pattern;
  };

};

register_feature name="include_gui_from_output" {
  ok=true;
};

register_feature name="include_gui" {
  ok=true;
};

register_feature name="include_gui_inline" {
  ok=true;
};