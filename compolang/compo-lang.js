// фича parseSimpleLang и базовые фичи языка load, loadPackage, pipe, register_feature

export function setup(vz, m) {
  vz.register_feature_set(m);
}

import * as P from "./lang-parser.js";
export function simple_lang(env) 
{
  env.parseSimpleLang = function( code, opts={} ) {
    try {
      var parsed = P.parse( code, { vz: env.vz, parent: (opts.parent || env), base_url:opts.base_url } );
      var dump = parsed2dump( env.vz, parsed, opts.base_url || "" );
      return env.restoreFromDump( dump );
    }
    catch (e) 
    {
      console.error(e);
      if (typeof e.format === "function")
          console.log( e.format( [{text:code}] ));
    }
  }
  env.compalang = env.parseSimpleLang;
}

// преобразовать результат парсинга во вьюзавр-дамп
function parsed2dump( vz, parsed, base_url ) {
/* они почти похожи.
   надо обработать массив link - привести к объектам
   и пока во вьюзавре есть типы обработать type
*/
  // links
  /* я думал links запихать в объекты. но у нас функторы - они не активируют детей напрямую.
     поэтому links на этапе restore надо обрабатывать отдельно.
  for (var lname of Object.keys(parsed.links)) {
    var lrec = parsed.links[lname];
    var newlinkobj = { type: "link", params: {...lrec.params,tied_to_parent: true} }
    while (parsed.children[ lname ]) lname=lname+"y";
    parsed.children[ lname ] = newlinkobj;
  }
  */
  // type
  if (Object.keys( parsed.features ).length > 0) {
    var first_feature_name = Object.keys( parsed.features )[0];
    var first_feature_code = first_feature_name;
    //var first_feature = parsed.features[  ]
    if (vz.getTypeInfo(first_feature_code))
      parsed.type = first_feature_code;
  }
  for (let c of Object.keys(parsed.children)) {
    let cc = parsed.children[c];
    parsed2dump( vz, cc, base_url );
  }
  parsed.forcecreate = true;
  parsed.features[ "base_url_tracing" ] = {params: {base_url}};
  //feature("base_url_tracing",{base_url});
  return parsed;
}

var compolang_modules = {};
// короче решено все делать через load и пусть она разбирается что там.
// а то уже взрыв мозга, что загружать, package или combolang.
export function load(env,opts) 
{
  env.feature("simple-lang");
  //env.parsed_alive = false;
  //env.finalize_parse = () => { current_parent = parents_stack.pop() };

  env.trackParam("files",(files) => {
    console.log("load: gonna load files",files)
    if (!files) return;
    files.split(/\s+/).map( loadfile )
  });

  env.signalParam("files");

  function loadfile(file) {
     if (!file) return;

     if (file.endsWith( ".js")) {
       var file2 = env.compute_path( file );
       console.log("loading package",file,"=>",file2);
       return vzPlayer.loadPackage( file2 )
     }
     if (vzPlayer.getPackageByCode(file)) {
       return vzPlayer.loadPackage( file )
     }     

     if (compolang_modules[file])
      file = compolang_modules[file];
     else
      file = env.compute_path( file );

     let new_base_url = env.vz.getDir( file );
     console.log("load: loading",file)
     fetch( file ).then( (res) => res.text() ).then( (txt) => {
       // нужна sub-env для отслеживания base-url
       var subenv = env.create_obj( {} );
       subenv.feature("simple-lang");
       subenv.parseSimpleLang( txt, {vz: env.vz, parent: env.ns.parent,base_url: new_base_url} );
       // было
       //subenv.parseSimpleLang( txt, {vz: env.vz, parent: env.ns.parent,base_url: new_base_url} );
     });
  }
}

export function register_compolang(env,opts) {
  env.onvalue("url",(url) => {
    if (!env.params.name)
    {
      console.error("COMPOLANG PACKAGE WITHOUT NAME CANNOT BE REGISTERED",code);
      return;
    }
    var code = env.params.name;
    var url = env.compute_path(url);
    compolang_modules[code] = url;
  });

  env.on("parsed",() => {
    env.remove();
  })
}

export function do_register_compolang( name,url ) 
{
  compolang_modules[code] = url;
}

export function register_compolang_func( env ) 
{
  env.register_compalang = (code,url) => {
    compolang_modules[code] = url;
  }
}

export function load_package(env,opts) 
{
  env.parsed_alive = false;
  env.trackParam("files",(files) => {
    console.log("load_package: gonna load files",files)
    if (!files) return;
    files.split(/\s+/).map( loadfile )
  })
  env.signalParam("files");

  function loadfile(file) {
    if (file.indexOf(".js") > 0) // это файл
        file = env.compute_path( file );
    // а иначе это похоже package-specifier (айди в таблице)

    console.log("load_package: loading",file);

    return vzPlayer.loadPackage( file );
  }
}

