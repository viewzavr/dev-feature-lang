/*
https://github.com/kieler/elkjs
https://github.com/eclipse/sprotty
https://rtsys.informatik.uni-kiel.de/elklive/json.html
*/

export function setup( vz, m ) {
  vz.register_feature_set( m );
}

export function dump2elk( env )
{
  env.onvalue ("input",(i) => {
    let res = gen( i );
    res.layoutOptions = { 'algorithm': 'layered' };
    //res = JSON.stringify( res,null," " )
    res = JSON.stringify( res )
    env.setParam("output",res)
  })
}

// по мотивам https://github.com/viewzavr/viewzavr-system-a/blob/main/player/vz-comps/export-plantuml.js

function mkport( name, parent_path ) {
  let lab = (name == "input" ? "in" : name == "output" ? "out" : name)
  let t = { id: parent_path + "->" + name, width: 8, height: 8, labels: [ { text: lab, width: (lab.length*5) }] }
  return t
}

function add_id( objdump, parent_path="root" ) {
  let id = parent_path + "/" + objdump.$name;
  objdump.$elk_id = id;
  Object.values( objdump.children ).forEach( v => add_id( v, id ))
  Object.values( objdump.features_list ).forEach( v => add_id( v, id ))
}

function add_ports_if_needed( path, objdump )
{
  function find_root( objdump )
  {
    if (objdump.$elk_parent_objdump) return find_root( objdump.$elk_parent_objdump )
      return objdump
  }
  let root = find_root( objdump );

  function findobj( objid, rootdump ) {
    //console.log("findobj: comparing",rootdump.$elk_id,objid)
    if (rootdump.$elk_id == objid) {
      //console.warn("OK")
      return rootdump;
    }
    let cc = Object.values( rootdump.children || {} ).concat( Object.values( rootdump.features_list || {} ) );
    for (let i=0; i<cc.length; i++) {
       let r = findobj( objid, cc[i] ) 
       if (r) return r
    }
    //cc.forEach( c => findobj( objid, c ))
  }

  let k = path.split("->");
  let objpath = k[0]
  let pname = k[1]
  let obj = findobj( objpath, root )

  if (obj) {    
    if (pname) {
      let existing_port = obj.$elk.ports.find((x) => x.id == path)
        if (!existing_port) {
          //console.warn("add_ports_if_needed: port not found, adding", path, pname)
          obj.$elk.ports.push( mkport( pname,obj.$elk_id ) )
        }
    }  
  }
  else
  {
    console.error(" add_ports_if_needed: obj not found", objpath, "path",path)
  }
}


// задача найти в elk-описании ссылки на @ и поменять их на пути
function fix_links( objdump ) {
  //console.log('fix-lnks called',objdump.$elk.edges)

  objdump.$elk.edges.forEach( edge => {
    //console.log('checking edge',edge)
    check_path( edge.sources[0], (newval) => {
      edge.sources[0] = newval;
    })
    check_path( edge.targets[0], (newval) => {
      edge.targets[0] = newval;
    })
    add_ports_if_needed( edge.sources[0],objdump )
    add_ports_if_needed( edge.targets[0],objdump )
  });
  
  let cc = Object.values( objdump.children || {} ).concat( Object.values( objdump.features_list || {} ) );
  //console.log( cc,cc.forEach, typeof(cc),typeof(objdump.children),"qq=",objdump.children )
  //console.log(typeof(Object.values( objdump.children )), typeof(objdump.features_list) )
  //console.log(Object.values( objdump.children ), objdump.features_list )
  //console.log("CCCCCCCCCCcc",Array.isArray(Object.values( objdump.children ).concat( Object.values( objdump.features_list ))), cc.forEach)
  cc.forEach( fix_links )

  // на вход берет значение ссылки на выход вызывает cb если есть замена
  function check_path( value, cb ) {
    if (value[0] == "@") {
      //console.warn("check_path",value)
      let objname = value.split("->")[0].substring(1)
      let fo = find_obj( objname )
      if (fo) {
        if (value.endsWith("->."))
          //cb( fo ) // на объект ссылка.. (заодно и для let) - стало быть прямое оставим
          cb( value.replace("@" + objname, fo))
        else
          cb( value.replace("@" + objname, fo))
      }
    }
  }

  // вход - имя объекта (с убранной @)
  // выход - найденный путь объекта
  function find_obj( name ) {
    //console.warn( "find_obj",name)
    let res = go_obj( name, objdump, null, true )
    //console.log("found:",res)
    return res
  }

  function go_obj( name, objdump, except, allow_go_to_parent ) {
    //console.log("comparing", objdump.$name, name)
    if (objdump.$name == name) {
       return objdump.$elk_id
    }  
    //let cc = Object.values( objdump.children ) + Object.values( objdump.features_list );
    let cc = Object.values( objdump.children || {} ).concat( Object.values( objdump.features_list || {} ) );
    let found
    cc.find( c => {
      if (c === except) return
      let cr = go_obj( name, c )
      if (cr) { found = cr; return cr }
    })
    if (found) return found

    // надо еще в летах искать
    // это сработает т.к. мы порты уже пропихнули
    if (objdump.features.let) {
      let found_port = objdump.$elk.ports.find( p => {
        let pname = p.id.split("->")[1]
        if (pname == name)
          return true
      })
      if (found_port) {
          //console.warn("found port is",found_port, "returnriong",found_port.id)

          return found_port.id
      }
    }

    if (objdump.$elk_parent_objdump && allow_go_to_parent)
      return go_obj( name,objdump.$elk_parent_objdump, objdump, true )
  }
}

