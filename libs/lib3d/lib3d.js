export function setup(vz, m) {
  vz.register_feature_set( m );
}

export function render3d( env ) {
  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.1, 1000 );
  var renderer;

  obj.setParam("tag","canvas");
  env.feature("dom");
  obj.onvalue("dom",(dom) => {
    renderer = new THREE.WebGLRenderer( {canvas: dom});
  });

}

import * as utils from "./utils.js";

export function points( env ) {
  var obj = env.vz.vis.addPoints( env, "points" );
  add_std( obj );
  env.trackParam("input",(df) => {
    console.log("gonna paint df=",df);
    var dat = df;
    obj.positions = utils.combine( [ dat.X, dat.Y, dat.Z ] );
    obj.colors = utils.combine( [ dat.R, dat.G, dat.B ] );
    obj.radiuses = dat.RADIUS || [];
    obj.setParam("count",obj.positions.length / 3);
    env.signal("changed");
  })
}

export function lines( env ) {
  var obj = env.vz.vis.addLines( env, "lines" );
  add_std( obj );
  env.trackParam("input",(df) => {
    console.log("gonna paint df=",df);
    var dat = df;
    obj.positions = utils.combine( [ dat.X, dat.Y, dat.Z, dat.X2, dat.Y2, dat.Z2 ] );
    if (dat.R2)
      obj.colors = utils.combine( [ dat.R, dat.G, dat.B,dat.R2, dat.G2, dat.B2 ] );
    else
      obj.colors = utils.combine( [ dat.R, dat.G, dat.B, dat.R, dat.G, dat.B ] ); 
    obj.radiuses = dat.RADIUS || [];
    obj.setParam("count",obj.positions.length / 3);
    env.signal("changed");
  })
}

// вот такая жизнь.. но есть надежда что на фиче-ланге это будет проще
export function linestrips( env ) {
  var convertor_env = env.create_obj({},{name:"convertor"});
  convertor_env.feature( "linestrips_to_lines" );
  convertor_env.linkParam( "input","..->input");
  var painter_env = env.create_obj({},{name:"lines-env"});
  painter_env.linkParam( "input","@convertor->output");
  painter_env.feature("lines");
}
export function linestrip( env ) {
  return linestrips(env);
}

import * as df from "../csv/df.js";

// идея - сведем к lines
// сделаем просто конвертор
export function linestrips_to_lines( env ) {
  env.trackParam("input",(dat) => {
    var prevn;
    var vals = {X:[],Y:[],Z:[],X2:[],Y2:[],Z2:[],R:[],G:[],B:[],R2:[],G2:[],B2:[]}
    var Nvals = dat.N ? dat.N : [];
    for (var i = 0; i<dat.length; i++)
    {
      var n = Nvals[i];
      if (n == prevn) {
        if (i > 0) { // todo optimize
          vals.X.push( dat.X[i-1] );
          vals.Y.push( dat.Y[i-1] );
          vals.Z.push( dat.Z[i-1] );
          vals.X2.push( dat.X[i] );
          vals.Y2.push( dat.Y[i] );
          vals.Z2.push( dat.Z[i] );

          if (dat.R) {
            vals.R.push( dat.R[i-1] );
            vals.G.push( dat.G[i-1] );
            vals.B.push( dat.B[i-1] );
            vals.R2.push( dat.R[i] );
            vals.G2.push( dat.G[i] );
            vals.B2.push( dat.B[i] );
          }
        }
      }
      prevn = n;
    }
    if (!dat.R) vals.R=undefined;
    var newdf = df.create_from_hash( vals );
    env.setParam("output", newdf)
  });
  if (env.params.input) env.signalParam("input");
}

function add_std( obj ) {
  obj.addArray("positions",[],3,function(v) {
    obj.positions = v;
  } );
  obj.setParamOption("positions","internal",true);
  
  obj.addArray("radiuses",[],1,function(v) {
    obj.radiuses = v;
  } );
  obj.setParamOption("radiuses","internal",true);  
  
  obj.addArray("colors",[],1,function(v) {
    obj.colors = v;
  } );
  obj.setParamOption("colors","internal",true);    
  
  obj.addCheckbox("visible",true,(v) => {
    obj.visible=v;
  });

  obj.addString("count","0");

}

/*
export function add_css_style( env ) {

  env.trackParam("text",(styles) => {
    var styleSheet = document.createElement("style");
    styleSheet.type = "text/css";
    styleSheet.textContent = styles;
    document.head.appendChild(styleSheet);
  })
  if (env.params.text) env.signalParam("text");

}
*/
