
//////// arr_filter
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

//////// arr_map
// вход:
// input - массив
// code  - функция преобразования

// выход:
// output - массив результатами преоразований

// пример: @arrsource | arr_map code="(val,index) => val*2" | console_log

register_feature name="arr_map"
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
       res.push( check );
    })
    env.setParam("output",res);
  }
`;

///////////////////////////////////


register_feature name="arr_find_min_max" code=`
  env.onvalues(["input"],process);

  env.addCmd("refresh",() => process( env.params.input ));

  function compute_array_minmax( arr,min=10e10,max=-10e10 ) {
    for (var i=0; i<arr.length; i++) {
      var v = arr[i];
      if (v < min) min = v;
      if (v > max) max = v;
    }
    return {min: min, max:max, diff: (max-min)};
  }

  function isTypedArray(obj)
  {
    return !!obj && obj.byteLength !== undefined;
  }

  function process(arr) {

    if (!(Array.isArray(arr) || isTypedArray(arr))) {
      console.error("arr_find_min_max: not an array on input",arr);
      return;
    }

    let res = compute_array_minmax( arr );


    env.setParam("min",res.min);
    env.setParam("max",res.max);
    env.setParam("diff",res.diff);

    env.setParam("output",res)
  }
`;

///////////////////////////////////////

register_feature name="arr_length" code=`
  env.onvalues(["input"],(arr) => {
    let res = (arr ? arr.length : 0) || 0;

    env.setParam("output",res);
  });
`;