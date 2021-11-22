export function setup(vz, m) {
  vz.register_feature_set( m );
}

import CSV from "./csv.js";
import * as df from "./df.js";

export function load_csv( env ) {
  //var empty_df = df.create();
  env.addFile("file");
  env.trackParam("file",(file) => {
    console.log("gonna load csv from",file);
    //env.setParam("output",df );
    fetch( file ).then( (res) => res.text() ).then( (text) => {
      var df = CSV( text )
      env.setParam("output",df );
    });
  })
  if (env.params.file)
      env.signalParam("file");
}
