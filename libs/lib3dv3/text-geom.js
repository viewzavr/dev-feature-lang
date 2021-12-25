import * as utils from "./utils.js";

export function setup(vz, m) {
  vz.register_feature_set( m );
}

export function text3d( env ) {
  var material = new THREE.MeshPhongMaterial( { color: 0xffffff } ); // front , flatShading: true
  var group = new THREE.Group();
  env.setParam("output",group ); // я это сделал чтобы позицию понимаешь сохранять можно было..

  env.onvalues(["text","loaded_font"],(t,font) => {
        var geometry = new TextGeometry( t, {
          font: font,
          size: 80,
          height: 5,
          curveSegments: 12,
          bevelEnabled: true,
          bevelThickness: 10,
          bevelSize: 8,
          bevelOffset: 0,
          bevelSegments: 5
        } );

        geometry.computeBoundingBox();
        const centerOffset = - 0.5 * ( geometry.boundingBox.max.x - geometry.boundingBox.min.x );

        var textMesh1 = new THREE.Mesh( geometry, material );

        textMesh1.position.x = centerOffset;
        textMesh1.position.y = 0; //hover;
        textMesh1.position.z = 0;

        group.clear();
        group.add( textMesh1 );
        //env.setParam("output",group );
        env.signalParam("output");
  })

  const loader = new THREE.FontLoader();

  loader.load( 'fonts/helvetiker_regular.typeface.json', function ( font ) {  
    env.setParam("loaded_font",font);
  });

  env.onvalue("color",(v) => {
     material.color = utils.somethingToColor(v);
     material.needsUpdate = true;
  });

  env.feature("lib3d_visual");

  // todo потом эти все вещи про df вытащить в отдельный фиче-слой
  // и аппендом их добавлять
  //env.feature( "lines_df_input" );
}