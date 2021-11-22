export function setup(vz, m) {
  vz.register_feature("simple-lang",simple_lang);
  vz.register_feature("load",load);
  vz.register_feature("load_package",load_package);
}

import * as P from "./lang-parser.js";
export function simple_lang(env) 
{
  env.parseSimpleLang = function( code, opts={} ) {
    try {
      return P.parse( code, { vz: env.vz, parent: (opts.parent || env) } );
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
    console.log("gonna load files",files)
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
    console.log("gonna load files",files)
    if (!files) return;
    files.split(/\s+/).map( loadfile )
  })
  env.signalParam("files");

  function loadfile(file) {
    return vzPlayer.loadPackage( file )
  }
}