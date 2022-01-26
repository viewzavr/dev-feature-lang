//import ThreeForceGraph from 'three-forcegraph';
//import {ForceGraph3D} from './3d-force-graph.js';

// https://github.com/vasturiano/3d-force-graph#data-input

export function setup(vz, m) {
  vz.register_feature_set( m );
}

function addnode( rec, objrec ) {
  rec.nodes.push( objrec );
  rec.nodes_table[ objrec.id ] = objrec;
  objrec.table_key = objrec.id;
}

function addlink( rec, linkrec ) {
  rec.links.push( linkrec );
  let linkid = linkrec.table_key || `${linkrec.source}=>${linkrec.target}`;
  rec.links_table[ linkid ] = linkrec;
  linkrec.table_key = linkid;
}

function create_rec() {
  return {nodes: [], links: [], nodes_table: {}, links_table: {} }
}


// поставить стрелочки между детьми-соседями
export function sibling_connection( env ) {
  env.on("genobj",(obj,rec, id) => {

    var ch = obj.ns.getChildNames();
    let prevchild;
    ch.forEach( function(cname,index) {
        var c = obj.ns.getChildByName( cname );
        
        if (c.historicalType == "link")  // ссылки параметры
          return;

        if (prevchild)
        addlink( rec, {target: c.getPath(),
                       source: prevchild.getPath(), 
                       isstruct: true,
                       color: 'black'

                       })
        
        prevchild = c;
    });


  })
}

// добавить все параметры в граф
export function add_all_params( env ) {
  env.host.on("genobj",(obj,rec, id) => {
    // параметры все
    var params = obj.getParamsNames();
    //if (!obj.params.hasOwnProperty("children")) params = params.concat( ["children"] );
    //params=["children"];
    //params=[];

    params.forEach( (pn,index) => {
      //rec.nodes.push( { id: id + "->" + pn, name: pn } );
      addnode( rec, { id: id + "->" + pn, name: pn, object_path: id, color: 'yellow', isparam: true } )
      // IFROMTO
      addlink( rec, { source: id, target: id + "->" + pn, isparam: true, isstruct:(pn=="children") } );
    })
  })
}

// добавить все фичи в граф
export function add_all_features( env ) {
  env.on("genobj",(obj,rec, id) => {
    // фичи
    var fa = Object.keys( obj.$features_applied );
    fa.forEach( (pn,index) => {
      if (pn.startsWith("vzf") 
        || pn.startsWith("viewzavr")
        || pn.startsWith("base-url")
        ) return;
      //rec.nodes.push( { id: id + "->" + pn, name: pn } );
      //obj.emit("dbg-add",nodedata); // кстати это гибче..

      addnode( rec, { id: id + " feature " + pn, 
                          name: pn, 
                          label: pn,
                          object_path: id, isfeature: true } )
      // IFROMTO
      addlink( rec, { source: id, 
                      target: id + " feature " + pn, 
                      isfeature: true 
                    } );
    });

    // фичи из доп-списка F-FEAT-PARAMS
    (obj.$feature_list_envs || []).forEach( (fenv,index) => {
      var fid = fenv.getPath();
      gen( fenv, rec, env );

      // IFROMTO
      addlink( rec, { source: id, 
                      target: fid, 
                    } );
    });
  })
}

// нарисоваем все paramRefs
// (заметим ссылки рисуются отдельно)
export function add_all_param_refs( env ) {
  env.on("genobj",(obj,rec, id) => {

  for (var refrecord of obj.getParamRefsRecords()) {
      var refname = refrecord.name;
      let desired_parent = refrecord.desired_parent;
      if (!desired_parent) continue;

      var ref = obj.getParam( refname );
      let [objpath,paramname] = ref ? ref.split("->") : [null,null];
      let tobj = desired_parent.findByPath( objpath );
      if (!tobj) {
        //addnode( rec, { id: id + "->" + pn, name: pn, object_path: id, color: 'yellow', isparam: true } )
        // IFROMTO

        addlink( rec, { source: id, 
                        target: id + "->" + refname,
                        target_obj_path: id,
                        target_param: refname,
                        isparam: true } );
        return;
         // может тут стоило бы поставить хоть ссылочку на то что нет значения..
         //debugger;
      }
      let path = tobj.getPath();

      if (ref) {
        let is_outer = obj.getParamOption( refname,"is_outgoing");

        if (is_outer) // стрелку нарисовать исходящей следует
          addlink( rec, {source:id+"->"+refname, 
                        source_obj_path: id,
                        source_param: refname,
                        target:path + "->" + paramname,
                        target_param: paramname,
                        target_obj_path: path,
                        
                        islink: true});
          else
         addlink( rec, {target:id+"->"+refname, 
                        source:path + "->" + paramname,
                        source_param: paramname,
                        source_obj_path: path,
                        target_obj_path: id,
                        target_param: refname,
                        islink: true});

      };
    };

  });
}


