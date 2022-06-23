import setup_anim from "./animations-interface.js";
import setup_caching from "./caching.js";
import * as utils from "./threejs-utils.js";
import * as THREE from '../../three.js/build/three.module.js';

export function setup( vz,m ) {
  vz.register_feature_set( m )
}

// https://threejs.org/docs/#examples/en/loaders/GLTFLoader

/* input
     src - путь к модели
   output
     output - threejs сцена модели

   тут опять смешались кони, люди.. по идее - отдельно бы parser, отдельно рисователь..
   parser при этом может выдавать какую-то сильно внутреннюю штуку..

*/

export function render_gltf( obj ) {
  obj.feature("lib3d_visual");

  var dir = import.meta.url.substr( 0,import.meta.url.lastIndexOf("/") ) 

/* вот опять непонятная история
   вроде бы цвет это история про материал.. таки.. а не про объект...
   может управление цветом вынести следует в модификатор?
   и пусть он оттуда материалом рулит..
   но опять же а как удобно пользователю..
   впрочем может быть ему будет и удобно - выбор объекта - добавка Раскрасить - выбираем цвет..

  obj.addSlider( "opacity", 100,0,100,1,function(v) {
    obj.opacity = v / 100.0;
  });
*/

  // попробуем юзать scale3d..  
  /*
  obj.addSlider( "scale", 1, 0.1, 10, 0.1,function(v) {
      //obj.scale.set(v,v,v);
      obj.scale=v;
  });
  */

  obj.setParam("color",[0,0,0]); // что-то белое по умолчанию забеляет..
  obj.onvalue( "color",function(c) {
      obj.colors = c;
  })

  obj.addFile("src");

    var opacity=1;
    Object.defineProperty(obj, 'opacity', {
      get: function() { return opacity },
      set: function(v) {
        opacity=v; 
        if (!obj.gltf) return;
        utils.setMaterialOpacity( obj.gltf.scene, opacity );
        }
    });
    
    var colors=[];
    var colors_assigned = [];
    Object.defineProperty(obj, 'colors', {
      get: function() { return colors },
      set: function(v) {
        colors=v;
        if (!obj.gltf) return;
        
        // optimization
        if (colors_assigned[0] == v[0] && colors_assigned[1] == v[1] && colors_assigned[2] == v[2]) return;
        // optimization 2 : real case - points game assigns colors changing very slowly 10 times per second
        if (Math.abs(colors_assigned[0]-v[0]) + Math.abs(colors_assigned[1]-v[1]) + Math.abs(colors_assigned[2]-v[2]) < 0.01) return;
        
        //console.log("CC!",v,colors_assigned);
        colors_assigned = colors.slice();
        
        if (colors.length > 0) {
          //debugger;
          //utils.setMaterialColorEmissive( obj.gltf.scene, new THREE.Color( colors[0], colors[1], colors[2] )  );
          var w = 0.5;
          // var w = 1.0;
          var c = new THREE.Color( colors[0]*w, colors[1]*w, colors[2]*w )
          utils.traverseMaterials( obj.gltf.scene, function(m) {
            m.emissive = c;
            /* Majid idea is great!
            m.wireframe = true;
            m.wireframeLinewidth = 2;
            m.metalness = 1.0;
            */
            
            //m.color = c;
          });
        }
        // are we in need to undo colors?...
        }
    });
    
    // робит только для 1 позиции (т.е. массива из 3 чисел)
    var positions=[0,0,0];
    Object.defineProperty(obj, 'positions', {
      get: function() { return positions },
      set: function(v) { 
        positions=v;
        // debugger;
        if (!obj.gltf) return;
        obj.gltf.scene.position.set( v[0],v[1],v[2] ); 
      }
    });
    
    // робит только для 1 позиции (т.е. массива из 3 чисел)
    var rotations=[0,0,0];
    Object.defineProperty(obj, 'rotations', {
      get: function() { return rotations },
      set: function(v) { 
        rotations=v;
        
        // debugger;
        if (!obj.gltf) return;
        if (v && v.length >= 3)
         obj.gltf.scene.rotation.set( v[0],v[1],v[2] ); 
      }
    });

    obj.onvalue("positions",(v) => {
      obj.positions = v;
    });
    obj.onvalue("rotations",(v) => {
      obj.rotations = v;
    });
    // чисто теоретически эти куски смело выносим в модификаторы.. так-то...


    // на случай если управлять visible этой модели
    //var myGroup = new THREE.Group();
    //threejs.scene.add( myGroup );

    function clear() {
      if (obj.gltf) {
        // console.log("GLTF removing",obj.gltf.scene);
        // threejs.scene.remove( obj.gltf.scene );
        utils.disposeObjectTree( obj.gltf.scene );
      }
      obj.gltf = undefined;
      obj.sceneObject = undefined;
    }

    // переделали калбеки на промисы - зато сможем их кешировать если захотим
    obj.doload = function(loader, src) {
      var p = new Promise(function(resolve,reject) {
        loader.load( src, function ( gltf ) {
          resolve( gltf );
        });
      });
      return p;
    }

    /////////////////////////////
    obj.onvalue("src",function() {
    console.log("src changed", obj.getParam("src") );

    // todo: move imports to doload?
    // btw think something about caching on local File's

    
    let threejs_url = dir + "/../../three.js";
    import( threejs_url + "/examples/jsm/loaders/GLTFLoader.js").then(function(m1) {
    import( threejs_url + "/examples/jsm/loaders/DRACOLoader.js").then(function(m2) {
      // Instantiate a loader
      const loader = new m1.GLTFLoader();

      // Optional: Provide a DRACOLoader instance to decode compressed mesh data
      const dracoLoader = new m2.DRACOLoader();
      dracoLoader.setDecoderPath( dir+'/draco/' );
      loader.setDRACOLoader( dracoLoader );

      var src = obj.getParam("src");
      console.log("going to load",src );
      
      if (src instanceof File) {
            src = URL.createObjectURL( src );
            // todo revoke
      }
      else if (!src.length) {
        console.error("gltf: src has no length and not a file! src=",src);
        return;
      }

      obj.doload( loader, src ).then( function( gltf ) {
          if (gltf.scene) gltf.scene.$viewzavr_parent_obj = obj;
          //console.log( "loaded gltf",gltf );
          clear();

          obj.gltf = gltf;
          obj.sceneObject = gltf.scene;
          
          // if object already removed - do not do anything any more!
          if (obj.removed) {
            clear(); // but call clear on loaded data!
            return;
          }
          
          obj.scale = obj.scale;
          obj.opacity = obj.opacity;
          obj.colors = obj.colors;
          obj.positions = obj.positions;
          obj.rotations = obj.rotations;
          
          obj.signal( "loaded" );

          obj.setParam("output",gltf.scene);

          gltf.animations; // Array<THREE.AnimationClip>
          gltf.scene; // THREE.Group
          gltf.scenes; // Array<THREE.Group>
          gltf.cameras; // Array<THREE.Camera>
          gltf.asset; // Object

        });

      });
    });
    
    }); // trackParam src
    
    
    obj.chain("remove",function() {
      clear();
      this.orig();
    });
    
    /////////////////////////////
    setup_anim( obj ); // feature..
    setup_caching( obj ); // feature..
      
    return obj;
} // addGltf


