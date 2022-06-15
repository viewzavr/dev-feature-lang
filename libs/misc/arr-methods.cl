// кстати если в list добавить length - число аргументов, и привести параметры к аксессорам по именам
// то все arr-методы смогут обрабатывать list.

//////// arr_filter_by_features
// вход - input - массив объектов
//      - features - строка список фич (сейчас одна)
// выход - output - список объектов у которых эти фича есть
register_feature name="arr_filter_by_features"
{
  arr_filter code="(val,index) => {
     //let features = env.params.features.split(' ');
     
     return val.is_feature_applied( env.params.features );
  }";
};


//////// arr_filter
// вход:
// input - массив
// code  - функция проверки что элемент подходит

// выход:
// output - массив с элементами прошедшими проверку

// пример: @arrsource | arr_filter code="(val,index) => index%3 == 0" | console_log

feature "arr_compact" {
  arr_filter code="(val) => val != null";
};

register_feature name="arr_filter"
  code=`
  // нам надо реагировать и на все остальные входы...
  //env.onvalues(["input","code"],process);

  function callprocess() {
    //console.log("qq arr_filter called",env.getPath(), env.params.input, env.params.code)
    if (env.params.input && env.params.code)
      process( env.params.input, env.params.code );
    else
      env.setParam("output",[]);
  }

  env.feature('delayed');
  let pd = env.delayed( callprocess );
  env.on("param_changed", () => {
     //console.log("qq arrfilter param-changed", env.getPath())
     pd();
  });
  pd(); // без этого вызова получается у нас arr-filter не сработает, если уже все готово

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

//////// arr_reverse
// вход:
// input - массив

// выход:
// output - массив перевернутый

register_feature name="arr_reverse"
  code=`
  env.onvalues(["input"],process);

  function process(arr) {
    if (!Array.isArray(arr)) {
      env.setParam("output",[]);
      return;
    }

    let res = arr.reverse();
    
    env.setParam("output",res);
  }
`;

register_feature name="arr_join"
  code=`
  env.onvalues(["input","with"],process);

  function process(arr,sep="") {
    if (!Array.isArray(arr)) {
      env.setParam("output",[]);
      return;
    }

    let res = arr.join(sep);
    
    env.setParam("output",res);
  }
`;

register_feature name="arr_sort"
  code=`

  env.onvalues_any(["input","func"],process);

  function process(arr,func) {
    if (!Array.isArray(arr)) {
      env.setParam("output",[]);
      return;
    }

    let res = arr.sort(func);
    
    env.setParam("output",res);
  }
`;

// вроде так покороче?
// compute_output code=`env.params.input.reverse()`

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

    env.setParam("output",[res.min, res.max])
  }
`;

///////////////////////////////////////

register_feature name="arr_length" code=`
  env.onvalues(["input"],(arr) => {
    let res = (arr ? arr.length : 0) || 0;

    env.setParam("output",res);
  });
`;

// уже идея такая - может сделать N-арный arr-метод который в js уходит
// т.к index, map, reverse и sort

register_feature name="arr_contains"
  code=`

  env.onvalues_any(["input",0],process);

  function process(arr,elem) {
    if (!Array.isArray(arr)) {
      env.setParam("output",false);
      return;
    }

    let res = arr.indexOf(elem) >= 0;
    
    env.setParam("output",res);
  }
`;

/*
register_feature name="arr_uniq" {
  geta (i-call-js code=("(arr) => [...new Set(arr)]"))
};
*/


register_feature name="arr_uniq"
  code=`

  env.onvalues_any(["input",0],process);

  function process(arr,elem) {
    if (!Array.isArray(arr)) {
      env.setParam("output",[]);
      return;
    }

/*
    function onlyUnique(value, index, self) {
      return self.indexOf(value) === index;
    }

    let res = arr.filter( onlyUnique );

*/    
    let res = [...new Set(arr)];
    env.setParam("output",res);
    
  }
`;

register_feature name="arr_flat"
  code=`

  env.onvalues_any(["input",0],process);

  function process(arr,elem) {
    if (!Array.isArray(arr)) {
      env.setParam("output",[]);
      return;
    }

    let res = arr.flat(5);
    env.setParam("output",res);
    
  }
`;

/* когда разберемся с добавкой аргументов то сможем делать вот так:
feature "arr_flat" {
  m_eval "(arr) => flat(5)" output=[] {{ x-param-alias name=1 from="input" }};
};
*/