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