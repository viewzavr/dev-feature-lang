import * as df from "./df.js";

export function setup(vz, m) {
  vz.register_feature_set( m );

/* idea:
  vz.compalang(`
      .......
`);
*/
}

// создает новую df из выбранных колонок входной df
// пример: df_set X=<значение> Y="->Z"
// тогда в колонке X будет константа указанного значения, а в Y - скопируется колонка Z
// тут set считается что в своем окружении и опирается на параметры этого окружения
// при этом старые колонки сохраняются
export function df_set( env, opts ) {
 //Object.keys( args ) 
 env.onvalue("input",(value) => {
   if (!df.is_df(value)) {
      console.error( "df_set: incoming value is not df", value)
      return
   };

   var output = df.create_from_df_no_slice( value );

   var cols = env.getParamsNames();
   var colvals = env.params;
   // моно сделать фильтр что выставлено из языка
   for (let colname of cols) {
     var colvalue = colvals[colname];
     var colarr;
     if (typeof(colvalue) == "string" && colvalue.slice(0,2) == "->" ) {
        colarr = value[ colvalue.slice( 2 ) ] || []; // так-то get_column здесь..
     }
     else
        colarr = new Array( df.get_length(value) ).fill(colvalue); // так то тут выгоднее ставить функцию было бы
        // но для этого df должен уметь поддержать колонку-функцию
        // и кстати эта ф-я не обязана быть константой...
        // но надо решить вопросы с копированием тогда..

    df.add_column( output, colname, colarr );
   }
   env.setParam("output",output);
 })
}

// параметр: count
// выбирает подстроки с шагом count
export function df_skip_every( env, opts ) {
 //Object.keys( args ) 
 env.onvalues(["input","count"],(value,count) => {
   if (!df.is_df(value)) return;
   if (!(count > 0)) return;
   var output = df.skip_every( value,count)
   env.setParam("output",output);
 })
}

// выбирает подмножество строк
// start, count
export function df_slice( env, opts ) {
 env.onvalues_any(["input","start","count"],(value,start,count) => {
   if (!df.is_df(value)) return;
   //if (!(env.params.step > 0)) return;
   var start = start || 0;
   var finish = (count > 0) ? start + count : value.length;
   if (finish > value.length) finish=value.length;

   var output = df.slice( value,start,finish)
   env.setParam("output",output);
 })
}

// фильтр надо сделать по колонке..

import * as utils from "../lib3dv3/utils.js";

// конвертирует dataframe в array по указанным колонкам построчно
// вход: input - df
//       columns - имена колонок
// выход: взяты колонки и их значения соединены одно за другим и итого 1 массив
export function df_combine( env ) {
  env.onvalues(["input","columns"],(df,cols) => {
    if (!df.isDataFrame) return;
    let arrs = cols.map( name => df[name] );
    
    let res = utils.combine( arrs );
    env.setParam("output",res);
  });
}

/////////////////// конвертирует df в набор df построчно
// т.е. на выходе массив dataframe-ов в каждом из которых 1 строка записана

export function df_to_rows( env ) {
  env.onvalues(["input"],(value) => {
    if (!df.is_df(value)) {
      env.setParam("output",[]);
      return;
    }
    
    let res = [];
    for (let i=0; i<value.length; i++) {
      let output = df.slice( value,i,i+1);
      res.push( output );
    }
    
    env.setParam("output",res);
  });
}