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

// https://github.com/vasturiano/3d-force-graph#input-json-syntax
// пляся от корня заданного obj, генерить согласно описанию
function gen( obj,rec ) {
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
      
      //return `(${objname}) ..> (${objname2}) : "link ${paramname} -> ${paramname2} TPU"\n`;
      addlink( rec,   {target: objname2 + "->" + paramname2,
                       source: objname + "->" + paramname,
                       source_obj_path: objname,                       
                       source_param: paramname, 
                       target_obj_path: objname2,
                       target_param: paramname2,
                       islink: true,
                       object_path: id })
}

function fixup( obj, rec ) {
  rec.links.forEach( (link) => {
    if (!rec.nodes_table[ link.source ])
    {
      addnode( rec, {id: link.source, problematic: true, object_path: link.source_obj_path })
      // todo object-path
      // todo быть может узел объекта добавить или связь с ним

      // если этого параметра еще не было в источнике - ддобавим его
      if (link.source_obj_path && rec.nodes_table[ link.source_obj_path ])
        addlink( rec, { source: link.source_obj_path, target: link.source, isparam: true, noparamrecord: true } );
    }
    if (!rec.nodes_table[ link.target ])
    {
      addnode( rec, {id: link.target, problematic: true, object_path: link.target_obj_path })
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

  if (!prevrec.nodes_table) return newrec; // если в старом нет наших таблиц - берем тупо новое

  // https://bl.ocks.org/vasturiano/2f602ea6c51c664c29ec56cbe2d6a5f6

  // создадим новое из старого, но только то что не удалено
  var rec = create_rec();
  prevrec.nodes.forEach( node => {
    if (newrec.nodes_table[ node.table_key ]) 
        addnode( rec, node );
  })
  prevrec.links.forEach( node => {
    if (newrec.links_table[ node.table_key ]) 
        addlink( rec, node );
  })

  // добавим то что появилось в новом сверху
  newrec.nodes.forEach( node => {
    if (!prevrec.nodes_table[ node.table_key ]) {
      addnode( rec,node );
    }
  } )
  newrec.links.forEach( node => {
    if (!prevrec.links_table[ node.table_key ]) {
      addlink( rec,node );
    }
  } )

  return rec;
}

// задача сделать граф
export function scene_explorer_graph( env ) {

  var stop_process = ()=>{};
  env.onvalue("input",(obj) => {
    // запускаем процесс генерации
    var interv = setInterval( () => perform_generate( obj ), 5000 );
    stop_process = () => clearInterval( interv );
  });
  env.on("remove",stop_process);

  function perform_generate( root_obj ) {
    var res = gen( root_obj );
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

  var graph;
  env.onvalues(["input","target_dom"],(gdata,dom) => {
    graph = create_graph( dom, graph );

    env.setParam("graph",graph); // точка прицепления различных фич

    var exisiting_gdata = graph.graphData();
    var newgdata = merge( exisiting_gdata, gdata );

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
        .linkColor(link => link.islink ? 'purple' : ( link.ischild ? 'red' : 'green' ))
        .linkOpacity(1)
        //.linkCurvature( link => link.islink ? 0.2 : 0 )
        .linkCurvature( 0.2 )
        .linkWidth(link => link.islink ? 2 : 0 ) // 2 : 1 красиво но медленно
        .linkDirectionalArrowLength(link => link.islink ? 13.5 : 0 )
        //.linkDirectionalArrowRelPos(1)
         //.linkDirectionalArrowLength(13.5)
        .linkDirectionalArrowRelPos(1)
        .nodeColor( (node) => node.isobject ? 'red' : 'yellow')
        .nodeVal( (node) => node.isobject ? 10 : 1 )
        .nodeLabel('id')
        .onNodeClick(node => {
          console.log("clicked node",node );
          env.setParam("current_object_path", node.object_path );

          var obj = env.findByPath( node.object_path );
          console.log("object is",obj);
          console.log("object params are ",obj?.$vz_params);
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
      .distance(link => link.islink ? 1 : 10 );
      //.distance(link => link.islink ? 10 : (link.isstruct ? 0.1 : 1) );


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

