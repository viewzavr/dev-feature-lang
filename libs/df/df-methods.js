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

/* df_create_from_arrays columns=["X,Y,Z,TEXT"] input=(list @row1_arr @row2_arr);
   т.е. input это массив строк, а каждая строка - массив значений в порядке columns
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

/* df_create_from_rows columns=["X,Y,Z,TEXT"] input=(list @row1 @row2 ...)
   input это массив словарей с именами и значениями колонок
*/
export function df_create_from_rows(env) {
  if (!env.paramAssigned("columns")) env.setParam("columns",[])
  env.onvalues(["input","columns"],(value,columns) => {
   if (!Array.isArray(value)) {
      console.error( "df_import_arrays: incoming value is not array", value)
      return
   };
   if (columns.length == 0) columns = Object.keys( value[0] || {} )
   let output = df.create_from_rows(value, columns);
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

  function process () {
    let value = env.params.input;
   if (!df.is_df(value)) {
      console.error( "df_set: incoming value is not df", value)
      return
   };

   var output = df.create_from_df_no_slice( value );

   var cols = env.getParamsNames();

   var colvals = env.params;
   //console.log("df-set",{cols,colvals})   
   // моно сделать фильтр что выставлено из языка
   //console.log("df set - begin stage")
   for (let colname of cols) {
     if (colname == "output" || colname == "input") continue

     let colvalue = colvals[colname];
     
     if (colvalue == null || isNaN( colvalue )) {
       continue; // оставить..
     }

     if (colname == "length") { // особый случай
       df.set_length( output, colvalue)
       continue
     }

     let colarr;
     if (typeof(colvalue) == "string" && colvalue.slice(0,2) == "->" ) {
        colarr = value[ colvalue.slice( 2 ) ] || []; // так-то get_column здесь..
     }
     else {
        // если colvalue это уже массив
        if (Array.isArray(colvalue))
          colarr = colvalue.slice(0)
        else {
          // console.log("making handler for ",colname,"colvalue=",colvalue)
          colarr = new Array( df.get_length(value) ).fill(colvalue); // так то тут выгоднее ставить функцию f(index), чем копировать значения

          // все последующее есть чухня

          // авантюра, DF-PROXY - типа оптимизация + заранее не знаем какой длины будет колонка
          /*
          var handler = {
            get: function(target, name) {
              const value = Reflect.get(target, name);
              if(typeof value === "function"){
                return value.bind(target)
              }
              if (name === "length") return output.length; // точка тормоза... надо ли это вообще? пусть нулем будет..
              // df-combine читает первую колонку.. ну пусть читает максимум из всех.. кстати..
              return colvalue;
            }
          };
          var proxy = new Proxy([], handler); // [] сиречь мы типа массив
          colarr = proxy
          */
          
        }
     }        
        // но для этого df должен уметь поддержать колонку-функцию
        // и кстати эта ф-я не обязана быть константой...
        // но надо решить вопросы с копированием тогда..

    //console.log("df set ",colname, colarr)
    df.add_column( output, colname, colarr );
   }
   env.setParam("output",output);
 }

 //env.onvalue("input",process )
 env.feature("delayed")
 let process_delayed = env.delayed( process )
 env.on('param_changed',(pn) => {
  //console.log("df-set: see param changed",pn)
  if (pn == "output") return
  process_delayed(); // потому что мало ли там будут шпарить..
  // но это кстати некий аналог потактовой обработки lingua franca
 })
 process_delayed(); // тыркнемся
}


// преобразует входную df (данную в input) вызывая единообразно func для каждой указанной колонки
// пример: df_operation X=10 Y=5 func={: v arg | return v*arg } умножает колонку X на 10 а колонку Y на 5
export function df_operation( env, opts ) {

  function process () {
   let value = env.params.input;
   if (!df.is_df(value)) {
      console.error( "df_operation: incoming value is not df", value)
      return
   };

   var output = df.create_from_df_no_slice( value );

   var cols = env.getParamsNames();
   var colvals = env.params;
   // моно сделать фильтр что выставлено из языка
   let func = env.params.func

   for (let colname of cols) {
     if (colname == "output" || colname == "input" || colname == "func") continue
     if (!value[colname]) continue;

     var colvalue = colvals[colname]; // чего дали в параметрах
     var colarr = value[colname].map( x => func( x, colvalue ) )
     
        // но для этого df должен уметь поддержать колонку-функцию
        // и кстати эта ф-я не обязана быть константой...
        // но надо решить вопросы с копированием тогда..

     df.add_column( output, colname, colarr );
   }
   env.setParam("output",output);
 }

 env.feature("delayed")
 let process_delayed = env.delayed( process )
 env.on('param_changed',(pn) => {
  if (pn == "output") return
  process_delayed(); // потому что мало ли там будут шпарить..
  // но это кстати некий аналог потактовой обработки lingua franca
 })
 process_delayed(); // тыркнемся
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

/////////////////// конвертирует df в набор строк
// где каждая строка есть dataframe

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
// где каждая строка есть массив
export function df_to_rows_arrays( env ) {
  if (!env.paramConnected("columns")) // ценный параметр columns позволяет добиться определенности в массиве
    env.setParam("columns",[])

  env.onvalues(["input","columns"],(value,columns) => {
    if (!df.is_df(value)) {
      env.setParam("output",[]);
      return;
    }
    
    let res = [];
    for (let i=0; i<value.length; i++) {
      let output = df.get_rows( value,i,1,columns );
      res.push( output );
    }
    
    env.setParam("output",res);
  });
}

/////////////////// конвертирует df в набор строк
// где каждая строка есть хеш
export function df_to_lines( env ) {
  if (!env.paramConnected("columns")) // тут columns вроде не так важен
    env.setParam("columns",[])

  env.onvalues(["input","columns"],(value,columns) => {
    if (!df.is_df(value)) {
      env.setParam("output",[]);
      return;
    }
    
    let res = [];
    for (let i=0; i<value.length; i++) {
      let output = df.get_line( value,i,columns );
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

