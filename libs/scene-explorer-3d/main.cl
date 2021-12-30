load files="lib3dv3 csv params io gui render-params df
            scene-explorer-3d misc
            ";

s1: screen auto_activate activate_by_hotkey hotkey='i' {
  button text="click me" cmd="@s2->activate";

//  scene_explorer_graph | scene_explorer_3d target=@d1;
//  d1: dom style="position: absolute; width:100%; height: 100%; top: 0; left: 0; z-index:-2";
  
};

s2: scene-explorer-screen activate_by_hotkey hotkey='q';

apply_by_hotkey hotkey='b' {
  rotate_screens;
};