export function setup(vz, m) {
  vz.register_feature_set( m );
}

import CSV from "./csv.js";
import * as df from "../df/df.js";

export function parse_csv( env ) {
  env.feature("load_file_func");
  //var empty_df = df.create();
  env.addText("input");
  env.addString("separator",",");

  env.onvalues(["input","separator"],(text,sep) => {
    var df = CSV( text,sep );
    env.setParam("output",df );
  })
}

// генерирует текст csv из df
export function generate_csv( env ) {

  env.addCmd("apply",perform);

  function perform() {
    let src = env.params.input;
    if (!df.is_df(src)) {
      console.error( "generate_csv: input is not data-frame",src);
      return;
    }
    console.log('generate_csv: performing');    
    
    let cols = df.get_column_names( src );
    let text = cols.join(",");
    let len = df.get_length( src );

    for (var i=0; i<len; i++) {
      // подготовим строку
      let line = cols.map( (name) =>  df.get_column(src,name)[i] );
      text = text + "\n" + line.join(",");
    }

    console.log('generate_csv: setting output');
    env.setParam("output","");
    env.setParam("output",text);
  };

}