// здесь env это env генератора
function gen( obj,rec, env ) {
  rec ||= create_rec();

  if (Array.isArray(obj)) {
    obj.forEach( (realobj) => gen( realobj, rec, env ));
    return rec;
  }

  var id = obj.getPath();
  
  if (id == "/state") return "";

  let nodedata = { id: id, 
                  name: obj.ns.name, 
                  object_path: id, 
                  isobject: true,
                  color: 'red' };
  //if (obj.$dbg_info) nodedata = {...nodedata, ...obj.$dbg_info};
  // хотя можно было бы и событие у узла вызвать так-то...
  obj.emit("dbg-add",nodedata); // кстати это гибче..

  addnode( rec, nodedata );

  // точка передачи управления доп-алгоритмам
  env.emit("genobj",obj,rec,id);
  
  var ch = obj.ns.getChildNames();
  ch.forEach( function(cname,index) {
      var c = obj.ns.getChildByName( cname );
      var cid = c.getPath();
      
      if (c.historicalType == "link") { // ссылки параметры
        genlink( c,rec );
        
      }
      else {
        gen( c,rec, env );

        var tid = env.params.children_node ? id + "->children" : id;

        addlink( rec, {target: tid,
                       source: cid, 
                       ischild: true, 
                       isstruct: true,
                       target_obj_path: id,
                       source_obj_path: cid
                      })
      }
  });

  // addParamRef + отладить ссылки

  // ссылки из этого объекта на другие объекты addObjRef
  for (var refname of Object.keys( obj.references || {})) {
      var path = obj.getParam( refname );
      var ref = path && path.getPath ? path.getPath() : path; // R-SETREF-OBJ
      if (ref) {
         
         addlink( rec, {target:id+"->"+refname, 
                        source:ref,
                        target_obj_path: id,
                        source_obj_path: ref,
                        target_param: refname,
                        islink: true});
         /* 
         if (obj.getParamOption( refname,"backref" ))
           addlink( rec, {target:id+"->"+refname, source:ref});
         else
          addlink( rec, {source:id, target:ref});

         t += `(${id}) <== (${ref}) : "obj ref TPU"\n`;
         else
         t += `(${id}) ==> (${ref}) : "obj ref TPU"\n`;
         */
      }
  }
  
  return rec;
}

function genlink( obj,rec ) {
      var v = obj.getParam("from");
      if (!v || v.length == 0) return;
      var arr = v.split("->");
      if (arr.length != 2) {
        //console.error("Link: source arr length not 2!",arr );
        return;
      }
      var objname = arr[0];
      var paramname = arr[1];

      var id = obj.getPath();
      var v2 = obj.getParam("to") || "";
      var arr2 = v2.split("->");
      if (arr2.length != 2) return;
      var objname2 = arr2[0]; // КУДА
      var paramname2 = arr2[1];

      // convert to absolute pathes
      if (obj.currentRefFrom && obj.currentRefFrom())
        objname = obj.currentRefFrom().getPath();
      else
        objname=objname + " [UNRESOLVED]";
      if (obj.currentRefTo && obj.currentRefTo())
        objname2 = obj.currentRefTo().getPath();
      else
        objname2=objname2 + " [UNRESOLVED]";

      // ситуация - нет того или иного параметра
      // если нет целевого - его можно прицепить
      // если нет источника - его надо создать и обозначить что его нет
      // но наверное лучше это сделать то ли позже, то ли когда
      // короче отдельно проверим..

      // микрофишка - у нас параметр . означает сам объект - нарисуем стрелку из объекта тогда..
      var source = objname + "->" + paramname;
      if (paramname == ".") source = objname;
      
      //return `(${objname}) ..> (${objname2}) : "link ${paramname} -> ${paramname2} TPU"\n`;
      addlink( rec,   {target: objname2 + "->" + paramname2,
                       source: source,
                       source_obj_path: objname,                       
                       source_param: paramname, 
                       target_obj_path: objname2,
                       target_param: paramname2,
                       islink: true,
                       object_path: id })
}

