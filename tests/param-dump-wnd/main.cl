load "lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

someobj: test1
  {{ x-param-slider name="slider1" }};


screen auto_activate {
  row {
    render-params @someobj;
  };
};

debugger_screen_r;
