import * as vrml from "./parse_vrml.js";

export function setup( vz,m ) {
  vz.register_feature_set( m )
}

export function parse_vrml( env ) 
{
  function parse1( text ) {
    var v = vrml.construct_vrml_object_from_text( text );
    var s = vrml.get_vrml_shapes( v );

    var v2 = {
      positions: vrml.get_shapes_xyz_arr( s ),
      indices: vrml.get_shapes_indices_arr( s ),
      colors: vrml.get_shapes_colors_arr( s )
    }

    return v2;
  }

  env.onvalue("input",(text) => {
     let vrmlobj = parse1( text );
     env.setParam("output",vrmlobj);
  })

}

export function render_vrml ( env ) 
{
   env.feature("mesh");

   env.onvalue("input",(vrmlobj) => {
      env.setParam("positions",vrmlobj.positions);
      env.setParam("indices",vrmlobj.indices);
      env.setParam("colors",vrmlobj.colors);
   });
}