// починить сгенерированный граф
// а то там не всегда ссылки и объекты совпадают почему-то
// и рисовалка валится от этого
function fixup( obj, rec ) {
  rec.links.forEach( (link) => {
    if (!rec.nodes_table[ link.source ])
    {
      addnode( rec, {id: link.source, problematic: true, 
                     object_path: link.source_obj_path,
                     color: 'yellow',
                     name: link.source_param,
                     isparam: true })
      // todo object-path
      // todo быть может узел объекта добавить или связь с ним

      // если этого параметра еще не было в источнике - ддобавим его
      if (link.source_obj_path && rec.nodes_table[ link.source_obj_path ])
        addlink( rec, { source: link.source_obj_path, target: link.source, isparam: true, noparamrecord: true } );
    }
    if (!rec.nodes_table[ link.target ])
    {
      addnode( rec, {id: link.target, problematic: true, 
                     object_path: link.target_obj_path,
                     name: link.target_param,
                     color: 'yellow',
                     isparam: true })
      // ну может это и не проблема
      // todo object-path

      // если этого параметра еще не было в приемнике - ддобавим его
      if (link.target_obj_path && rec.nodes_table[ link.target_obj_path ])
        addlink( rec, { source: link.target_obj_path, target: link.target, isparam: true, noparamrecord: true } );
    }
  })
}

// было предыдущее состояние prevrec, есть новое newrec
// цель - преобразовать prevrec так чтобы оно отражало newrec 
// но при этом сохранило свойства графа из prevrec
function merge( prevrec, newrec ) {

  if (!prevrec.nodes_table) {
      newrec.has_changed = true;
      return newrec; 
      // если в старом нет наших таблиц - берем тупо новое
      // потому что оно значит совсем куку, дефолтное  какое-то
  }

  // https://bl.ocks.org/vasturiano/2f602ea6c51c664c29ec56cbe2d6a5f6

  // создадим новое из старого, но только то что не удалено
  var rec = create_rec();
  prevrec.nodes.forEach( node => {
    if (newrec.nodes_table[ node.table_key ]) 
        addnode( rec, node );
      else rec.has_changed = true;
  })
  prevrec.links.forEach( node => {
    if (newrec.links_table[ node.table_key ]) 
        addlink( rec, node );
      else rec.has_changed = true;
  })

  // добавим то что появилось в новом сверху
  newrec.nodes.forEach( node => {
    if (!prevrec.nodes_table[ node.table_key ]) {
      addnode( rec,node );
      rec.has_changed = true;
    }
  } )
  newrec.links.forEach( node => {
    if (!prevrec.links_table[ node.table_key ]) {
      addlink( rec,node );
      rec.has_changed = true;
    }
  } )

  return rec;
}

// задача сделать граф (сгенерировать структуру данных)
export function scene_explorer_graph( env ) {

  var stop_process = ()=>{};

  env.addFloat( "update_interval", 500 );

  //if (!env.params.update_interval) env.params.update_interval = 500;

  if (!env.hasParam("active")) env.params.active=true;

  env.onvalues(["input","update_interval"],(obj) => {
    stop_process()
    // запускаем процесс генерации
    var interv;

    //if (env.params.active) // это есть тело фичи active
    interv = setInterval( 
        () => perform_generate( obj ),
        env.params.update_interval
    );
    /*
       по идее : active => regenerate_by_timer, т.е. как-то так это должно быть
        а не то что я тут вписываюсь в коды прямо
    */

    stop_process = () => { if (interv) clearInterval( interv ); }

    perform_generate( obj );
  });
  env.on("remove",stop_process);

  function perform_generate( root_obj ) {
    if (!env.params.active) return; // чет решил сюды воткнуть

    console.log("REGENERATING GRAPH")
    var res = gen( root_obj, null, env );
    fixup( root_obj, res);
    env.setParam("output",res )    
  }

  if (!env.params.input) {
    setTimeout( () => {
      if (!env.params.input)
        env.setParam("input", env.findRoot() )
    },100 )
  }

/*
  function gen( obj ) {
    // Create Random tree
      const N = 2000;
    const gData = {
      nodes: [...Array(N).keys()].map(i => ({ id: i })),
      links: [...Array(N).keys()]
        .filter(id => id)
        .map(id => ({
          source: id,
          target: Math.round(Math.random() * (id-1)),
          color: id % 2
        }))
    };
    return gData;
    
  }
*/  
}

