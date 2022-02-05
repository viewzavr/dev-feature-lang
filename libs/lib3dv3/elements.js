import * as THREE from './three.js/build/three.module.js';
import * as utils from "./utils.js";

export function setup(vz, m) {
  vz.register_feature_set( m );
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

  env.onvalues(["output","visible"],(so,vis) => {
    so.visible = vis;
  })

  env.addColor("color",[1,1,1]);

  // отдельная фича - отключаем frustum culling
  env.onvalue("output",(so) => {
    so.frustumCulled = false;
  })

  // такая всем добавка
  env.onvalues(["positions","output"],(p,o) => {
    if (o.geometry) {
      o.geometry.computeBoundingSphere();
      o.geometry.computeBoundingBox();
    }
  })

  //obj.addString("count","0");


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

  env.setParam("material",material);  

  env.feature("node3d",{object3d: sceneObject});
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
      env.setParam("color",[1,1,1]); // надо таки сбросить, а то эти цвета начинают на тот перемножаться
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
  // но - идея новая, попробовать points с универсальной структурой
  // + затем создать отдельную raw-points без этого

  env.setParam("material",material);  

  env.feature("node3d",{object3d: sceneObject});
}


////////////////////////////////////////// mesh

////////////////////////////////////
export function mesh( env ) {
  var geometry = new THREE.BufferGeometry();
  //var material = new THREE.MeshStandardMaterial( {side: THREE.DoubleSide} );
  //var material = new THREE.MeshPhongMaterial( {
    var material = new THREE.MeshStandardMaterial( {
      specular: 0x888888,
      emissive: 0x000000,
      shininess: 250,
      //ambient: 0xffffff,
      side: THREE.DoubleSide
  } );
  var sceneObject = new THREE.Mesh( geometry, material );

  env.setParam("output",sceneObject );
  // ну да, это правильно, писать в output
  // потому что pipe-ы вытаскивают именно output
  // и еще причем мы пишем не в сцену, а просто некий output.
  // потом обходом это все соберется

  env.feature("delayed");
  let recompute_normals = env.delayed( () => { 
    geometry.computeVertexNormals(); 
    env.emit("normals-recomputed", sceneObject );
  });

  env.onvalue("positions",(v) => {
    geometry.setAttribute( 'position', new THREE.BufferAttribute( new Float32Array(v), 3 ) );
    geometry.needsUpdate = true;
    recompute_normals();
  });

  env.onvalue("indices",(v) => {
    geometry.setIndex( new THREE.BufferAttribute( new Uint32Array(v), 1 ) );
    geometry.needsUpdate = true;
    recompute_normals();
  });


  // geometry.computeBoundingSphere();
  // geometry.setAttribute( 'normal', new THREE.BufferAttribute( new Float32Array(normals), 3 ) );

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
  
  // а вот почему я материал сюда положил, а scale3d - туда????
  env.onvalue("material",(v) => {
     // тут разрешаем объект подать, сообразно проверим
     // а давайте без давайте попробуем.. материал и все..
     //if (v.params) v = v.params.output;
     if (!v) return;
     sceneObject.material = v;
     material = v;
     env.signalParam("colors");
     env.signalParam("color");
  });

  env.setParam("material",material);

  env.feature("lib3d_visual");
  // 0.004 scale

  env.feature("mesh_df_input");
}


///////////////////// история про df-input
// заключается в попытке дать окружениям рисования некий стандартный вход
// который затем можно было бы использовать так, чтобы разные loaders
// выдавали структуру подобного формата на вход рисовалкам.

// добавляет input, подразумевая под этим data-frame
// считаем это универсальной структурой (попыткой ее создать)
export function points_df_input( env ) {
  env.onvalue("input",(df) => {
    //console.log("gonna paint df=",df);
    var dat = df;
    if (dat.XYZ || dat.positions)
      env.setParam("positions", dat.XYZ || dat.positions );
    else
      env.setParam("positions", utils.combine( [ dat.X, dat.Y, dat.Z ] ) );

    if (dat.colors)
      env.setParam("colors", dat.colors );
    else
    if (dat.R && dat.G && dat.B)
      env.setParam("colors", utils.combine( [ dat.R, dat.G, dat.B ] ) );

    env.setParam("radiuses", dat.RADIUS || [] );
    env.setParam("count",env.params.positions.length / 3);
    env.signal("changed");
  });
}


