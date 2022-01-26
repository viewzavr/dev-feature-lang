load files=`
scene-explorer-3d.js
misc
visual-features.cl
`;

///////////////////////////// набираем фичи
vf1: visual-features
{ // выдает - набор окружений с параметрами {title:..., features1:....., features2: ..... } 
  visual-feature title="Flat mode"   body={feat_struc_z_all_0};
  visual-feature title="Head on top" body={feat_struc_golova_naverhu};
  visual-feature title="Filter" body={feat_filter};
  // кстати тут реально можно было бы и карту построить просто... чистово гуи с группами...
  // не знаю зачем я заморачиваюсь...
};

///////////////////////////// утилита dbg и другие

// меняет отладочную информацию по данному узлу в визуальном дереве
register_feature name="dbg" code=`
  env.host.on('dbg-add',(opts) => {
     Object.assign( opts, {radius:100},env.params );
  })
`;

register_feature name="get_param" code=`
  //debugger;
  env.onvalues( ["input","name"],(input,name) => {
    //debugger;
    if (input?.getParam)
      env.setParam( "output", input.getParam( name ) );
  })
`;

register_feature name="install_explorer_feature" {
  rt: {
    deploy_features input=@explr  features=(@rt->dat | get_param name="explorer-features");
    deploy_features input=@sgraph features=(@rt->dat | get_param name="generator-features");
    };
};

/////////////////////////////

register_feature name="two_side_columns" {
  row justify-content="space-between"
      align-items="flex-start"
      style="width: 100%" class="vz-mouse-transparent-layout";
  // вот я тут опираюсь на хрень vz-mouse-transparent-layout которая определена непойми где...
  // непроговоренные ожидания.. хоть бы module-specifier указал бы как-то..
};

register_feature name="debugger_screen_r" {
  scene-explorer-screen hotkey='s' {{
    apply_by_hotkey hotkey=@.->hotkey {
      rotate_screens;
    };
  }}
};

register_feature name="scene-explorer-screen"  {
scr: screen {
    //button text="click me 2" cmd="@s1->activate";

    cols: two_side_columns {

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

        // установка добавок
        repeater model=@vf1->output
        {
          cb: column {
            cbb: checkbox text=(@cb->modelData | get_param name="title") value=false;
            if condition=@cbb->value {
              column {
                render-params object=@fobj;
                fobj: deploy input=(@cb->modelData | get_param name="body");
                install_explorer_feature dat=@fobj;
              }
            }
            
         }   

        }
      };

    };
    
    
    //scene_explorer_graph | explr: scene_explorer_3d target=@d1;
    sgraph: scene_explorer_graph
               //add_all_params
               add_all_features
               add_all_param_refs
               active=@scr->visible
               //sibling_connection
               //children_node=true
               //update_interval=100
               ;

    explr: scene_explorer_3d
              target=@graph_dom 
              input=@sgraph->output
              /////////struc_z_golova_naverhu
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
      g.nodeVal( (node) => node.isfeature ? 10 : (node.radius || node.v || 1) )
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
              //debugger;
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

//////////////////////////////// struc_z_all_0
// располагает всех в одной плоскости

// связки
register_feature name="add_struc_z_all_0" {
  dbg-3d-feature title="Flat mode" explorer-features={ struc_z_all_0; }
   ;
};

// то есть вот это у нас - объект управления + пакет добавок (добавляется внешне!)
// и плюс допом вверху будет гуи-запись. тройное...
register_feature name="feat_struc_z_all_0" {
  explorer-features={ struc_z_all_0 ; }
  ;
};

// фича
register_feature name="struc_z_all_0" code=`
  let lastrec;
  let unsub = env.host.onvalue("gdata",(rec) => {
    //debugger;
      lastrec = rec;
      rec.nodes.forEach( (node) => {
          //if (!node.fz)
          node.fz = 0.000001;
      })
  })
  // on remove... - хватит читать value
  // .struc_computed
  env.on("remove",() => {
    unsub();
    lastrec?.nodes.forEach( (node) => {
      node.fz = undefined;
    })
  });
`;

// апи версия 2
// фича вида add-feature ... получает на вход target равный окружению с детьми 
// explr, sgraph и cols. и типа пожалуйста на них влияй скока хочушь.
// хотя.. это тоже самое что наверное сказать: activate-feature { add_struc_z_all_0; }
///////////////////////////////////// struc_z_golova_naverhu
// связка
register_feature name="add_struc_golova_naverhu" {
  dbg-3d-feature 
     title="3d mode, root top" 
     explorer-features={ struc_z_golova_naverhu step=100; }
     state={
       st: step=20  
         explorer-features={ struc_z_golova_naverhu step=@st->step; }
     }
  ;
};

register_feature name="feat_struc_golova_naverhu" {
  st:
    {{
      z-factor: param_slider min=0 max=500 step=10 value=50;
    }}
  explorer-features={ struc_z_golova_naverhu step=@st->z-factor; }
  ;
};

// располагает всех таким образом чтобы они были по плоскостям
// в зависимости от вложенности - корень вверху
register_feature name="struc_z_golova_naverhu" code=`
  if (!env.params.step) env.params.step = 50;
  let lastrec;
  let epoch=0;

  env.onvalue("step",() => { 
    epoch++; 
    env.host.callCmd("refresh");
  })
  
  let unsub = env.host.onvalue("gdata",(rec) => {
      let r = -1*env.params.step;
      rec.nodes.forEach( (node) => {
          if (node.struc_computed != epoch) {
             if (node.object_path)
                 node.fz = node.object_path == "/" ? 0 : node.object_path.split("/").length * r;
             node.struc_computed = epoch;
          } 
      })
  });
  env.on("remove",() => {
    unsub();
    lastrec?.nodes.forEach( (node) => {
      node.fz = undefined;
      node.struc_computed = undefined;
    })
  });  
`;

//////////////////// добавка про фильтрацию по имени


register_feature name="feat_filter" {
  st:
    {{
      pattern: param_string value="** lib3d-visual";
    }}
  generator-features={ graph_filter pattern=@st->pattern; add_all_params; }
  ;
};

load files="set-params";

register_feature name="graph_filter" {
  root: set_params input=@selected->output {
    selected: find-objects pattern=@root->pattern | console_log text="FILTERED OBJECTS";
  };
};
