load files=`
scene-explorer-3d.js
misc
visual-features.cl
`;

///////////////////////////// набираем фичи
vf1: visual-features
{ // выдает - набор окружений с параметрами {title:..., features1:....., features2: ..... } 
  visual-feature title="Flat mode"   body={feat_struc_z_all_0};
  visual-feature title="Head on top" body={feat_struc_golova_naverhu} init_on=true;
  visual-feature title="Filter" body={feat_filter} init_on=true;
    //visual-feature title="Hide debugger" body={feat_hide_dbg} init_on=true;
    //visual-feature title="Hide loaders" body={feat_hide_load} init_on=true;
  visual-feature title="Show debugger" body={feat_show_dbg};
  visual-feature title="Show loaders" body={feat_show_load};
  visual-feature title="Show all params" body={feat_show_all_params};

  visual-feature title="Background color" body={feat_bgcolor};

  visual-feature title="Hilite recent links" body={feat_link_particle} init_on=true;

  visual-feature title="Hilite recent nodes" body={feat_nodechange_hilite} init_on=true;
  
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

/*
register_feature name="get_param" code=`
  //debugger;
  env.onvalues( ["input","name"],(input,name) => {
    //debugger;
    if (input?.getParam)
      env.setParam( "output", input.getParam( name ) );
  })
`;
*/

register_feature name="install_explorer_feature" {
  rt: obj {
    insert_features input=@explr  list=(@rt->dat | get_param name="explorer-features");
    insert_features input=@sgraph list=(@rt->dat | get_param name="generator-features");
    };
};

/////////////////////////////

register_feature name="debugger_screen_r" {
  scene-explorer-screen hotkey='s' ~dbg_skip {{
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
        text (join "showing items: " (@sgraph->output? | geta "nodes" | geta "length"));
        dom tag="h3" innerText="Selected object" style="margin:0;";
        text "path:";
        text @explr->current_object_path? style="max-width:250px";;
        text "params:";
        render-params object_path=@explr->current_object_path?;

        button "js debugger" curpath=@explr->current_object_path? code=`
           let obj = env.findByPath( env.params.curpath );
           debugger`;
      };

      column gap="0.5em" padding="0.5em" margin="1em" 
             //style="background: rgba( 255 255 255 / 25% ); color: white;" {
              style="background: rgba( 128 128 128 / 50% ); color: white;" {
        dom tag="h3" innerText="Graph params" style="margin:0;";

        //ueb: checkbox text="update_every_beat" value=false;
        render-params object=@sgraph;
        render-params object=@explr;

        // установка добавок
        repeater model=@vf1->output
        {
          cb: column {
            cbb: checkbox 
                    text=(@cb->input | geta "title")
                    value2=false
                    value=(@cb->input | geta "init_on");
                    
            if @cbb->value? then={
              column {
                render-params object=@fobj;
                fobj: insert_children input=@.. list=(@cb->input | geta "body");
                install_explorer_feature dat=@fobj;
              };
            };
            
         };   

        };
      };

    };
    
    //scene_explorer_graph | explr: scene_explorer_3d target=@d1;
    sgraph: scene_explorer_graph
               //add_all_params
               ~add_all_features
               ~add_all_param_refs
               active=@scr->visible
               //sibling_connection
               //children_node=true
               //update_interval=100
               ;

    explr: scene_explorer_3d
              target=@graph_dom 
              input=@sgraph->output?
              /////////struc_z_golova_naverhu
              ~curvature1
              //objects_big
              ~features_big
              //update_every_beat=@ueb->value
              ~obj_titles
              ~node_click_zoom
              ~params_preview_values
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
  env.host.onvalue("graph",(g) => {
      g
      .nodeThreeObjectExtend(true)
      .nodeThreeObject(node => {
          if (node.isobject) {
            if (node.name.startsWith("item_")) return; // это выглядит лишним

            const sprite = new SpriteText(node.name);
            sprite.material.depthWrite = false; // make sprite background transparent
            sprite.color = tri2hex(env.params.obj_title_color || [1,1,1]); //node.color; //  || 'white'
            //sprite.color = 'white';
            sprite.textHeight = env.params.obj_title_size || 12;
            sprite.position.z=10;
            return sprite;
          }
          if (node.isparam) {

              let preview = "-";
              //////////// очень временно и экспериментально.
              // experiment

/*
              if (node.name) {
                node.refobj ||= env.findByPath( node.object_path );
                // закешируем
                let refobj = node.refobj;
                //var refobj = env.findByPath( node.object_path );
                //console.log("nodelabel called");
                var val = refobj ? refobj.getParam( node.name ) : "refobj is null";
                if (!refobj) {
                  //debugger;
                  refobj = env.findByPath( node.object_path );
                }

                // todo: добавить тут наш превьювер строчек

                if (val != null && val.toString)
                  preview = val.toString ? val.toString().slice(0,80) : val;
                else
                  preview = val;
              };
*/              

            //const sprite = new SpriteText( node.name + "=" + preview);
            const sprite = new SpriteText( node.name );

            sprite.material.depthWrite = false; // make sprite background transparent
            sprite.color = tri2hex([0,0.7,0]); //node.color; //  || 'white'
            //sprite.color = tri2hex(env.params.obj_title_color || [1,1,1]); //node.color; //  || 'white'
            //sprite.color = 'white';
            sprite.textHeight = env.params.obj_title_size/2 || 6;
            sprite.position.z=10;
            return sprite;            
          }
      });
  })

  env.addSlider("obj_title_size",12,1,50,1,(v) => {
    env.host.signalParam("graph");
  })
  env.addColor("obj_title_color",[1,1,1],(v) => {
    env.host.signalParam("graph");
  })

    /// работа с цветом    
    // c число от 0 до 255
    function componentToHex(c) {
        if (typeof(c) === "undefined") {
          debugger;
        }
        var hex = c.toString(16);
        return hex.length == 1 ? "0" + hex : hex;
    }

    // r g b от 0 до 255
    function rgbToHex(r, g, b) {
        return "#" + componentToHex(r) + componentToHex(g) + componentToHex(b);
    }  

    // triarr массив из трех чисел 0..1
    function tri2hex( triarr ) {
       return rgbToHex( Math.floor(triarr[0]*255),Math.floor(triarr[1]*255),Math.floor(triarr[2]*255) )
    }

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

            if (val != null && val.toString)
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
  st: criteria-string="screen22"
    {{
      x-param-string name="criteria-string";
    }}
  generator-features={ 
    graph_filter criteria-string=@st->criteria-string; 
  }
  ;
};

load "set-params";

register_feature name="graph_filter" {
  root:
    if @scr->visible then={
       x-set-params 
         input=(find-objects-by-crit 
                   input=@root->criteria-string
                | console_log_input "FILTERED GRAPH OBJECTS"
                );
    } else={
      
      x-set-params input=[];
    };
  ;
};

//////////////////// скрыть отладчик

register_feature name="feat_hide_dbg" {
  generator-features={ hide_debugger; };
};

//////////////////// скрыть load узлы

register_feature name="feat_hide_load" {
  generator-features={ hide_loaders; };
};


//////////////////// показать все параметры

register_feature name="feat_show_all_params" {
  generator-features={ add_all_params; };
};


//////////////////// показать отладчик

register_feature name="feat_show_dbg" {
  generator-features={ show_debugger; };
};

//////////////////// показать load узлы

register_feature name="feat_show_load" {
  generator-features={ show_loaders; };
};


//////////////////// цвет фона

register_feature name="feat_bgcolor" {
  st:
    {{
      color: param_color value=[1,1,1];
    }}
  explorer-features={ gr_bg_color color=@st->color graph=@.->graph; }
  ;
};

register_feature name="gr_bg_color" code=`
  
    /// работа с цветом    
    // c число от 0 до 255
    function componentToHex(c) {
        if (typeof(c) === "undefined") {
          debugger;
        }
        var hex = c.toString(16);
        return hex.length == 1 ? "0" + hex : hex;
    }

    // r g b от 0 до 255
    function rgbToHex(r, g, b) {
        return "#" + componentToHex(r) + componentToHex(g) + componentToHex(b);
    }  

    // triarr массив из трех чисел 0..1
    function tri2hex( triarr ) {
       return rgbToHex( Math.floor(triarr[0]*255),Math.floor(triarr[1]*255),Math.floor(triarr[2]*255) )
    }

  env.onvalues(["graph","color"],(g,c) => {
      //console.log("gggg1",c)
      c = tri2hex(c);
      //console.log("gggg",c)
      g.backgroundColor( c );
      //g.node_title_color = "black";

      // тыркнем остальных чтобы они отразили node_title_color
      //env.host.signalParam("graph");
  });

  //env.onvalue("font_w")
`;


//////////////////// показ ссылок

register_feature name="feat_link_particle" {
  st:
    {{
      color: param_color value=[1,1,1];
    }}
  explorer-features={ link_particle color=@st->color graph=@.->graph? recent_seconds=10; }
  ;
};

register_feature name="link_particle" code=`

    /// работа с цветом    
    // c число от 0 до 255
    function componentToHex(c) {
        if (typeof(c) === "undefined") {
          debugger;
        }
        var hex = c.toString(16);
        return hex.length == 1 ? "0" + hex : hex;
    }

    // r g b от 0 до 255
    function rgbToHex(r, g, b) {
        return "#" + componentToHex(r) + componentToHex(g) + componentToHex(b);
    }  

    // triarr массив из трех чисел 0..1
    function tri2hex( triarr ) {
       return rgbToHex( Math.floor(triarr[0]*255),Math.floor(triarr[1]*255),Math.floor(triarr[2]*255) )
    }

  env.feature("timers");
  let unsub_t = ()=>{}; 
  env.onvalues(["graph","color","recent_seconds"],(g,c,s) => {
    unsub_t();
    process( g,c,s );
    
    unsub_t = env.setInterval( () => {
       //console.log("calling refresh");
       //g.refresh()
       process( g,c,s ); // все-таки надо пере-вызывать
       //console.log("done");
      }, 500 );
   
    //unsub_t = env.setInterval( () => process(g,c,s), 5000 );
  });
  //env.on("remove",sub);

  function process(g,c,s) {
      
      g.linkDirectionalParticles( link => {
          if (!link.islink) return 0;
          if (!link.passed_value_timestamp) return 0;

          let t0 = performance.now(); // todo optimize - на gdata надо реагировать//
          let seconds_ago = (t0 - link.passed_value_timestamp) / 1000;
          if (seconds_ago < s) {
            //console.log("checked link",link,"seconds_ago=",seconds_ago)
            return 5;
          }
          // идея - кол-вом выдавать например давность
          // хотя можно и шириной
          return 0;
      })
      .linkDirectionalParticleWidth( 5 );
      //g.linkDirectionalParticleColor( '#f0f0f0' );
  }

  //env.vz.register_feature_append("link","link_ts");

`;


//////////////////// показ изменившихся узлов (в основном параметров)

register_feature name="feat_nodechange_hilite" {
  st:
    {{
      color: param_color value=[1,1,1];
    }}
  explorer-features={ nodechange_hilite color=@st->color graph=@.->graph? recent_seconds=10; }
  ;
};

register_feature name="nodechange_hilite" code=`

    /// работа с цветом    
    // c число от 0 до 255
    function componentToHex(c) {
        if (typeof(c) === "undefined") {
          debugger;
        }
        var hex = c.toString(16);
        return hex.length == 1 ? "0" + hex : hex;
    }

    // r g b от 0 до 255
    function rgbToHex(r, g, b) {
        return "#" + componentToHex(r) + componentToHex(g) + componentToHex(b);
    }  

    // triarr массив из трех чисел 0..1
    function tri2hex( triarr ) {
       return rgbToHex( Math.floor(triarr[0]*255),Math.floor(triarr[1]*255),Math.floor(triarr[2]*255) )
    }

  env.feature("timers");
  let unsub_t = ()=>{}; 
  env.onvalues(["graph","color","recent_seconds"],(g,c,s) => {
    unsub_t();
    c = tri2hex(c);
    process( g,c,s );
    
    unsub_t = env.setInterval( () => {
       process( g,c,s ); // все-таки надо пере-вызывать
      }, 500 );
  });

  function process(g,c,s) {
      
      g.nodeColor( node => {

          if (!node.changed_timestamp) 
            return node.color;

          let t0 = performance.now(); // todo optimize - на gdata надо реагировать//
          let seconds_ago = (t0 - node.changed_timestamp) / 1000;
          
          if (seconds_ago < s) {
            return c;
          }

          return node.color;

      })
  }

`;
