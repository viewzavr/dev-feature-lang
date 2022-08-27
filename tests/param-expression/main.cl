load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

screen auto_activate {
  row {
    text text="result = (";
    text text=(compute_output code='return 2+2');
    text text=" )";
  };
};

// debugger_screen_r;

/*
  scene-explorer-screen hotkey='b' {{
    apply_by_hotkey hotkey='b' {
      rotate_screens;
    };
  }}
*/