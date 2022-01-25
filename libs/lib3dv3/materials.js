import * as THREE from './three.js/build/three.module.js';
import * as utils from "./utils.js";

export function setup(vz, m) {
  vz.register_feature_set( m );
}

///////////////////// набор окружений про материалы
// output = материал threejs

export function mesh_basic_material ( env ) {
  env.feature( "mesh_material_common");

  var material = new THREE.MeshBasicMaterial( {
      //ambient: 0xffffff,
      side: THREE.DoubleSide
  } );

  env.setParam("output",material);
}

export function mesh_material_common ( env ) {
  env.addColor("color",[ 1, 1, 1] );
  env.onvalues(["color","output"],(v,material) => material.color.setRGB( v[0],v[1],v[2] ) );

  env.addSlider("opacity",1,0,1,0.01 );
  env.onvalues(["opacity","output"],(v,material) => {
    material.opacity=v;
    material.transparent = (v < 1.0) ? true : false;
    //material.transparent = true;
    //material.needsUpdate = true;
    // короче вот этот needsUpdate это правильно, но - без него идет полезный глюк для отображения Дубинса с чередующимися нормалями
  });
}

export function mesh_pbr_material ( env ) {
  env.feature( "mesh_material_common");

  var material = new THREE.MeshStandardMaterial( {
      specular: 0x888888,
      emissive: 0x000000,
      shininess: 250,
      //ambient: 0xffffff,
      side: THREE.DoubleSide
  } );

  env.setParam("output",material);


  env.addColor("emissive",[ 0,0,0 ] );
  env.onvalue("emissive",(v) => material.emissive.setRGB( v[0],v[1],v[2] ) );

  env.addSlider("metalness",0,0,1,0.01,(v) => {
    material.metalness=v;
  })
  env.addSlider("roughness",1,0,1,0.01,(v) => {
    material.roughness=v;
  })

  env.addCheckbox("flat_shading",false,(v) => {
    material.flatShading=v;
    material.needsUpdate = true;
  });
}

export function mesh_phong_material ( env ) {
  env.feature( "mesh_material_common");  

  var material = new THREE.MeshPhongMaterial( {
      specular: 0x888888,
      emissive: 0x000000,
      shininess: 250,
      //ambient: 0xffffff,
      side: THREE.DoubleSide
  } );

  env.addColor("specular",[ 0.5, 0.5, 0.5] );
  env.onvalue("specular",(v) => material.specular.setRGB( v[0],v[1],v[2] ) );

  env.addCheckbox("flat_shading",false,(v) => {
    material.flatShading=v;
    material.needsUpdate = true;
  })  

  env.setParam("output",material);
}

export function mesh_lambert_material ( env ) {
env.feature( "mesh_material_common");  


  var material = new THREE.MeshLambertMaterial( {
      emissive: 0x000000,
      shininess: 250,
      //ambient: 0xffffff,
      side: THREE.DoubleSide
  } );

  env.setParam("output",material);

}
