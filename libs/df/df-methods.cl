// df_get
// вход: input, column
//   input - датафрейм
//   column - колонку, которую вытащить

/* пример: @dat | df_get column="X"
*/
register_feature name="df_get" 
  code=`
  env.setParam("output",[]);
  env.feature("delayed");

  let delayed_process = env.delayed( process );
  env.onvalues(["input","column"],delayed_process);

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

// df_div - делит колонку column датайферма input на коэффициент coef

register_feature name="df_div" code=`
  env.onvalue("input",process);
  env.onvalue("coef",process);
  env.onvalue("column",process);

  function process() {
    var df = env.params.input;
    if (!df || !df.isDataFrame || !df[ env.params.column ] || !env.params.coef) {
      env.setParam("output",[]);
      return;
    }
    df = df.clone();
    df[env.params.column] = df[env.params.column].map( v => v / env.params.coef );
    env.setParam("output",df);
  }
`;

// вход: input, code
//   input - датафрейм
//   code - код функции, которая применяется построчно и если выдает результат то строка берется

/* пример: @dat | df_filter code="(line) => line.X > 0";
*/
register_feature name="df_filter" 
  code=`
  env.onvalues(["input","code"],process);

  function process(df,code) {
  	
    
    if (!df || !df.isDataFrame) {
      env.setParam("output",[]);
      return;
    }
    //var f = new Function( "line", code );
    //var res = dfjs.create_from_df_filter( df, f );
    
    var f = eval( code );

    var res = df.create_from_df_filter( f );
    env.setParam("output",res);
  }

/* todo научиться делать сие
  import( env.$base_url + "df.js").then( (m) => {
  	env.setParam("dfjs",m);
  });
*/  
`;