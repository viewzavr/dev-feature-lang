load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

screen auto_activate {
  column {
    text (join "1 result = " (a: 5; b: 7; + @a @b; ) );
    text (join "2 result = " (if (1 > 0) then={33}) );
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