function gen( objdump, parent_path="", parent_object, is_hosted ) {
  if (Array.isArray(objdump)) {
    //let t = { id: parent_path, children: objdump.map( r => gen(r) ) }
    let children = {}
    objdump.forEach( r => children[r.$name] = r)
    let newobjdump = { $name: "root", children: children, features:[], features_list:[], links:[], params: {} }
    let res = gen( newobjdump, "" )
    fix_links( newobjdump )
    return res
  }

  let id = parent_path + "/" + objdump.$name;
  objdump.$elk_id = id;

  let fts = Object.keys( objdump.features ).filter( n => n!="base_url_tracing")
  let objname = objdump.name_is_autogenerated ? "" : objdump.$name + ": " ;
  let objtitle = objname + fts.join(",")

  /* добавить аргументов что ли.. статичных ххотяб
  */
  for (let i=0; i<objdump.params.args_count; i++) {
    if (!objdump.params[i]) continue;
    objtitle += " " + i + "=" + JSON.stringify( objdump.params[i] ) 
    //objtitle += i.toString() + "=" + objdump.params[i]
  }

  let w  = objtitle.length * 10;
  //var t = { id: id, width: w, height: 30, labels:[], ports: [ mkport("input",id), mkport("output",id)], children: [], edges: [] };
  var t = { id: id, width: w, height: 30, labels:[], ports: [], children: [], edges: [] };

  t.labels.push( {text: objtitle } )

  objdump.$elk = t
  objdump.$elk_parent_objdump = parent_object

  //t.labels.push( {text: fts.join(",") })

  var ch = Object.keys( objdump.children || {} );
  ch.forEach( function(cname,index) {
      var c = objdump.children[ cname ];
      //var cid = id + "/" + cname;
      
      if (c.historicalType == "link") { // ссылки параметры
        //t.edges.push( genlink( c ) );
      }
      else {
        //if (id != "/") // уберем ссылку от корня
        //t += `(${id}) ..> (${cid})\n`; // связь родитель-ребенок.. 
        //t += gen( c, id );
        t.children.push( gen( c,id, objdump ) )
      }
  });

  var ch2 = Object.keys( objdump.features_list || {} );
  let counter = 0;
  ch2.forEach( function(cname,index) {
      let c = objdump.features_list[ cname ];
      let cid = id + "/" + cname + "_" + (counter++);
      c.$name = cid; // потому что там у них чухня написана дублирующаяся
      
      if (c.historicalType == "link") { // ссылки параметры
        t.edges.push( genlink( c ), objdump, is_hosted ? parent_object : objdump, parent_object );
      }
      else {
        t.children.push( gen( c,id, objdump, true ) )
      }
  });  

  for (var refname of Object.keys( objdump.links || {})) {
    //t += genlink( objdump.links[ refname ] )
    //t.edges.push( genlink( objdump.links[ refname ] ) )
    add_edge( genlink( objdump.links[ refname ], objdump, is_hosted ? parent_object : objdump, parent_object ) )
  }

  ///////////////////// пайпа

  if (objdump.features.pipe) {
    let q = Object.values( objdump.children || {} );
    for (let i=0; i<q.length-1; i++) 
      add_edge( { sources: [q[i].$elk_id + "->output"], targets:[q[i+1].$elk_id + "->input"] })
    // мне кажется это можно опустить
    //add_edge( { sources: [id + "->input"], targets: [q[0].$elk_id + "->input"]})
    //add_edge( { targets: [id + "->output"], sources: [q[q.length-1].$elk_id + "->output"]})
    add_edge( genlink( { from: q[q.length-1].$elk_id + "->output", to: id + "->output"}, objdump, is_hosted ? parent_object : objdump, parent_object ) )
  }

  ///////////////////// ()-вычисление

  if (objdump.features.computer) {
    let q = Object.values( objdump.children || {} );
    //add_edge( { targets: [id + "->output"], sources: [q[0].$elk_id + "->output"]})
    add_edge( genlink( { from:q[0].$elk_id + "->output", to:id + "->output"}, objdump, is_hosted ? parent_object : objdump, parent_object) )
  }

  function add_edge( edge ) {
     let edge_id = id + ":edge_" + t.edges.length
     edge.id = edge_id
     t.edges.push( edge )
  }
  
  return t;
}

