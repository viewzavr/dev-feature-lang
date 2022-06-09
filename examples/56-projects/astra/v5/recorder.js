// flying camera recorder and player
// надо делать мультик - сделаем полет камеры

export default function setup( vz ) {
  vz.addItemType( "rec1","Camera: Camera recorder/player (api)", function( opts ) {
    return create( vz, opts );
  } );
}

// create function should return Viewzavr object
export function create( vz, opts ) {
  var obj = vz.createObj( opts );

  var playerCamera = vz.createObjByType( "camera", {parent: obj});
  var link = playerCamera.linkParam("cameraInfo","..->curpostarget");
  //link.setParam("enabled",false);
  //obj.addParamMirror

  obj.addCheckbox("manage_camera",false,(v) => {
    link.setParam("enabled",v);
  })

//  var pts = vz.vis.addPoints( obj,"points" );
//  var lines = vz.vis.addPoints( obj,"lines" );
//  var spcur = vz.vis.addPoints( obj,"point_cur" );
//  var lincur = vz.vis.addPoints( obj,"line_cur" );
  
  var res = import_program( [] );

  obj.addText( "track","", function(v) {
    var arr = parse_arr( v );
    res = import_program( arr );
    // в секундах
    obj.addSlider( "T", obj.params.T || 0,0, res.getTimeLen(),5 );
    // obj.addSlider( "pseudoT", obj.params.pseudoT || 0,0, res.getTimeLen(),0.1 );
    
    obj.setParam( "positions", res.getRecords().map( r => r.slice( 0,3 ) ).flat(5) );
    obj.setParam( "positions-and-targets", res.getRecords().flat(5) );
    obj.setParamOption("positions","internal",true);
    obj.setParamOption("positions-and-targets","internal",true);
  });
  
  obj.trackParam("T",() => {
    var record = res.getRecordByT( obj.params.T );
    if (!record) return;
    //spcur.positions = record.slice( 0,3 );
    obj.setParam("curpos",record.slice( 0,3 ) );
    obj.setParam("curtarget", record.slice( 3,6 ) );
    obj.setParam("curpostarget", record ); // NOTE так то если я научусь выкусывать в ссылках то это не надо будет
  });

  // да тоже по идее надо внешнее делать.. и там разрешено или нет..
  //obj.addCheckbox("manage-camera"
  // но формально нужны галочки - если мы в режиме полета то вот, а если нет то нет
  
  obj.addCmd("add-current",() => {
    //var arr = [1].concat( qmlEngine.rootObject.cameraPos.concat( qmlEngine.rootObject.cameraCenter ) );
    var arr = playerCamera.params.cameraInfo;
    var str = "100 " + arr.map( v => v.toString() ).join(" ");
    obj.setParam( "track", obj.params.track + "\n" + str, true );
  });

  return obj;
}

// arr упаковка - набор записей [ время, x,y,z, x2,y2,z2 ] где x2 это куда смотрим 
function import_program( arr ) {
  var res = { records: [], times: [] };
  var t = 0; // длина ролика
  for (var i=0; i<arr.length; i++) {
    if (i > 0)
        t = t + arr[i][0];
    res.times.push( t );
    res.records.push( arr[i].slice( 1 ) );
  }
  res.getTimeLen = function() { return t; }
  
  res.getRecordByT = function(t) {
    for (var i=0; i<res.records.length; i++) {
      if (i == res.records.length - 1) return res.records[i];
      if (t >= res.times[i] && t <= res.times[i+1]) {
        var w =  (t - res.times[i]) /  (res.times[i+1] - res.times[i]);
        return interp_arr( res.records[i], res.records[i+1], w );
      }
    }
    return null;
  }
  
  res.getRecords = () => res.records;
  
/*  
  res.getRecordsSlice = (i1,i2) => {
    var acc = [];
    for (var i=0; i<res.records.length; i++) 
       acc = acc.concat( res.records[i].slice( i1,i2 ) );
  }
*/  
/*  
  res.getRecordsSlice = (i1,i2) => {
    var acc = [];
    for (var i=0; i<res.records.length; i++) 
       acc = acc.concat( res.records[i].slice( i1,i2 ) );
  }  
*/  

  return res;
}



///////////////
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

// тут у нас текст чисел разделенных пробелом
// и с комментами #
function parse_arr( txt ) {
  if (!txt.split) return [];
  var res = [];
  var lines = txt.split(/\n/);
  for (var line of lines) {
    var parts = line.split("#").map( s => s.trim() );
    if (!parts[0] || parts[0].length == 0) continue;
    var nums = parts[0].split(/[,\s]/);
    res.push( nums.map( f => parseFloat(f) ) );
  }
  return res;
}