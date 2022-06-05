import * as THREE from './three.js/build/three.module.js';
import { FontLoader }   from './three.js/examples/jsm/loaders/FontLoader.js';
import { TextGeometry } from './three.js/examples/jsm/geometries/TextGeometry.js';
import * as utils from "./utils.js";

export function setup(vz, m) {
  vz.register_feature_set( m );
}

export function text3d_one( env ) {
  var material = new THREE.MeshPhongMaterial( { color: 0xffffff } ); // front , flatShading: true
  var group = new THREE.Group();
  env.setParam("output",group ); // я это сделал чтобы позицию понимаешь сохранять можно было..

  env.addSlider("size",2,0,10,0.1 );

  env.onvalues(["text","loaded_font","size"],(t,font,size) => {
        t = t.toString(); // а то числы подают

        var geometry = new TextGeometry( t, {
          font: font,
          size: size,
          height: size/2,
          curveSegments: 12,
          bevelEnabled: false,
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

  const loader = new FontLoader();

  var path = env.vz.getDir( import.meta.url ) + "three.js/examples/";
  loader.load( path+'fonts/helvetiker_regular.typeface.json', function ( font ) {  
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


// вход: lines - массив строк [str,str,str...]
//       positions - массив положений [x,y,z,x,y,z,...]
//       colors - массив цветов [r,g,b,r,g,b,...]
//       size - размер текста
export function text3d( env ) {
  var material = new THREE.MeshPhongMaterial( { color: 0xffffff } ); // front , flatShading: true
  var group = new THREE.Group();
  env.setParam("output",group ); // я это сделал чтобы позицию понимаешь сохранять можно было..

  env.addSlider("size",2,0,10,0.1 );

  env.onvalue("positions",(v) => {
    apply_positions();
  });
  env.onvalue("colors",(v) => {
    apply_colors();
  });

  env.onvalues(["lines","loaded_font","size"],(lines,font,size) => {
    generate( lines, font, size );
    env.signalParam("output");
  });

  function generate( lines, font, size ) {
    group.clear();
    var pos=[0,0,0];
    for (let i=0; i<lines.length; i++) {
       //position_func( i,pos );
       var m = create_one( lines[i], font, size)
       group.add( m );
    }
    apply_positions();
    apply_colors();
  }

  function apply_positions() {
     var pos = [0,0,0];
     for (var i=0; i<group.children.length; i++) {
        var m = group.children[i];
        var i3 = 3*i;
        if (env.params?.positions?.length >= i3) {
          pos[0] = env.params.positions[i3];
          pos[1] = env.params.positions[i3+1];
          pos[2] = env.params.positions[i3+2];
        } else break;

        m.position.x = m.position.x0 + pos[0];
        m.position.y = pos[1];
        m.position.z = pos[2];
     }
  }

  function apply_colors() {
    return;
     
     for (var i=0; i<group.children.length; i++) {
        var m = group.children[i];
        var i3 = 3*i;
        if (env.params.colors.length < i3) break;
        //m.material[1].color =  tri2int( env.params.colors[i3],env.params.colors[i3+1],env.params.colors[i3+2] )
        m.material[1].color = new THREE.Color( env.params.colors[i3],env.params.colors[i3+1],env.params.colors[i3+2] )
     }
  }  

  function rgb2int( r,g,b ) {
    return Math.floor(r*255) * (256*256) + Math.floor(g*255)*256  + Math.floor(b*255);
  }          

  function create_one( text, font, size ) {
    // todo вот это надо выделять в очередь
    // это и последующее назначение геометрии в меш
    // а сам меш можно создавать сразу же

    // https://threejs.org/examples/#webgl_geometry_text
    var geometry = new TextGeometry( text ? text.toString() : "", {
          font: font,
          size: size,
          height: size/2,
          curveSegments: 12,
          bevelEnabled: false,
          bevelThickness: 10,
          bevelSize: 8,
          bevelOffset: 0,
          bevelSegments: 5
        } );

        geometry.computeBoundingBox();
        const centerOffset = - 0.5 * ( geometry.boundingBox.max.x - geometry.boundingBox.min.x );

        var own_material = new THREE.MeshPhongMaterial( { color: 0xffffff } ); // front , flatShading: true

        //var textMesh1 = new THREE.Mesh( geometry, [material,own_material] );
        var textMesh1 = new THREE.Mesh( geometry, material );

        textMesh1.position.x = centerOffset;
        textMesh1.position.x0 = centerOffset;
        textMesh1.position.y = 0; //hover;
        textMesh1.position.z = 0;
    return textMesh1;
  }

  const loader = new FontLoader();

  var path = env.vz.getDir( import.meta.url ) + "three.js/examples/fonts/";
  env.addComboValue( "font_name","helvetiker_regular",
      ["helvetiker_regular","helvetiker_bold","optimer_regular","optimer_bold","gentilis_regular","gentilis_bold",
       "droid/droid_sans_regular","droid/droid_sans_bold","droid/droid_serif_regular","droid/droid_serif_bold"])

  env.onvalue("font_name",(name) => {
     // https://threejs.org/docs/#examples/en/geometries/TextGeometry
    env.setParam( "font_url",path+name+".typeface.json");
  })
  env.onvalue("font_url",(url) => {
    loader.load( url, function ( font ) {  
      env.setParam("loaded_font",font);
    });
  })

  env.onvalue("color",(v) => {
     material.color = utils.somethingToColor(v);
     material.needsUpdate = true;
  });

  env.feature("lib3d_visual");

  // todo потом эти все вещи про df вытащить в отдельный фиче-слой
  // и аппендом их добавлять
  env.feature( "texts_df_input" );
}


// добавляет input, подразумевая под этим data-frame
export function texts_df_input( env ) {
  env.onvalue("input",(df) => {
    
    var dat = df;
    env.setParam("positions", utils.combine( [ dat.X, dat.Y, dat.Z ] ) );
    if (dat.R)
      env.setParam("colors", utils.combine( [ dat.R, dat.G, dat.B ] ) );
    env.setParam("lines", dat.TEXT || [] );
    env.setParam("count",env.params.positions.length / 3);
    env.signal("changed");
  })
}