load files=`
scene-explorer-3d.js
`;

register_feature name="scene-explorer-screen"  {
  screen {
    //button text="click me 2" cmd="@s1->activate";

    column gap="0.5em" padding="0.5em" margin="1em" style="background: rgba( 255 255 255 / 25% ); color: white;" {
      dom tag="h3" innerText="Selected object" style="margin:0;";
      text text="path:";
      text text=@explr->current_object_path;
      text text="params:";
      render-params object_path=@explr->current_object_path;
    };
    
    //scene_explorer_graph | explr: scene_explorer_3d target=@d1;
    sgraph: scene_explorer_graph;
    explr: scene_explorer_3d target=@graph_dom input=@sgraph->output;

    graph_dom: dom style="position: absolute; width:100%; height: 100%; top: 0; left: 0; z-index:-2";
    //d1: dom style="width:500px; height: 500px; ";
  }
}