// фича parseSimpleLang и базовые фичи языка load, loadPackage, pipe, register_feature

export function setup(vz, m) {
  vz.register_feature_set(m);
}

import * as P from "./lang-parser.js";
export function simple_lang(env) 
{
  env.parseSimpleLang = function( code, opts={} ) {
    try {
      return P.parse( code, { vz: env.vz, parent: (opts.parent || env), base_url:opts.base_url } );
    } 
    catch (e) 
    {
      console.error(e);
      if (typeof e.format === "function")
          console.log( e.format( [{text:code}] ));

    }
  }
}

var compolang_modules = {};
export function load(env,opts) 
{
  env.feature("simple-lang");
  //env.parsed_alive = false;
  //env.finalize_parse = () => { current_parent = parents_stack.pop() };

  env.trackParam("files",(files) => {
    console.log("load: gonna load files",files)
    if (!files) return;
    files.split(/\s+/).map( loadfile )
  })
  env.signalParam("files");

  function loadfile(file) {
     if (file.endsWith( ".js")) {
       return env.vz.loadPackage( file )
     }

     if (compolang_modules[file])
      file = compolang_modules[file];
     else
      file = env.compute_path( file );
    
     var new_base_url = env.vz.getDir( file );
     console.log("load: loading",file)
     fetch( file ).then( (res) => res.text() ).then( (txt) => {
       env.parseSimpleLang( txt, {vz: env.vz, parent: env.ns.parent,base_url: new_base_url} );
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

    return vzPlayer.loadPackage( file )
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
export function register_feature( env ) {
  env.onvalue("code",(code) => {
    if (!env.params.name)
    {
      console.error("FEATURE CODE WITHOUT NAME CANNOT BE REGISTERED",code);
      return;
    }
    code = "(env,args) => { " + code + "}";
    var f = eval( code );
    env.vz.register_feature( env.params.name, f );
  });

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
  //env.$base_url = opts.base_url;
  env.compute_path = (file) => {
    //if (Array.isArray(file))
    if (typeof(file) === "string")
      return add_dir_if( file, opts.base_url );
    return file;
  }
}