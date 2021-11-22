var cache = {};

export function clearCache() {
  cache = {}
}

export function cachedLoad( url, transform_func,loadfile_func ) {

  if (!loadfile_func) loadfile_func = loadFile; // use viewlang func

function genpromis() {
  return new Promise(
      function( resolv,reject ) {
        loadfile_func( url, function(res) {
          resolv( [url,transform_func(res)] );
        }
        ,
        function(err) {
          console.error("cachedLoad: error loading file url=",url,"err=",err);
          resolv( [url,transform_func("")] );
        }
        )
        }
    );
}

  if (typeof(url) == "string") {
    if (!cache[url]) cache[url] = genpromis();
    return cache[url];
  }
  
  return genpromis();
}

export function combine( arrays_list ) {
  var arr0 = arrays_list[0];
  if (!(Array.isArray(arr0) || arr0 instanceof Float32Array)) {
    return [];
  }

  const len = arr0.length;
  const len2 = arrays_list.length;  
  var res = new Float32Array( len * len2 );
  
  // F-COMBINE-EMPTY-COLUMNS
  for (var j=0; j<len2; j++)
    if (!arrays_list[j]) arrays_list[j] = [];

  var k = 0;
  for (var i=0; i<len; i++) {
    for (var j=0; j<len2; j++,k++)
      res[k] = arrays_list[j][i] || 0; // F-COMBINE-EMPTY-VALUES
  }
  return res;
}


// interpolates two 1-dimensional arrays
export function interp_arr( arr1, arr2, w ) {
  //var acc = [];
  if (!arr1) return []; // ну так вот странно пока
//  if (!arr1) arr1=arr2;
  if (!arr2) arr2=arr1;
//  if (!arr1) return []; // ну так вот странно пока
  if (arr1 === arr2) return arr1;

  // ***********************

  // TODO обработать различие длин массивов - интерполировать только общую часть, а хвост копировать
  // сейчас как-то так и делается но абы как и только если второй массив длинее первого
  
  if (typeof(arr1[0]) == "string" || typeof(arr2[0]) == "string") return arr1;
   
  const count = arr1.length;
  var acc = new Float32Array( count );
  for (var i=0; i<count; i++) {
//    if (typeof(arr1[i]) == "string") 
// todo optimize - вынести флаг проверку первого аргумента наружу. а точнее вообще отдельную ветку сделать.. типа if (typeof(arr1[i]) == "string") return arr1;
// DONE см выше
//      acc.push( arr1[i] );
//    else
//      acc.push( arr1[i] + w * (arr2[i] - arr1[i]) );
      acc[i] = arr1[i] + w * (arr2[i] - arr1[i]);
  }
  return acc;
}

// todo передалать на интерфейс DF
// interpolates dataframe
export function interp_df( df1, df2, w ) {
  return interp_csv( df1, df2, w );
}

// interpolates dataframe
export function interp_csv( csv1, csv2, w ) {
  if (!csv1) return { colnames: [], length: 0, isDataFrame: true}
  if (!csv2) return csv1;
  if (csv1 === csv2) return csv1; // in case of same data provided
  
  var res = { isDataFrame: true };
  res.colnames = csv1.colnames;
  res.length = csv1.length;
  res.colnames.forEach(function(name) {
    res[ name ] = interp_arr( csv1[name], csv2[name], w );
  });
  
//  console.log("intterp csv1",csv1,"csv2",csv2);
//  console.log("interpolated csv is",res );
  
  return res;
};

/* Generates the following construct:
  1 adds params (file,file2,w) to obj
  2 loads data from that files,
  3 parses this data by parser arg func
  4 interpolates 2 data using iterp arg func
  5 result is setted as param to obj named dataparam string arg
*/
export function file_merge_feature( obj,parser,interp,dataparam,loadfile ) {
  obj.addFile( "file","",function(v) {
    cachedLoad(v,parser,loadfile).then(function(arr) {
      var fact_v = arr[0];
      var dat = arr[1];
      if (fact_v == obj.getParam("file")) { // here we check that loaded data is that needed right now
        dat1 = dat;
        f(1);
      }
    });
  });
  
  obj.addFile( "file_interpolate_2","",function(v) {
    cachedLoad(v,parser,loadfile).then(function(arr) {
      var fact_v = arr[0];
      var dat = arr[1];
      if (fact_v == obj.getParam("file_interpolate_2")) {
        dat2 = dat;
        f(2);
      }
    });
  });
  
  obj.addSlider( "interpolate_w",0,0,1,0.01,function(v) {
    w=v;
    f(4); // this should not be called if files are still loaded!
  });
  
  var dat1, dat2, w=0;
  var f = function() {
    if (obj.removed) return;
  
    var dat = interp( dat1, dat2, w );
    obj.setParam( dataparam, dat );
  }
  
  ///////////// feature: R-NOJUMP-ON-PARAM-CHANGE and R-NOJUMP-ON-W-CHANGE
  // in other case data will jump while files are loading
  // maybe better to assign [files] instead of [file] and [file2]
  // and move them into Promise.all
  // but in that case we have to track that they are not changed manually
  // which is possible, btw
  // TODO: this doesnt work. setFile_v1 -> flag, setFile_v2 -> flag, loaded_v1 => flag cleared
  // idea: create promises for each file, and reassign them to some vars
  
  obj.trackParam("file",function() { data_pending = data_pending | 1; } );
  obj.trackParam("file_interpolate_2",function() { data_pending = data_pending | 2; } );
  var data_pending=0;
  
  var orig_f = f;
  f = function(reason) {
    if (reason < 4) data_pending = data_pending & (~reason);
    if (data_pending) return;
    orig_f();
  }
}


export function add_param_interpolation( obj,param,outputparam,f ) {
  obj.trackParam( param,u );
  var param2 = param + "_interpolate_2";
  obj.trackParam( param2,u );
  obj.addSlider( "interpolate_w",0,0,1,0.01,u );
  
  function u() {
    var v1 = obj.params[param];
    var v2 = obj.params[param2];
    var w = obj.params.interpolate_w;
    var res;
    if (w == 0 || typeof(v2) == "undefined" || !isFinite(v1))
       res = v1;
       else
       res = v1 + (v2-v1)*w;
    if (typeof(res) != "undefined") { // mm?
      obj.setParam( outputparam, res );
      if (f) f( res );
    }
  }

}
