load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc imperative";


nodetree: (template {
 type="alfa" {
   type="beta" {
     type="ref";
   };
   type="teta";
 };
} | geta 0);

newitemtemplate: (template {
  type="alfa";
} | geta 0);

console_log @nodetree;

/*
jsdata: { "type": "alfa", "children": [
   "type":"beta"
   ]}
*/

possible_types: (list "alfa" "beta" "teta" "zita" "ref");

feature "render-node" 
{
  node: column {
    dat: @..->input;
    dat_parent: @..->input_parent;
    parent_editor: @..->parent_editor;    

    row {
      text "тип";
      combobox value=(@dat | console_log_input "SSS" | geta "params" | geta "type") values=@possible_types;

      button "+" {
        i-call-js @dat @newitemtemplate @node code="(obj,t,editor) => {
            // идея заменить потом newitemtemplate на функцию от obj
            console.log(obj,t)
            t.counter = (t.counter || 0) +1;
            let newname = 'newname_' + t.counter;
            obj.children[ newname ] = t;
            //editor.signalParam('input');
            // тож не катит.
            editor.setParam('input',JSON.parse( JSON.stringify( obj )))
        };"
      };
      button "-" {
        i-call-js @dat @parent_editor code="(obj,peditor) => {
            //debugger;
            //p = editor.ns.parent.params.input;
            let p = peditor.params.input;
            if (!p) return;
            //debugger;
            delete p.children[ obj.$name ];
            peditor.setParam('input',JSON.parse( JSON.stringify( p )))
        };"
      }
    };

    column {
      @dat | geta "children" | geta (i-call-js code="(obj) => Object.values(obj)") | repeater {
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
    text "Редактируем узел 2";
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