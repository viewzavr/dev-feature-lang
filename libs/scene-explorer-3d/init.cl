load files=`
scene-explorer-3d.js
misc
`;

register_feature name="two_side_columns" {
  row justify-content="space-between" 
      align-items="flex-start"
      style="width: 100%" class="vz-mouse-transparent-layout";
  // вот я тут опираюсь на хрень vz-mouse-transparent-layout которая определена непойми где...
  // непроговоренные ожидания.. хоть бы module-specifier указал бы как-то..
};

register_feature name="debugger_screen_r" {
  scene-explorer-screen hotkey='q' {{
    apply_by_hotkey hotkey=@.->hotkey {
      rotate_screens;
    };
  }}
};

register_feature name="scene-explorer-screen"  {
scr: screen {
    //button text="click me 2" cmd="@s1->activate";

    two_side_columns {

      column gap="0.5em" padding="0.5em" margin="1em" style="background: rgba( 255 255 255 / 25% ); color: white;" {
        dom tag="h3" innerText="Selected object" style="margin:0;";
        text text="path:";
        text text=@explr->current_object_path;
        text text="params:";
        render-params object_path=@explr->current_object_path;

        button text="js debugger" curpath=@explr->current_object_path code=`
           let obj = env.findByPath( env.params.curpath );
           debugger`;
      };

      column gap="0.5em" padding="0.5em" margin="1em" 
             style="background: rgba( 255 255 255 / 25% ); color: white;" {
        dom tag="h3" innerText="Graph params" style="margin:0;";

        //ueb: checkbox text="update_every_beat" value=false;
        render-params object=@sgraph;
        render-params object=@explr;
      };

    };
    
    
    //scene_explorer_graph | explr: scene_explorer_3d target=@d1;
    sgraph: scene_explorer_graph
               //add_all_params
               add_all_features
               //sibling_connection
               //children_node=true
               //update_interval=100
               ;

    explr: scene_explorer_3d 
              target=@graph_dom 
              input=@sgraph->output
              struc_z_golova_naverhu
              curvature1
              //objects_big
              features_big
              //update_every_beat=@ueb->value
              obj_titles
              params_preview_values
              active=@scr->visible
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

// большие узлы объектов остальное помельче
register_feature name="objects_big" code=`
  env.onvalue("graph",(g) => {
      g.nodeVal( (node) => node.isobject ? 10 : 1 )
  })
`;

// большие узлы фич остальное помельче
register_feature name="features_big" code=`
  env.onvalue("graph",(g) => {
      g.nodeVal( (node) => node.isfeature ? 10 : 1 )
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
// в зависимости от вложенности - корень внизу
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

// располагает всех таким образом чтобы они были по плоскостям
// в зависимости от вложенности - корень вверху
register_feature name="struc_z_golova_naverhu" code=`
  env.onvalue("gdata",(rec) => {
      let r = -50;
      rec.nodes.forEach( (node) => {
          if (!node.struc_computed) {
             if (node.object_path)
                 node.fz = node.object_path == "/" ? 0 : node.object_path.split("/").length * r;
             node.struc_computed = true;
          } 
      })
  })
`;


// добавить названия объектов
register_feature name="obj_titles" code=`
  env.onvalue("graph",(g) => {
      g
      .nodeThreeObjectExtend(true)
      .nodeThreeObject(node => {
          if (node.isobject) {
            if (node.name.startsWith("item_")) return; // это выглядит лишним

            const sprite = new SpriteText(node.name);
            sprite.material.depthWrite = false; // make sprite background transparent
            sprite.color = 'white'; //node.color;
            sprite.textHeight = 12;
            sprite.position.z=10;
            return sprite;
            }
      });
  })
`;

// добавить значения параметров при наведении мышки
register_feature name="params_preview_values" code='
  env.onvalue("graph",(g) => {
      g
       .nodeLabel( node => {

          let s1=node.label || node.id;
          if (!node.isparam) return s1;

          let preview = "cant preview value, no node.name";
          if (node.name) {
            var refobj = env.findByPath( node.object_path );
            //console.log("nodelabel called");
            var val = refobj ? refobj.getParam( node.name ) : "refobj is null";
            if (!refobj) {
              debugger;
              refobj = env.findByPath( node.object_path );
            }

            // todo: добавить тут наш превьювер строчек

            if (typeof(val) != "undefined" && val.toString)
              preview = val.toString ? val.toString().slice(0,80) : val;
            else
              preview = val;
          };
          
          return s1 + "<br/><br/>"+preview;
       })
  });
';