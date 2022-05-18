load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc imperative";


nodetree: type="alfa" {
   type="beta" {
     type="ref";
   };
   type="teta";
 };

console_log "nodetree=" @nodetree; 

newitemtemplate: (template {
  type="alfa";
});

possible_types: (list "alfa" "beta" "teta" "zita" "ref");

feature "render-node" 
{
  node: column {
    dat: @..->input;
    dat_parent: @..->input_parent;
    parent_editor: @..->parent_editor;    

    row {
      text "тип";
      combobox value=(@dat | geta "type") values=@possible_types;

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