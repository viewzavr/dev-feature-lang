
// разделяет df на несколько - по значению указанной колонки
// input, column
// output - массив вида [ значение column, sub-df ]
feature "df_split" {: env |
  env.onvalues(["input","column"],(df,colname) => {
    let difres = new Set()
    let col = df.get_column( colname )
    if (!col) {
      env.setParam("output",{})
      return
    }
    
    for (let i=0; i<df.length; i++) {
       let v = col[i]
       difres.add( v )
    }
    
    let res = []
    for (let value of difres.keys()) {

      let dfr = df.create_from_df_filter_fast( (df, index) => {
        return df[colname][index] == value
      })
      res.push( [value, dfr] )
    }
    env.setParam("output",res)
  })
:}

// строит индекс значений
// input, column
// output - словарь вида значение column=>массив_номеров_строк
feature "df_index" {: env |
  env.onvalues(["input","column"],(df,colname) => {
    let res = {}
    let col = df.get_column( colname )
    if (col)
    for (let i=0; i<df.length; i++) {
       let v = col[i]
       res[ v ] ||= []
       res[v].push(i)
    }
    env.setParam("output",res)
  })
:}

// read @df | df_convert {: df index row | return {...df.get_row(index),X:index} :}
/* функция fn получает на вход строку df, а на выходе должна выдать null, строку df или массив строк.
   todo мб это оптимизировать всё стоит..
*/
feature "df_convert" {: env |
  if (!env.paramAssigned(1))
     env.setParam(1,true)

  env.onvalues(["input",0,1], (df, fn, arg) => {
    //console.log("df-convert processing...",df,fn)
    if (!fn.bind) fn = eval( fn ); // типа строка..
    let res = df.create_from_df_convert( fn, arg )
    env.setParam( "output",res )
  })
:}

// синоним - как с arr_map
feature "df_map" {
  df_convert
}

feature "df_get_columns" {
  x: object output = (m-eval {: df=@x.input |
    return df?.colnames || []
  :})
}

// df_get - вытаскивает 1 колонку
// вход: input, column
//   input - датафрейм
//   column - колонку, которую вытащить

/* пример: @dat | df_get column="X"
*/
register_feature name="df_get" 
  code=`
  // это зло
  //env.setParam("output",[]);

  //env.feature("delayed");
  //let delayed_process = env.delayed( process );
  // не надо - onvalues итак уже delayed
  env.onvalues(["input","column"],process);

  env.feature("param-alias");
  env.addParamAlias( "column",0 );

  function process(df,column) {
    if (!df || !df.isDataFrame) {
      env.setParam("output",[]);
      return;
    }

    //let o = df.get_column( df, column ) || [];
    let o = df[column] || [];
    env.setParam("output",o);
  }
`;

feature "df_mul" {
  df_operation func={: orig coef | return orig*coef :}
}
feature "df_div" {
  df_operation func={: orig coef | return orig/coef :}
}
feature "df_add" {
  df_operation func={: orig coef | return orig+coef :}
}
feature "df_sub" {
  df_operation func={: orig coef | return orig-coef :}
}

// df_filter - фильтрует, выбирая только строки удовлетворяющие условию
// вход: input, code
//   input - датафрейм
//   code - код функции, которая применяется построчно и если выдает результат то строка берется

/* пример: @dat | df_filter code="(df, index) => df[index].X > 0";
*/

// мб тут стоит применить идею лямбды. а ее можно каррировать
// read @df | df_filter {: df index | return df.X[index] > 5 :}

// в качестве фантазии на будущее: df_filter X={: x | return x > 5:} это фильтрация по значению колонки
feature "df_filter"
  `
  env.feature("param-alias");
  env.addParamAlias("code",0);
  env.onvalues(["input","code"],process);

  function process(df,code) {

    if (!df || !df.isDataFrame) {
      env.setParam("output",[]);
      return;
    }
    //var f = new Function( "line", code );
    //var res = dfjs.create_from_df_filter( df, f );
    
    var f=code;
    if (typeof(f) == 'string') f = eval( f );

    var res = df.create_from_df_filter_fast( f );
    env.setParam("output",res);
  }

/* todo научиться делать сие
  import( env.$base_url + "df.js").then( (m) => {
  	env.setParam("dfjs",m);
  });
*/  
`;

// todo..
feature "df_append_rows" {: env |
  env.trackParam(0, arr => {
    let df = env.params.input
    if (!df?.is_df) return
  })
:}

// это строанное
load "misc"
let df_lib = (import_js (resolve_url "./df.js"))
feature "df-merge" {: env |
  env.onvalue(0,(list) => {
    if (!(Array.isArray(list) && list.length > 0)) {
      env.setParam( "output", this._.df_lib.create() )
      return
    }
    if (!(list && list[0] && list[0].clone)) {
      env.setParam( "output", this._.df_lib.create() )
      return
    }
    console.log("df-merge mergin",list)

    let df = list[0].clone()
    for (let i=1; i<list.length; i++) {
      let df2 = list[i];
      if (!df2) continue
      for (let name of df2.colnames) {
        df.add_column( name, df2.get_column(name) )
      }
    }
    env.setParam("output",df)
  })
:}