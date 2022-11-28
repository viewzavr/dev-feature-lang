export function setup( vz, m ) {
  vz.register_feature_set( m );
}

export function dump2uml( env )
{
  env.onvalue ("input",(i) => {
    let res = gen( i );
    env.setParam("output",res)
  })
}

export function uml_url( env ) {
  env.onvalue ("input",(i) => {
    let res = tohex( i );
    res = `https://www.plantuml.com/plantuml/uml/~h${res}`
    env.setParam("output",res)
  })
  
}

// по мотивам https://github.com/viewzavr/viewzavr-system-a/blob/main/player/vz-comps/export-plantuml.js

function gen( objdump, parent_path="" ) {
  if (Array.isArray(objdump))
    return objdump.map( r => gen(r) ).join("\n")

  let id = parent_path + "/" + objdump.$name;

  var t = `(${id})\n`;
  var ch = Object.keys( objdump.children || {} );
  ch.forEach( function(cname,index) {
      var c = objdump.children[ cname ];
      var cid = id + "/" + cname;
      
      if (c.historicalType == "link") { // ссылки параметры
        t += genlink( c );
      }
      else {
        //if (id != "/") // уберем ссылку от корня
        t += `(${id}) ..> (${cid})\n`; // связь родитель-ребенок.. 
        t += gen( c, id );
      }
  });

  for (var refname of Object.keys( objdump.links || {})) {
    t += genlink( objdump.links[ refname ] )
  }
  
  return t;
}

function genlink( objdump, parent_path="" ) {
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
      
      return `(${objname}) ..> (${objname2}) : "link ${paramname} -> ${paramname2} TPU"\n`;
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

