export function setup(vz, m) {
  vz.register_feature_set(m);
  /*
  vz.register_feature("simple-lang",simple_lang);
  vz.register_feature("load",load);
  vz.register_feature("load_package",load_package);
  */
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

     fetch( file ).then( (res) => res.text() ).then( (txt) => {
       env.parseSimpleLang( txt, {parent: env.ns.parent} );
     });
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