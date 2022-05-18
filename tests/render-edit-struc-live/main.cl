load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc imperative";


nodetree: 
  manual_features="overlay" {
   manual_features="render3d_join" {
     manual_features="ref";
     manual_features="ref";
     manual_features="ref";
   };
   manual_features="column" {
     manual_features="ref";
     manual_features="ref";    
   }
 };

console_log "nodetree=" @nodetree; 

newitemtemplate: (template {
  manual_features="ref";
});

possible_types: (list "overlay" "render3d_join" "render3d_left_right" "render3d_window_in_window" "ref" "column");

feature "render-node" 
{
  node: column {
    dat: @..->input;
    dat_parent: @..->input_parent;
    parent_editor: @..->parent_editor;    

    row {
      text "тип";
      combobox value=(@dat | geta "manual_features" | geta 0) values=@possible_types;

      button "+" {
        creator input=@newitemtemplate target=@dat;
      };
      button "-" {
        i-call-js @dat code="(obj) => {
            obj.remove();
        };"
      }
    };

    column {
      @dat | get_children_arr | repeater {
        r: row {
          text " - ";
          render-node input=@r->input input_parent=@dat parent_editor=@../../..;
        };
      };  
    };
  };
};

screen auto_activate {
  column {
    text "Редактируем узел";
    render-node input=@nodetree;

  };
};

debugger_screen_r;

/*
  scene-explorer-screen hotkey='b' {{
    apply_by_hotkey hotkey='b' {
      rotate_screens;
    };
  }}
*/