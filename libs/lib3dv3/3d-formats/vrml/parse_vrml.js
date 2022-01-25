// constructs vrml js object from text
// provides accessors for that object to get particular things

export function construct_vrml_object_from_text (vrml_lines_text) {
//  console.time("parse_vrml");
  var STATES = [[]];

  var perliner = function (line) {
    var indent = line.match(/^(  )*/)[0].length / 2;

    var lines = line.replace(/(\S+)\s*([\}\]])/g, '$1\n$2').split(/\r?\n+/g);

    lines.forEach(function (line) {
      while (true) {
        if (line.match(/^[^\[]+\{/)) {
          var key = line.match(/^\s*([^\]]+?)\s*\{/)[1];
          line = line.replace(/(.*?)\{/, '');
          
          //console.log('OBJ', key);
          var obj = { };
          if (Array.isArray(STATES[0])) {
            obj.$TYPE = key;
            STATES[0].push(obj);
          } else {
            STATES[0][key] = obj;
          }
          STATES.unshift(obj);

        } else if (line.match(/^[^\{]+\[/)) {
          var key = line.match(/^\s*([^\{]+?)\s*\[/)[1];
          line = line.replace(/(.*?)\[/, '');
          
          //console.log('ARR', key);
          var arr = []; 
          if (Array.isArray(STATES[0])) {
            arr.$TYPE = key;
            STATES[0].push(arr);
          } else {
            STATES[0][key] = arr;
          }
          STATES.unshift(arr);

        } else if (line.match(/^\s*\}/)) {
          //console.log('CLOSEOBJ', '}');
          line = line.replace(/^\s*\}/, '')

          // TODO check
          STATES.shift();

        } else if (line.match(/^\s*\]/)) {
          //console.log('CLOSEARR', ']');
          line = line.replace(/^\s*\]/, '')

          // TODO check
          STATES.shift();

        } else if (line.match(/[\{\}\[\]]/)) {
          console.error('Mismatched parens:\n', line);
          return [];
          //process.exit(1);

        } else if (line.match(/^\s*(#|$)/)) {
          break;
        
        } else if (Array.isArray(STATES[0])) {
          var entries = line.split(/\s+|\s*\,\s*/g).filter(function (a) {
            return a;
          }).map(function (a) {
            //var arg = a.replace(/^\s+|\s+$/g, '');
            var arg=a; // parse-float-у вроде не должны пробелы то мешать..
            var p = parseFloat(arg); if (!isNaN(p)) return p;
//            if (String(parseFloat(arg)) == arg) {
//              return parseFloat(arg);
//            }
            return arg;
          });
          STATES[0].push.apply(STATES[0], entries);
          line = '';
        
        } else if (line.match(/^\s*\w+/)) {
          var key = line.match(/^\s*(\w+)/)[1];
          line = line.replace(/^\s*(\w+)/, '');

          var entries = line.split(/\s+|\s*\,\s*/g).filter(function (a) {
            return a;
          }).map(function (a) {
            //var arg = a.replace(/^\s+|\s+$/g, '');
            var arg=a;
            var p = parseFloat(arg); if (!isNaN(p)) return p;            
//            if (String(parseFloat(arg)) == arg) {
//              return parseFloat(arg);
//            }
            return arg;
          });
          STATES[0][key] = entries;
          line = '';

          //console.log('PROP', key, entries);

        } else {
          break;
        }
      }
    });
  }
    
  var vrml_lines_arr = vrml_lines_text.split(/\n/);
  for (var i=0; i<vrml_lines_arr.length; i++ )
  {
    perliner( vrml_lines_arr[i] );
  }
//  console.timeEnd("parse_vrml");
  return STATES[0];
}

/////////////////////////////// accessors

// returns set of shape objects of vrml
export function get_vrml_shapes(vrml) {
  return vrml.filter( function(rec) { return rec.$TYPE == "Shape" } );
}
  
// returns X,Y,Z coordinates from shapes set
// todo: maybe perform it for 1 shape only?
export function get_shapes_xyz (shapes) {
  var acc = { x:[], y:[], z:[] };

  shapes.forEach( function(s) {
    var pts = s.IndexedFaceSet.Coordinate.point;
    for (var j=0; j< pts.length; j+= 3) {
      acc.x.push( pts[j] );
      acc.y.push( pts[j+1] );
      acc.z.push( pts[j+2] );
    }
  })
    
  return acc;
}

export function get_shapes_xyz_arr (shapes) {
  var acc = [];

  shapes.forEach( function(s) {
    var pts = s.IndexedFaceSet.Coordinate.point;
    for (var j=0; j< pts.length; j+= 3) {
      acc.push( pts[j] );
      acc.push( pts[j+1] );
      acc.push( pts[j+2] );
    }
  })
    
  return acc;
}

export function get_shapes_indices(shapes) {
  var acc = { i1:[], i2:[], i3:[] };
  var i0 = 0;

  shapes.forEach( function(s) {
    var pts = s.IndexedFaceSet.coordIndex;

    for (var j=0; j< pts.length; j+= 4) {
      acc.i1.push( pts[j]+i0 );
      acc.i2.push( pts[j+1]+i0 );
      acc.i3.push( pts[j+2]+i0 );
    }

    i0 += s.IndexedFaceSet.Coordinate.point.length/3;
  })

  return acc;
}

export function get_shapes_indices_arr(shapes) {
  var acc = [];
  var i0 = 0;

  shapes.forEach( function(s) {
    var pts = s.IndexedFaceSet.coordIndex;

    for (var j=0; j< pts.length; j+= 4) {
      acc.push( pts[j]+i0 );
      acc.push( pts[j+1]+i0 );
      acc.push( pts[j+2]+i0 );
    }

    i0 += s.IndexedFaceSet.Coordinate.point.length/3;
  })

  return acc;
}

export function get_shapes_colors_arr(shapes) {
  var acc = [];
    
  var qq = function (s,acc) { // s = shape
    if (!s) { console.error("getshapecolorsarr: input is false!"); return acc; }
    var c = s.Appearance.Material.diffuseColor;
    var coords = s.IndexedFaceSet.Coordinate.point;
    for (var j=0; j<coords.length; j+=3) {
       acc.push( c[0] );
       acc.push( c[1] );
       acc.push( c[2] );
     }
    return acc;
  }

  shapes.forEach( function(s) {
    qq( s, acc )
  })

  return acc;
}