// генерирует ссылку по описанию + добавляет порт в целевой объект если его еще нет
function genlink( objdump, parent_object, host_object, parent_parent_object ) {
  function repl1( path, pattern, object ) {
    if (path.indexOf( pattern ) >= 0) {
      path = path.replace( pattern,object.$elk_id + "->" )
      // следующее можно оставить на глобальную стадию
      let k = path.split( "->")
      let pname = k[1]
      let desired_id = object.$elk_id + "->" + pname;
      let existing_port = object.$elk.ports.find((x) => x.id == path)
      if (!existing_port) {
        //console.warn("port not found, adding", path)
        object.$elk.ports.push( mkport( pname,object.$elk_id ) )
      }
    }
    //return path.replace( "..->",parent_parent_object.$elk_id + "->" ).replace( ".->",host_object.$elk_id + "->").replace( "~->", parent_object.$elk_id + "->" )
    return path
  }
  function repl( path ) {
    let a = repl1( path, "..->",parent_parent_object );
    let b = repl1( a, ".->",host_object );
    let c = repl1( b, "~->",parent_object );
    return c
  }

  let t = { sources: [repl( objdump.from )],targets: [repl( objdump.to )] }

  // вот тут говорят - мы ссылаемся на объект такой-то, например target, параметр такой-то.
  // а порт там не определен..
  // стало быть надо его добавить. либо отказаться.
  // попробуем добавить

  return t
}

function genlink1( objdump, parent_object, host_object, parent_parent_object ) {
  function repl( path ) {
    return path.replace( "..->",parent_parent_object.$elk_id + "->" ).replace( ".->",host_object.$elk_id + "->").replace( "~->", parent_object.$elk_id + "->" )
  }

  let t = { sources: [repl( objdump.from )],targets: [repl( objdump.to )] }

  // вот тут говорят - мы ссылаемся на объект такой-то, например target, параметр такой-то.
  // а порт там не определен..
  // стало быть надо его добавить. либо отказаться.
  // попробуем добавить

  return t
}

function genlink0( objdump, parent_path="" ) {
      var v = objdump.from;
      if (!v || v.length == 0) return;
      var arr = v.split("->");
      if (arr.length != 2) {
        //console.error("Link: source arr length not 2!",arr );
        return;
      }
      var objname = arr[0];
      var paramname = arr[1];
      
      var id = parent_path;
      var v2 = objdump.to || "";
      var arr2 = v2.split("->");
      if (arr2.length != 2) return;
      var objname2 = arr2[0]; // КУДА
      var paramname2 = arr2[1];

      // конфликты имен.. (они локальные)
      
      //return `(${objname}) ..> (${objname2}) : "link ${paramname} -> ${paramname2} TPU"\n`;
      return { sources: [objname], targets:[ objname2] }
}

////////////////////////////////////////// https://plantuml.com/ru/code-javascript-synchronous
  function tohex(str) {
    var result = '';
    for (var i=0; i<str.length; i++) {
      var r = str.charCodeAt(i).toString(16);
      //r = ("000"+r).slice(-4);
      r = ("0"+r).slice(-2);
      if (r.length != 2) 
        debugger;
      result += r;
    }
    return result;
  }