export function scene_explorer_3d( env ) {
  /*
  env.feature("dom");
  env.onvalue("output",(dom) => setup( dom ));
  */  
  // пусть на вход собственно граф и идет, а эта штука будет ево рисовать
  /*
  env.onvalue("input",(gdata) => {
    setup( null, gdata );
  })
  */

  //setup();

  // возможность постановки на паузу
  env.onvalues(["active","graph"],(active,graph) => {
    if (active) {
        graph.resumeAnimation();
        //console.log("GRAPH RESUMED");
      }
      else {
        graph.pauseAnimation();
        //console.log("GRAPH PAUSED");
      }
  })

  ///////////////////////////////////////  
  var unsub_target=()=>{};
  env.onvalue("target",(target) => {
    unsub_target();
    // тут еще пока вопросы, на что подписываться - на output (и там ф-я) или на dom (но это типа внутреннее же)
    unsub_target = target.onvalue("dom",(dom) => {
      //var dom = target?.params?.output || dom;
      
      if (dom.apply) dom=dom(); // там может быть функция сидит
      env.setParam("target_dom",dom); // это будет использоваться всяким orbit-control кроме всего
    });
  });
  env.on("remove",unsub_target);

  let update_once = false;
  env.addCmd("refresh",() => { 

    update_once=true 
  })

  env.addCheckbox("update_every_beat",false);

  var graph;
  env.onvalues(["input","target_dom"],(gdata,dom) => {
    graph = create_graph( dom, graph );

    env.setParam("graph",graph); // точка прицепления различных фич

    var exisiting_gdata = graph.graphData();
    var newgdata = merge( exisiting_gdata, gdata );

    if (env.params.update_every_beat)
    {}
    else {
      if (update_once)
      {
         update_once = false;
      }
      else
      if (!newgdata.has_changed) 
         return;
    }

    env.setParam("gdata",newgdata); // новые данные тут

    graph.graphData( newgdata );
  });

  env.on("remove", () => graph ? graph.cleanup() : 0 )

  function create_graph( dom,existing_graph ) {
// короче какая-то ерунда с привязкой к нашему dom, пусть пока будет базовый дом
    //dom = threejs.renderer.domElement.parentElement;
    //threejs.sceneControl.dispose()
    //dom = document.getElementById("qmlSpace");  

    if (dom?.apply) dom = dom();
    if (existing_graph?.attached_to_dom == dom) return existing_graph;
    if (!dom) return;

    // Create Random tree
    /*
    const N = 2;
    const gData = {
      nodes: [...Array(N).keys()].map(i => ({ id: i })),
      links: [...Array(N).keys()]
        .filter(id => id)
        .map(id => ({
          source: id,
          target: Math.round(Math.random() * (id-1)),
          color: id % 2
        }))
    };

    var dat = input || gData;
    */

    const graph = ForceGraph3D()(dom)
        .nodeLabel(node => node.id)
        .linkColor(link => link.islink ? 'purple' : ( link.ischild ? 'red' : (link.color || 'green') ))
        //.linkColor(link => link.islink ? 'purple' : ( link.ischild ? 'green' : 'red' ))
        .linkOpacity(1)
        //.linkCurvature( link => link.islink ? 0.2 : 0 )
        .linkCurvature( 0.2 )
        .linkWidth(link => link.islink ? 2 : 0 ) // 2 : 1 красиво но медленно
        .linkDirectionalArrowLength(link => link.islink ? 13.5 : 0 )
        //.linkDirectionalArrowRelPos(1)
         //.linkDirectionalArrowLength(13.5)
        .linkDirectionalArrowRelPos(1)
        //.nodeColor( (node) => node.isobject ? 'red' : (node.isfeature ? undefined : 'yellow'))
        .nodeAutoColorBy( 'name' )
        //.nodeOpacity( node => 0.5 )
        .nodeVal( (node) => {
          /*
           if (node.object_path == env.params.current_object_path) {
              debugger;
              return 100;
           }
           */
           return node.isfeature ? 10 : 1 
         }
        )
        //.nodeLabel('id')
        .nodeLabel( node => node.label || node.id)
        .onNodeClick(node => {

          // фича "фиксировать узел при клике на нево"
          // а то к нему начинают цепляться стрелочки от других
          node.fx = node.x;
          node.fy = node.y;
          node.fz = node.z;

          console.log("clicked node",node );
          env.setParam("current_object_path", node.object_path );

          var obj = env.findByPath( node.object_path );
          console.log("object is",obj);
          console.log("object params are ",obj?.$vz_params);

          // особая штука чтобы обновить раскраску
          //graph.nodeColor(graph.nodeColor())
          //graph.nodeVal(graph.nodeVal());
        })
        .onLinkClick(node => {

          console.log("clicked link",node );
          env.setParam("current_object_path", node.object_path );

          var obj = env.findByPath( node.object_path );
          console.log("object is",obj);
          console.log("object params are ",obj?.$vz_params);
        });
        
    const linkForce = graph
      .d3Force('link')
      //.distance(link => link.islink ? 10 : 0.1 );
      //.distance(link => link.islink ? 1 : 10 );
      .distance(link => link.islink ? 10 : (link.isstruct ? 0.5 : 0.1) );


    var installed_w, installed_h;
    function update_wh() {
      if (dom.clientWidth != installed_w || dom.clientHeight != installed_h) {
        installed_w = dom.clientWidth;
        installed_h = dom.clientHeight;
        
        graph.width( installed_w );
        graph.height( installed_h );

        graph.controls().handleResize(); // а то оно тупит без сего
      }
    }

    var whitnerval;
    setTimeout( () => {
      whitnerval = setInterval( update_wh, 100 );
    }, 1000 );

    

    graph.cleanup = () => {
      clearInterval( whitnerval );
      //graph.dispose();
      graph._destructor();
    }

    graph.attached_to_dom = dom;

    return graph;
  }

}




