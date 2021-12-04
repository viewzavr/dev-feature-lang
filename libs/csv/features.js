export function setup(vz, m) {
  vz.register_feature_set( m );
}

import CSV from "./csv.js";
import * as df from "./df.js";

export function parse_csv( env ) {
  env.feature("load_file_func");
  //var empty_df = df.create();
  env.addText("input");
  env.onvalue("input",(text) => {
    var df = CSV( text );
    env.setParam("output",df );
  })
}

// тут set считается что в своем окружении и опирается на параметры этого окружения
export function set( env, opts ) {
 //Object.keys( args ) 
 env.trackParam("input",(value) => {
   if (!df.is_df(value)) return;

   var output = df.create_from_df_no_slice( value );

   var cols = env.getParamsNames();
   var colvals = env.params;
   // моно сделать фильтр что выставлено из языка
   for (let colname of cols) {
     var colvalue = colvals[colname];
     var colarr;
     if (typeof(colvalue) == "string" && colvalue.slice(0,2) == "->" ) {
        colarr = value[ colvalue.slice( 2 ) ] || [];
     }
     else
        colarr = new Array( df.get_length(value) ).fill(colvalue);

    df.add_column( output, colname, colarr );
   }
   env.setParam("output",output);
 })
 if (env.params.input) env.signalParam("input");
}

// count
export function skip_every( env, opts ) {
 //Object.keys( args ) 
 env.trackParam("input",(value) => {
   if (!df.is_df(value)) return;
   if (!(env.params.count > 0)) return;
   var output = df.skip_every( value,env.params.count)
   env.setParam("output",output);
 })
 if (env.params.input) env.signalParam("input");
}

// start, count
export function slice( env, opts ) {
 //Object.keys( args )
 env.trackParam("input",(value) => {
   if (!df.is_df(value)) return;
   //if (!(env.params.step > 0)) return;
   var start = env.params.start || 0;
   var finish = (env.params.count > 0) ? start + env.params.count : value.length;
   var output = df.slice( value,start,finish)
   env.setParam("output",output);
 })
 if (env.params.input) env.signalParam("input");
}

// фильтр надо сделать по колонке..
