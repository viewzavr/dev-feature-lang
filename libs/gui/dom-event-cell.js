// перевод дом-событий в наши каналы comm3.js
import * as Q from "../../compolang/comm3.js";

export function setup( vz, m ) {
  vz.register_feature_set( m );

  vz.chain( "create_obj", function (obj,options) {
      obj.get_dom_event_cell = (name) => obj_dom_event_cell( obj, name );
      return this.orig( obj, options );
  });
}

// берет ячейку у массива объектов
// todo мб не только объекты сделать, а еще и dom.. но тогда тут отписываться придется
// хотя это возможно я думаю.
export function feature_dom_event_cell( env ) {
  env.onvalues( ["input",0], (arr, param_name) => {
    let single_elem_mode = !Array.isArray(arr);
    if (single_elem_mode) arr=[arr];
    let res = [];
    arr.forEach( (obj) => {
      if (!obj)
        res.push( null );
      else
        res.push( obj.get_dom_event_cell( param_name ) );
    });
    
    env.setParam( "output", single_elem_mode ? res[0] : res );
    // single_elem_mode - это плохо или это норм? так-то сигнатура выхода меняется...
  }); 
}

// универсальное - и для событий и для параметров
function obj_dom_event_cell( target, name ) {
  let c = Q.get_or_create_cell( target, "dom_event:"+name, target.getParam(name) );

  let unbind=()=>{};
  if (!c.attached_to_params) {
    c.attached_to_params = true;

    target.onvalue('dom',(dom) => {
       unbind();
       dom.addEventListener( name,ondom );
       unbind = () => {
          dom.removeEventListener( name, ondom );
       }
    });

    target.on("remove",() => unbind());
  };

  function ondom(event_data) {
    c.set( event_data );
  }

  return c;
};