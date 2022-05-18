load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

nodetree: data={type=alfa {
   type=beta;
   type=teta;
 }
};

possible_types: (list "alfa" "beta" "teta" "zita");

feature "render-node" {
  node: row {
    js: @..->input;
    //text @node->type;
    text "тип";
    combobox value=@js->type values=@possible_types;
    // type params.. например если это ref то источник..

    column {
      @js | geta "children" | repeater {
        render-node;
      };
    };
  };
};

screen auto_activate {
  row {
    render-node input=@nodetree->data;
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