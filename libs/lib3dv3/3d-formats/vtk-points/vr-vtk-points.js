export function setup( vz,m ) {
  vz.register_feature_set( m )
}

import { VTKLoader } from "./threejs-extract/VTKLoader.js";

export function parse_vtk_points( env ) {

  env.onvalue("input",(text) => {
     var loader = new VTKLoader();
     var df = loader.parse( text );
     console.log("parse_vtk: df=",df );
     env.setParam("output",df);
  })
  
}

// попытки сделать рисование структуры типа vtk
export function render_vtk_points( env, opts ) {
   env.feature("points");

   env.onvalue("input",(data) => {
      env.setParam("positions",data.XYZ);
      //env.setParam("colors",objdata.colors);
   });
}

export function points_vtk_input ( env, opts ) {

   env.host.onvalue("input",(data) => {
      env.host.setParam("positions",data.XYZ);
      //env.setParam("colors",objdata.colors);
   });  
}

import * as DF from    "../../../df/df.js";
export function vtk_points_to_normalized_df( env ) {
  env.host.onvalue("input",(data) => {
      var df = DF.create_from_df( data );
      let count = Math.floor( data.XYZ.length / 3 );
      let ax=new Float32Array( count );
      let ay=new Float32Array( count );
      let az=new Float32Array( count );
      for (let i=0,j=0; i<count; i++,j+=3) {
        ax[i] = df.XYZ[j];
        ay[i] = df.XYZ[j+1];
        az[i] = df.XYZ[j+2];
      }

      DF.add_column( df, "Z",az,true );
      DF.add_column( df, "Y",ay,true );
      DF.add_column( df, "X",ax,true );

      DF.remove_column( df, "XYZ" );
      DF.update_length( df );

      env.host.setParam( "output", df );
  });
}