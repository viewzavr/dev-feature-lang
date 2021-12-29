load files=`
scene-explorer-3d.js
`;

register_feature name="scene-explorer-screen"  {
  screen {
    //button text="click me 2" cmd="@s1->activate";
    
    scene_explorer_graph | scene_explorer_3d target=@d1;

    d1: dom style="position: absolute; width:100%; height: 100%; top: 0; left: 0; z-index:-2";
    //d1: dom style="width:500px; height: 500px; ";
  }
}