// потребность: удобный метод построения цепочек вычислений
// pipe { c1; c2; c3; }
// соединяет "детей" так: c2.input = @c1->output; c3.input = @c2->output
// открытый вопрос: куда идет output c3 ? это pipe.output = @c3->output ?
// кстати интересная идея от Кости - linestrips output это 3d object..
//import {delayed} from "viewzavr/utils.js";
export function pipe(env,opts) 
{
  // var delayed = require("delayed");
  env.feature("delayed");
  var delayed_chain_children = env.delayed(chain_children)
  env.on('appendChild',delayed_chain_children);

  function chain_children() {
      let cprev;
      let cfirst;
      
      for (let c of env.ns.getChildren()) {
         if (c.is_link) continue;
         if (!cfirst) cfirst = c;
         // пропускаем ссылки.. вообще странное решение конечно.. сделать ссылки объектами
         // и потом об них спотыкаться
         if (cprev) {
           c.linkParam("input",`../${cprev.ns.name}->output`); // вообще странно все это
         }
         cprev = c;
      }
      // output последнего ставим как output всей цепочки
      if (cprev)
          env.linkParam("output",`${cprev.ns.name}->output`)
      else
          env.linkParam("output",``)
      // input первого ставим на инпут пайпы
      if (cfirst) {
          if (!cfirst.hasLinksToParam("input") && !cfirst.hasParam("input"))
            cfirst.linkParam("input",`..->input`)
      }
  }
}

// регистрирует фичу name, code где code это код тела функции на яваскрипте
export function register_feature( env, fopts, envopts ) {
  var children = {};
  env.restoreFromDump = (dump,manualParamsMode) => {
    env.vz.restoreParams( dump, env,manualParamsMode );
    env.vz.restoreLinks( dump, env,manualParamsMode );
    env.vz.restoreFeatures( dump, env,manualParamsMode );
    children = dump.children;
    compile();
    return Promise.resolve("success");
  }
  
  var apply_feature = () => {};

/*
  env.onvalue("name",() => {
    env.vz.register_feature( env.params.name, (e,...args) => {
      apply_feature(e,...args)
    } );
  });
*/  

  function compile() {
    if (!env.params.name) {
      console.error("RESIGTER-FEATURE: feature have no name.")
      return;
    }

    var js_part = () => {};
    if (env.params.code) {
      var code = "(env,args) => { " + env.params.code + "}";
      try {
        js_part = eval( code );
      } catch(err) {
        console.error("REGISTER-FEATURE: error while compiling js!",err,"\n********* code=",code);
      }
    }
    var compalang_part = () => {};
    if (Object.keys( children ).length > 0) {
      var firstc = Object.keys( children )[0];
      compalang_part = (tenv) => {
        var edump = children[firstc];
        edump.keepExistingChildren = true; // смехопанорама
        edump.keepExistingParams = true;
        tenv.restoreFromDump( edump );
        //tenv.vz.createChildrenByDump( dump, obj, manualParamsMode );
      }
    }

    apply_feature = (e,...args) => {
      js_part( e,...args);
      compalang_part( e,...args);
    }

    env.vz.register_feature( env.params.name, (e,...args) => {
      apply_feature(e,...args)
    } );
  }

  //env.onvalue("code",compile );

  env.on("parsed",() => {
    env.remove();
  })
}



// регистрирует пакет name,url
export function register_package( env ) {
  env.onvalue("url",(url) => {
    if (!env.params.name)
    {
      console.error("PACKAGE WITHOUT NAME CANNOT BE REGISTERED",code);
      return;
    }
    var code = env.params.name;
    var url = env.compute_path(url);
    vzPlayer.addPackage( {code,url});
  });

  env.on("parsed",() => {
    env.remove();
  })
}

//////////////////////