// https://github.com/vasturiano/3d-force-graph#input-json-syntax
// пляся от корня заданного obj, генерить согласно описанию
function gen0( obj,rec ) {
  rec ||= create_rec();

  var id = obj.getPath();
  
  if (id == "/state") return "";

  //rec.nodes.push( { id: id, name: id } );
  addnode( rec, { id: id, name: id, object_path: id, isobject: true } )

  // параметры все
  var params = obj.getParamsNames();
  if (!obj.params.hasOwnProperty("children")) params = params.concat( ["children"] );

  //params=["children"];
  //params=[];
  params.forEach( (pn,index) => {
    //rec.nodes.push( { id: id + "->" + pn, name: pn } );
    addnode( rec, { id: id + "->" + pn, name: pn, object_path: id } )
    // IFROMTO
    addlink( rec, { source: id, target: id + "->" + pn, isparam: true, isstruct:(pn=="children") } );
  })
  
  var ch = obj.ns.getChildNames();
  ch.forEach( function(cname,index) {
      var c = obj.ns.getChildByName( cname );
      var cid = c.getPath();
      
      if (c.historicalType == "link") { // ссылки параметры
        genlink( c,rec );
        
      }
      else {
        gen( c,rec );

        addlink( rec, {target:id+"->children",
                       source: cid, 
                       ischild: true, 
                       isstruct: true,
                       target_obj_path: id
                      })
      }
  });
  

  // ссылки объектов
  /*
  for (var refname of Object.keys( obj.references || {})) {
      var path = obj.getParam( refname );
      var ref = path && path.getPath ? path.getPath() : path; // R-SETREF-OBJ
      if (ref) {
         if (obj.getParamOption( refname,"backref" ))
         t += `(${id}) <== (${ref}) : "obj ref TPU"\n`;
         else
         t += `(${id}) ==> (${ref}) : "obj ref TPU"\n`;
      }
  }
  */
  
  /*
  // неведомое
  if (obj.extraTpus) {
    var extras = obj.extraTpus();
    for (var e of Object.keys(extras)) {
      var ecomment = extras[e];
      if (typeof(ecomment) !== "string") ecomment = "";
      t += `(${id}) ==> (${e}) : "${ecomment}"\n`;
    }
  }
  if (obj.extraTpusBack) {
    var extras = obj.extraTpusBack();
    for (var e of Object.keys(extras)) {
      var ecomment = extras[e];
      if (typeof(ecomment) !== "string") ecomment = "";
      t += `(${id}) <== (${e}) : "${ecomment}"\n`;
    }
  }
  */  
  
  return rec;
}