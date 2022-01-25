import * as PO from "./parse_obj.js";

export function setup( vz,m ) {
  vz.register_feature_set( m )
}

export function parse_obj( env ) 
{
  function parse1( text ) {
    var res = PO.parse_obj( text );
    // var res = { XYZ: new Float32Array(xyz), indices: new Uint32Array(iii) }
    return res;
  }

  env.onvalue("input",(text) => {
     let objdata = parse1( text );
     env.setParam("output",objdata);
  })

}

// кстати важно - это render_obj_mesh по сути
// и могут быть еще render_obj_points
// и кстати если мы хотим двоих - то хорошо бы сделать такой тип all
// который перекидывает input на всех детей.. типа parse_obj | all { render_obj_mesh; render_obj_points; }
export function render_obj ( env ) 
{
   env.feature("mesh");

   env.onvalue("input",(objdata) => {
      env.setParam("positions",objdata.XYZ);
      env.setParam("indices",objdata.indices);
      //env.setParam("colors",objdata.colors);
   });
}