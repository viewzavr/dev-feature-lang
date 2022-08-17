load "lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

screen auto-activate {
  r: row {
    button "make white" c=[1,1,1];
    button "make blue" c=[0,0,1];
    button "make red" c=[1,0,0];
  };

  @r | get_children_arr | get-cell "click" | c-on (make-func { |btn|
    console-log "clicked color" (@btn | geta "c");
  });
};
