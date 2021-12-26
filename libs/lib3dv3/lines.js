import * as THREE from './three.js/build/three.module.js';
import * as utils from "./utils.js";

export function setup(vz, m) {
  vz.register_feature_set( m );
}

export function lines( env ) {
  var geometry = new THREE.BufferGeometry();
  var material = new THREE.LineBasicMaterial( {} );
  var sceneObject = new THREE.LineSegments( geometry, material );

  env.setParam("output",sceneObject );
  // ну да, это правильно, писать в output
  // потому что pipe-ы вытаскивают именно output
  // и еще причем мы пишем не в сцену, а просто некий output.
  // потом обходом это все соберется

  env.onvalue("positions",(v) => {
    geometry.setAttribute( 'position', new THREE.BufferAttribute( new Float32Array(v), 3 ) );
    geometry.needsUpdate = true;
  });

  env.onvalue("colors",(v) => {
    if (v?.length > 0) {
      geometry.setAttribute( 'color', new THREE.BufferAttribute( new Float32Array(v), 3 ) );
      material.vertexColors = true;
    }
    else
    {
      geometry.removeAttribute( 'color' );
      material.vertexColors = false; 
    }
    geometry.needsUpdate = true;
    material.needsUpdate = true;
  })

  env.onvalue("color",(v) => {
     material.color = utils.somethingToColor(v);
     material.needsUpdate = true;
  });

  env.feature("lib3d_visual");

  // todo потом эти все вещи про df вытащить в отдельный фиче-слой
  // и аппендом их добавлять
  env.feature( "lines_df_input" );
}


export function lib3d_visual( env ) {

  /*
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
  */
  
  env.addCheckbox("visible",true,(v) => {
    //obj.visible=v;
  });
  env.addColor("color")

  //obj.addString("count","0");
}

// добавляет input, подразумевая под этим data-frame
export function lines_df_input( env ) {
  env.onvalue("input",(df) => {
    console.log("gonna paint df=",df);
    var dat = df;
    env.setParam("positions", utils.combine( [ dat.X, dat.Y, dat.Z, dat.X2, dat.Y2, dat.Z2 ] ) );
    if (dat.R2)
      env.setParam("colors", utils.combine( [ dat.R, dat.G, dat.B,dat.R2, dat.G2, dat.B2 ] ) );
    else
      env.setParam("colors", utils.combine( [ dat.R, dat.G, dat.B, dat.R, dat.G, dat.B ] ) ); 
    env.setParam("radiuses", dat.RADIUS || [] );
    env.setParam("count",env.params.positions.length / 3);
    env.signal("changed");
  })
}

////////////////////////////////////
export function points( env ) {
  var geometry = new THREE.BufferGeometry();
  var material = new THREE.PointsMaterial( {} );
  var sceneObject = new THREE.Points( geometry, material );

  env.setParam("output",sceneObject );
  // ну да, это правильно, писать в output
  // потому что pipe-ы вытаскивают именно output
  // и еще причем мы пишем не в сцену, а просто некий output.
  // потом обходом это все соберется

  env.onvalue("positions",(v) => {
    geometry.setAttribute( 'position', new THREE.BufferAttribute( new Float32Array(v), 3 ) );
    geometry.needsUpdate = true;
  });

  env.onvalue("colors",(v) => {
    if (v?.length > 0) {
      geometry.setAttribute( 'color', new THREE.BufferAttribute( new Float32Array(v), 3 ) );
      material.vertexColors = true;
    }
    else
    {
      geometry.removeAttribute( 'color' );
      material.vertexColors = false; 
    }
    geometry.needsUpdate = true;
    material.needsUpdate = true;
  })

  env.onvalue("color",(v) => {
     material.color = utils.somethingToColor(v);
     material.needsUpdate = true;
  });

  env.onvalue("radius",(v) => {
      material.size = v;
      material.needsUpdate = true;
  });

  env.feature("lib3d_visual");
  env.addSlider( "radius", env.params.radius || 1, 0,10,0.1 );

  // todo потом эти все вещи про df вытащить в отдельный фиче-слой
  // и аппендом их добавлять
  env.feature( "points_df_input" );
}

// добавляет input, подразумевая под этим data-frame
export function points_df_input( env ) {
  env.onvalue("input",(df) => {
    console.log("gonna paint df=",df);
    var dat = df;
    env.setParam("positions", utils.combine( [ dat.X, dat.Y, dat.Z ] ) );
    if (dat.R)
      env.setParam("colors", utils.combine( [ dat.R, dat.G, dat.B ] ) );
    env.setParam("radiuses", dat.RADIUS || [] );
    env.setParam("count",env.params.positions.length / 3);
    env.signal("changed");
  })
}