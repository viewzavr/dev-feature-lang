import * as df from "./df.js";

export function setup(vz, m) {
  vz.register_feature_set( m );

/* idea:
  vz.compalang(`
      .......
`);
*/
}

export function df_create(env) {
 let output = df.create();
 //env.setParam("output",output)
 env.setParam("input",output)
 env.feature("df_set")
}

/* df_create_from_arrays columns=["X,Y,Z,TEXT"] input=(list @arr1 @arr2);
*/
export function df_create_from_arrays(env) {
  env.onvalues(["input","columns"],(value,columns) => {
   if (!Array.isArray(value)) {
      console.error( "df_import_arrays: incoming value is not array", value)
      return
   };
   let output = df.create_from_arrays(value, columns);
   env.setParam("output",output)
  });
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
     if (colname == "output" || colname == "input") continue

     var colvalue = colvals[colname];
     var colarr;
     if (typeof(colvalue) == "string" && colvalue.slice(0,2) == "->" ) {
        colarr = value[ colvalue.slice( 2 ) ] || []; // так-то get_column здесь..
     }
     else {
        // если colvalue это уже массив
        if (Array.isArray(colvalue))
          colarr = colvalue.slice(0)
        else
          colarr = new Array( df.get_length(value) ).fill(colvalue); // так то тут выгоднее ставить функцию было бы
     }        
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

/////////////////// конвертирует df в набор строк
// т.е. на выходе массив массивов, в каждом из которых 1 строка записана
export function df_to_rows_arrays( env ) {
  env.onvalues(["input"],(value) => {
    if (!df.is_df(value)) {
      env.setParam("output",[]);
      return;
    }
    
    let res = [];
    for (let i=0; i<value.length; i++) {
      let output = df.get_rows( value,i );
      res.push( output );
    }
    
    env.setParam("output",res);
  });
}

// вход массив df-ов
// выход df в котором строки df-ов поочередно заполнены значениями из списка исходных df
export function df_interleave( env ) {
  env.onvalues(["input"],(value) => {
    if (!Array.isArray(value))
    {
      env.setParam("output",[]);
      return;
    }

    value = value.filter( n => n != null);

    let df1 = value[0];
    if (!df.is_df(df1))
      {
      env.setParam("output",[]);
      return;
    }

    let has_column = {};
    for (let j=1; j<value.length; j++) {
      has_column[j] = {};
      for (let q of value[j].get_column_names())
        has_column[j][q] = true;
    }

    let res = df.create();
    for (let name of df1.get_column_names()) 
    {
      let acc = [];
      let col = df1[name];
      for (let i=0; i<col.length; i++) {
        acc.push( col[i] );
        for (let j=1; j<value.length; j++) {
          if (has_column[ j ][name]) {
            let v = value[j][name][i];
            acc.push( v );
          }  
        }
      }
      res.add_column( name, acc );
    };
    
    env.setParam("output",res);
  });
}