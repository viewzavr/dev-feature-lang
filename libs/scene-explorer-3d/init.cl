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
    explr: scene_explorer_3d 
              target=@graph_dom 
              input=@sgraph->output
              struc_z
              curvature1
              ;

    graph_dom: dom style="position: absolute; width:100%; height: 100%; top: 0; left: 0; z-index:-2";
    //d1: dom style="width:500px; height: 500px; ";
  };
};

// прямые связи всюду кроме ссылок
register_feature name="curvature0" code=`
  env.onvalue("graph",(g) => {
      g.linkCurvature( link => link.islink ? 0.2 : 0 )
  })
`;

// корявые соединения на структуре, остальные попрямее
register_feature name="curvature1" code=`
  env.onvalue("graph",(g) => {
      g.linkCurvature( link => link.isstruct ? 0.0 : 0.2 )
  })
`;

// фиксирует узел после перетаскивания
register_feature name="fixdrag" code=`
  env.onvalue("graph",(g) => {
      g.onNodeDragEnd(node => {
          node.fx = node.x;
          node.fy = node.y;
          node.fz = node.z;
      });
  })
`;

// располагает всех в одной плоскости
register_feature name="plane_nodes" code=`
  env.onvalue("gdata",(rec) => {
      rec.nodes.forEach( (node) => {
          if (!node.fz)
               node.fz = 0.000001;
      })
  })
`;

// располагает всех таким образом чтобы они были по плоскостям
// в зависимости от вложенности
register_feature name="struc_z" code=`
  env.onvalue("gdata",(rec) => {
      let r = 50;
      rec.nodes.forEach( (node) => {
          if (!node.struc_computed) {
             if (node.object_path)
                 node.fz = node.object_path == "/" ? 0 : node.object_path.split("/").length * r;
             node.struc_computed = true;
          } 
      })
  })
`;