function add_dir_if( path, dir ) {
  if (path[0] == "/") return path;
  if (path.match(/\w+\:\/\//)) return path;
  if (path[0] == "." && path[1] == "/") path = path.substring( 2 );
  if (path.trim() == "") return null; // if blank path specified, that means no data should be displayed. F-BLANK
  return dir + path;
}

export function base_url_tracing( env, opts ) 
{
  env.$base_url = opts.base_url;
  env.compute_path = (file) => {
    //if (Array.isArray(file))
    if (typeof(file) === "string")
      return add_dir_if( file, env.$base_url );
      //return add_dir_if( file, opts.base_url );
    return file;
  }
}

//////////////////////////////////////////
// устанавливает указанный параметр при вызове команды apply
// * target - полная ссылка на объект
// * пара object="some-path" и param="..."
export function setter( obj, options )
{
   obj.addParamRef("target","");
   obj.addObjectRef("object","");

   obj.addCmd( "apply",() => {

      if (obj.params.target) {
        var arr = obj.params.target.split("->");
        var tobj = obj.findByPath( arr[0] );
        if (tobj) {
          tobj.setParam( arr[1], obj.params.value, obj.params.manual );
        }
      }

      if (obj.params.object) {
        obj.params.object.setParam( obj.params.param, obj.params.value, obj.params.manual );
      }
   } )

}

// выполняет указанный код при вызове команды apply
export function func( obj, options )
{
   obj.feature("call_cmd_by_path");

   obj.addCmd( "apply",() => {
      if (obj.params.code) {
        var env = obj;
        eval( obj.params.code );
      }
      if (obj.params.cmd) {
        obj.callCmdByPath(obj.params.cmd)
      }
      for (let c of obj.ns.getChildren()) {
        c.callCmd("apply");
      }
   } )
}

// автоматический вызов команды apply при изменении любых параметров
// (кстати странно - даже выходных получается)
export function auto_apply( obj ) {
  function evl() {
    obj.callCmd("apply");
  }
  env.feature("delayed");
  var eval_delayed = env.delayed( evl )

  env.on('param-changed', (name) => {
    if (name == "output") return;
    if (env.getParamOption(name,"iotype") == "output") return;
    eval_delayed();
  });
}

// выполняет заданный код. если код поменяется - выполнит его еще раз.
export function js( obj, options )
{
  obj.onvalue("code",() => {
    if (obj.params.code) {
       var env = obj;
       try {
         eval( obj.params.code );
       }
       catch (e) 
       {
         console.error(e);
       }
    }
  });
}

export function call_cmd_by_path(obj) {

  obj.callCmdByPath = ( target_path, ...args ) => {
      if (!target_path) return;
      if (typeof(target_path) == "function") {
        return target_path( ...args )
      }
      var arr = target_path.split("->");
      if (arr.length != 2) {
        //console.error("btn: cmd arr length not 2!",arr );
        return;
      }
      var objname = arr[0];
      var paramname = arr[1];
      //var sobj = obj.findByPath( objname );
      //R-LINKS-FROM-OBJ
      var sobj = obj.findByPath( objname );
      if (!sobj) {
        console.error("callCmdByPath: cmd target obj not found",objname );
        return; 
      }
      if (!sobj.hasCmd( paramname)) {
        if (typeof( sobj[paramname] ) === "function") {
          sobj[paramname].apply( sobj );
          return;
        }
        console.error("btn: cmd target obj has nor such cmd, nor function",objname,paramname );
        return; 
      }
      sobj.callCmd( paramname );
  }

}

//////////////////////////////////
export function repeater( env, fopts, envopts ) {
  var children = {};
  env.restoreFromDump = (dump,manualParamsMode) => {
    children = dump.children;
    env.vz.restoreParams( dump, env,manualParamsMode );
    env.vz.restoreLinks( dump, env,manualParamsMode );
    env.vz.restoreFeatures( dump, env,manualParamsMode );
    
    return Promise.resolve("success");
  }

  var created_envs = [];

  env.onvalue("model",(model) => {
     for (let old_env of created_envs) {
       old_env.remove();
     }

     var firstc = Object.keys( children )[0];

     model.forEach( (element,eindex) => {
       var edump = children[firstc];
       edump.keepExistingChildren = true; // но это надо и вложенным дитям бы сказать..

       var p = env.vz.createSyncFromDump( edump,null,env.ns.parent );
       p.then( (child_env) => {
          // todo epochs
          child_env.setParam("modelData",element);
          child_env.setParam("modelIndex",eindex);

          created_envs.push( child_env );
       });
     });
  })
}

////////////////////////////
export function compute( env, fopts ) {
  env.setParam("output",undefined);
  env.setParamOption("output","internal",true);

  var imsetting_params_maybe;
  function evl() {
    if (env.params.code) {
     var params = env.params;
     imsetting_params_maybe = true;
     try {
      eval( env.params.code );
     } finally {
      imsetting_params_maybe=false;
     }
    }
  }

  env.feature("delayed");
  var eval_delayed = env.delayed( evl )

  env.on('param_changed', () => {
    if (!imsetting_params_maybe)
       eval_delayed()
  } );
  eval_delayed();
}

export function compute_output( env, fopts ) {
  env.setParam("output",{});
  env.setParamOption("output","internal",true);

  function evl() {
    if (env.params.code) {
     var params = env.params;
     var func = new Function('env',env.params.code)
     var res = func( env );
     //var res = eval( env.params.code );
     env.setParam("output",res);
    }
  }

  env.feature("delayed");
  var eval_delayed = env.delayed( evl )

  env.on('param_changed', (name) => {
     if (name != "output")
        eval_delayed();
   });
  eval_delayed();
}