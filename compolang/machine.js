// A Viewzavr package is a javascript module. It may do anything, and beside that
// there are following special functions may be exported:
// * setup, which is called when package is loaded
// * create, which is called to create scene when vzPlayer.loadApp function is called.

// setup function may register components in types table, which is used by player's visual interface
// and by Viewzavr.createObjByType function.
export function setup( vz ) {
  // на будущее получается как-то так
  //vz.addItemType( "compolang-machine","Compolang interpreter", {features: "compolang_interpreter"} );
  // и можно сокращать
  //vz.addItemType( "compolang-machine","Compolang interpreter", "simple_lang_interpreter" );
  // да и на самом деле даже - если тип влечет фичу
  vz.addItemType( "compolang_machine","Compolang machine" );

/*
  vz.addItemType( "compolang-machine","Compolang interpreter", function( opts ) {
    //return create( vz, opts );
    return vz.createObj( {name:"compolang",...opts,features:"simple_lang_interpreter"})
  } );
*/  
  vz.register_feature( "compolang_machine", compolang_machine);
  lang.setup( vz,lang );
}

import * as lang from "./compo-lang.js";

export function compolang_machine(obj) {
  obj.feature("simple-lang delayed");
  var go = obj.delayed(interpret);
  
  obj.addText( "text", "",go );
  obj.addString("base_url","",go);
  
  function interpret() {
    obj.ns.removeChildren();
    obj.parseSimpleLang( obj.params.text, {base_url: obj.params.base_url } );
  }

}


// create function should return Viewzavr object
export function create22( vz, opts ) {
  opts.name ||= "compolang";
  var obj = vz.createObj( opts );
  obj.feature("simple_lang_interpreter");
  /*
  obj.feature("simple-lang delayed");
  var go = obj.delayed(interpret);
  
  obj.addText( "text", "",go );
  obj.addString("base_url","",go);
  
  function interpret() {
    obj.ns.removeChildren();
    obj.parseSimpleLang( obj.params.text, {base_url: obj.params.base_url } );
  }
  */

  return obj;
}