// добавляет input, подразумевая под этим data-frame
export function lines_df_input( env ) {
  env.onvalue("input",(df) => {
    //console.log("gonna paint df=",df);
    var dat = df;

    if (dat.XYZ || dat.positions)
      env.setParam("positions", dat.XYZ || dat.positions );  
    else
      env.setParam("positions", utils.combine( [ dat.X, dat.Y, dat.Z, dat.X2, dat.Y2, dat.Z2 ] ) );

    if (dat.colors)
      env.setParam("colors", dat.colors );
    else
    if (dat.R2 && dat.G2 && dat.B2)
      env.setParam("colors", utils.combine( [ dat.R, dat.G, dat.B,dat.R2, dat.G2, dat.B2 ] ) );
    else
    if (dat.R && dat.G && dat.B)
      env.setParam("colors", utils.combine( [ dat.R, dat.G, dat.B, dat.R, dat.G, dat.B ] ) ); 

    env.setParam("radiuses", dat.RADIUS || [] );
    env.setParam("count",env.params.positions.length / 6);
    env.signal("changed");
  })
}

// добавляет input, подразумевая под этим data-frame
// считаем это универсальной структурой (попыткой ее создать)
export function mesh_df_input( env ) {
  env.onvalue("input",(df) => {
    console.log("gonna paint df=",df);
    var dat = df;
    if (dat.XYZ || dat.positions)
      env.setParam("positions", dat.XYZ || dat.positions );  
    else if (dat.X && dat.Y && dat.Z && dat.X2 && dat.Y2 && dat.Z2 && dat.X3 && dat.Y3 && dat.Z3)
      env.setParam("positions", utils.combine( [ dat.X, dat.Y, dat.Z,
                                                 dat.X2, dat.Y2, dat.Z2,
                                                 dat.X3, dat.Y3, dat.Z3 ] ) );
    else
      env.setParam("positions", utils.combine( [ dat.X, dat.Y, dat.Z ] ) );

    if ( dat.indices)
      env.setParam("indices",dat.indices);

    if (dat.colors)
      env.setParam("colors", dat.colors );
    else
    if (dat.R && dat.G && dat.B)
      env.setParam("colors", utils.combine( [ dat.R, dat.G, dat.B ] ) );

    env.setParam("count",env.params.positions.length / 3);
    env.signal("changed");
  });
}

/////////////////////////// рисователь нормалей
import { VertexNormalsHelper } from './three.js/examples/jsm/helpers/VertexNormalsHelper.js';
/*
export function render_normals( env ) {
  env.feature("lib3d_visual");

  let unsub1 = env.host.on("normals-recomputed",(threejsobj) => {

      const helper = new VertexNormalsHelper( threejsobj, 2, 0x00ff00, 1 );
      env.setParam("output",helper );
  });
  env.on("remove",() => {
    unsub1();
  })
}
*/

/* 
// выяснилось что а как мы об изменении то узнаем? в three-js нету сигналов никаких..
// можно конечно change объекта ловить, но это получается на все его change-ы?
// тем более что нормали это отд сигнал..
export function render_normals( env ) {
  env.feature("lib3d_visual");

  function make(threejsobj) {
      if (threejsobj?.geometry?.attributes?.normal) {
        const helper = new VertexNormalsHelper( threejsobj, 2, 0x00ff00, 1 );
        env.setParam("output",helper );
      }
      else
      {
         setTimeout( () => make(threejsobj), 1000 );
      }
    }  

  env.onvalue("input", make );
  
}
*/

// создает объект, рисующий нормали другого меш-объекта
// вход input ссылка на output того объекта
export function render_normals( env ) {
  env.feature("lib3d_visual");

  function make(threejsobj) {
      if (threejsobj?.geometry?.attributes?.normal) {
        //let col = env.params.color;
        let helper = new VertexNormalsHelper( threejsobj, 2, 0x00ff00, 1 );
        env.setParam("output",helper );
      }
      /*
      else
      {
         setTimeout( () => make(threejsobj), 1000 );
      }
      */
    }  

  let unsub1 = () => {};
  env.onvalue("input", (vzmesh) => {
    unsub1();
    unsub1 = vzmesh.on("normals-recomputed",make );
    if (vzmesh.params.output) make( vzmesh.params.output );
  } );

  env.on("remove",() => {
    unsub1();
  })

  env.onvalues(["color","output"],(v,helper)=> {
     helper.material.color = utils.somethingToColor(v);
     helper.material.needsUpdate = true;    
  });

  env.addSlider("length-of-normal",1,0.5, 10, 0.1);
  env.onvalues(["length-of-normal","output"],(v,helper)=> {
    helper.size=v;
    helper.update(); // получается у нас двойной пересчет...
  });
}
