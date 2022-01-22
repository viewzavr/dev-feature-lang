register_feature name="get_query_param" code=`
    function getParameterByName(name) {
      name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
      var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
        results = regex.exec(location.search);
      //return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
      return results === null ? null : decodeURIComponent(results[1].replace(/\+/g, " "));
    }

    env.onvalue("name",(name) => {
      var v = getParameterByName(name);
      env.setParam("output",v);
    })  
`;

register_feature name="fill_parent" {
  style="position: absolute; width:100%; height: 100%; left: 0px; top: 0px;"
};


////////
// вход:
// input - массив
// code  - функция проверки что элемент подходит

// выход:
// output - массив с элементами прошедшими проверку

// пример: @arrsource | arr_filter code="(val,index) => index%3 == 0" | console_log

register_feature name="arr_filter" 
  code=`
  env.onvalues(["input","code"],process);

  function process(arr,code) {
    if (!Array.isArray(arr)) {
      env.setParam("output",[]);
      return;
    }
    //var f = new Function( "line", code );
    //var res = dfjs.create_from_df_filter( df, f );
    
    var f = eval( code );

    let res = [];
    arr.forEach( (v,index) => {
       let check = f( v,index );
       if (check) res.push( v );
    })
    env.setParam("output",res);
  }
`;