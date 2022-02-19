/////////////////////////////////////////////////////
//////////////////////////////////////// гуи версия 2
/////////////////////////////////////////////////////


register_feature name="collapsible" {
  cola: 
  column
  {
    shadow_dom {
      btn: button text=@cola->text cmd="@pcol->trigger_visible";

      pcol: 
      column visible=false {{ use_dom_children from=@cola; }};

      deploy_features input=@btn  features=@cola->button_features;
      deploy_features input=@pcol features=@cola->body_features;
    };

  };
};

register_feature name="collapsible2" {
  cola:
  column
  {
    shadow_dom {
      row {
        btn: button text=@cola->text cmd="@pcol->trigger_visible" flex=1;
        cba: checkbox value=@cola->active cola=@cola {{
          onevent name="user-changed" {
            emit_event object=@cola name="user-changed-active";
          };
        }};
      };

      pcol:
      column visible=false {{ use_dom_children from=@cola; }};

      deploy_features input=@btn  features=@cola->button_features;
      deploy_features input=@pcol features=@cola->body_features;
    };

  };
};

register_feature name="collapsible3" {
  cola:
  dom_group
  {
    shadow_dom {
      row {
        btn: button text=@cola->text cmd="@pcol->trigger_visible" flex=1;
        cba: checkbox value=@cola->active cola=@cola {{
          onevent name="user-changed" {
            emit_event object=@cola name="user-changed-active";
          };
        }};
      };

      pcol:
      column visible=false {{ use_dom_children from=@cola; }};

      deploy_features input=@btn  features=@cola->button_features;
      deploy_features input=@pcol features=@cola->body_features;
    };

  };
};


register_feature name="render-guis2" {
  repeater opened=true {
    das1: 
      collapsible 
        text=(compute_output object=@.->input code=`return env.params.object?.params.gui_title || env.params.object?.ns.name;`) 
        body_features={set_params style="padding-left:1em;"}
    {
      render-params object=@das1->input;
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
           | render_guis_includ: render-guis2;

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
                          | g_from_output_rp_includ: render-guis2;
                      };
                   };
               };

       };

       column {
         render-guis2 input=@extra;
       };

       extra: gui_title = "Настройки" {
          param_string name="title" value=(@col->input | get param="gui_title")
          {{
             onevent name="param_value_changed" tgt=@col->input in=@extra->title code=`
               if (env.params.tgt)
                   env.params.tgt.setParam("gui_title", env.params.in );
             `;
          }};
          param_cmd name="Удалить" {
            call target=@col->input name="remove";
          };
        };

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

//////////////////////////////////////////////////////

// вход: list - окружение со списоком описаний добавок.
//       mapping - соответствие каналов добавок объектам приложения (куды добавлять)
//       text - надпись

// вот кстати здесь мы видим плохость в смешении окружений
// target это параметр layers_gui2, но он одновременно становится и параметром collapsible...
// а не факт что это то что нам было нужно. заманчиво конечно не заниматься передачей параметров,
// но с другой стороны явная передача выглядит для дальнейшего восприятия лучше..
// todo поанализировать эти случаи, когда и что и как мы используем и что ожидаем.


register_feature name="layers_gui2" {

  lgui: collapsible 
        target=@.
          //body_features={set_params style="padding:0.2em 0.2em 0.2em 0.4em; gap: 0.2em;";}
  {

    button text="+ Добавить" {
            creator target=@lgui->target input=@lgui->layer
              {{ onevent name="created" code=`args[0].manuallyInserted=true; console.log("created",args[0])` }};
    };
    
    find-objects pattern=@lgui->pattern 
     | repeater {
        collapsible2 text=(@.->input | get_param name="gui_title") 
          body_features=@lgui->each_body_features
          active=(@.->input | get_param name="active")
        {{
          connection event_name="user-changed-active" code=`
            //console.log("setting active to",env.host.params.input,"value=",args[0])
            env.host.params.input.setParam("active",args[0]);
          `;
        }}
        {

          //link from=@.->active to=@.->input
          render-guis-nested2 input=@..->input;
        };
     };

    
 
  };

};