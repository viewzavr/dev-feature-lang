export function setup(vz, m) {
  vz.register_feature_set( m );
}

export function render3d( env ) {
  
  env.scene = new THREE.Scene();
  env.setParam( "scene",env.scene );

  // todo ориентироваться на dom-размеры..
  if (!env.params.camera) {
    var camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.1, 1000 );
    env.setParam("camera",camera);    
  }

  //env.setParamOption("camera","internal",true);
  //env.renderer;

  env.setParam("tag","canvas");
  env.feature("dom");
  env.onvalue("dom",(dom) => {
    env.renderer = new THREE.WebGLRenderer( {canvas: dom});
    env.setParam("renderer",renderer);
    animate();
  });

  function animate() {
    requestAnimationFrame( animate );
    var cam = env.params.camera;
    if (cam.params) cam = cam.params.output; // случай когда камеру залинковали на объект
    // т.е render3d camera=@somecam

    env.renderer.render( env.scene, cam );
  }

  env.feature("renderer_bg_color");

  // фича - собрать объекты вложенные в render3d
  //env.feature("node3d",{output_name:"nested_object3d"});
  var nested_items = new THREE.Object3D();
  //env.feature("node3d",{object3d:nested_items});


  var mon = env.feature("f_monitor_children_output");
  //env.monitor_children_output;
  mon( (o) => {
    if (o.isCamera) {
      env.setParam("camera",o);
      return;
    }
    if (o.isObject3D)
      nested_items.add(o);

  }, () => nested_items.clear() )
  
  // теперь у нас в сцене есть то что задали во вложенных окружениях

  // фича - рендерить объект (сцену) указанную в параметре
  // пусть это будет параметр input для примера
  env.onvalue("input",update_scene)
  env.onvalue("scene",update_scene)

  function update_scene() {
    env.scene.clear();
    // это то что рендерера просят нарисовать, вложив в нево объекты
    env.scene.add( nested_items );
    // это то что рендерера попросили нарисовать явно
    if (env.params.input?.isObject3D)
        env.scene.add( env.params.input );
    if (env.params.scene?.isObject3D)
        env.scene.add( env.params.scene );

  }

  update_scene();

  // todo вот тут надо подумать, сцена тут на входе или что
  // короче на вход сцена идет или кто

}

// сиречь узел. занимается тем что собирает вложенные окружения.
export function node3d( env, opts={} ) {
  var object3d = opts.object3d || new THREE.Object3D();

  env.on("childrenChanged", rescan );

  var tracked=[];
  function rescan() {

    tracked.forEach( (t) => t() ); tracked=[];
    
    object3d.clear();
    for (var c of env.ns.getChildren()) {
      
      tracked.push( c.trackParam("output",rescan) ); // следим за изменениями
      var o = c.params.output;
      // todo func?
      if (!o?.isObject3D) continue;
      object3d.add( o );
    }

  }

  env.addCmd("rescan_children_for_3d",rescan);

  rescan();

  //env.object3d = object3d;
  //env.setParam(opts.output_name || "output", object3d );
}

// сиречь узел. занимается тем что собирает вложенные окружения.
export function f_monitor_children_output( env, opts={} ) {
  
  var monitor_children_output = ( found_func, clear_func ) => {
    clear_func ||= ()=>{};

    env.on("childrenChanged", rescan );

    var tracked=[];
    function rescan() {

      tracked.forEach( (t) => t() ); tracked=[];
    
      clear_func();
      for (var c of env.ns.getChildren()) {
        tracked.push( c.trackParam("output",rescan) ); // следим за изменениями
        var o = c.params.output;
        if (!o) continue;
        // todo func?
        found_func( o );
      }
    }
  rescan();
  }

  //env.monitor_children_output = monitor_children_output;
  return monitor_children_output;
  //env.object3d = object3d;
  //env.setParam(opts.output_name || "output", object3d );
}

export function renderer_bg_color( env ) {
  env.addColor( "bgcolor",[0,0,0] );
  var unbind = () => {};
  env.onvalue("renderer",(r) => {
    unbind();
    unbind = env.onvalue( "bgcolor", (v) => {
      var opacity = 1.0;
      env.renderer.setClearColor( utils.somethingToColor(v), opacity);
    });
  });

}

export function camera3d( env ) {
  var cam = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.1, 1000 );
  // гуи
  env.addArray( "pos", [], 3 );
  env.addArray( "center", [], 3 );  

  env.onvalue( "pos", (v) => {
    cam.position.set( v[0],v[1],v[2] );
  })
  env.onvalue( "center", (v) => {
    cam.lookAt(new THREE.Vector3(( v[0],v[1],v[2] )));
  })

  env.setParam("output",cam );
}

export function orbit_control( env ) {
  // смотрим на камеру верхнего окружения
  env.linkParam("camera","..->camera");

  env.onvalue("camera",update);

  var cc;
  function update() {
    var c = env.params.camera;
    if (c?.params)
        c = c.params.output;
    var dom = env.ns.parent.params.output;
    if (typeof(dom) == "function") dom = dom(); // фишка такая
    // т.е. родителем должен быть некто
    if (!dom) return;
    if (!c) return;

    if (cc) cc.dispose();

    
    cc = new THREE.OrbitControls( c, dom );

    //sceneControl.addEventListener( 'change', function() {
  }
  
}

import * as utils from "./utils.js";

export function points0( env ) {
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

export function lines0( env ) {
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
  env.linkParam("output","lines-env->output");
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


/* первая версия
export function render3d( env ) {
  env.scene = new THREE.Scene();
  env.camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.1, 1000 );
  //env.renderer;
  console.log("VVV")

  env.setParam("tag","canvas");
  env.feature("dom");
  env.onvalue("dom",(dom) => {
    env.renderer = new THREE.WebGLRenderer( {canvas: dom});
    env.setParam("renderer",renderer);
    animate();
  });

  function animate() {
    requestAnimationFrame( animate );
    env.renderer.render( env.scene, env.camera );
  }

  env.feature("renderer_bg_color");

  // фича - собрать объекты вложенные в render3d
  env.feature("node3d");
  // теперь у нас в сцене есть то что задали во вложенных окружениях

  // фича - рендерить объект (сцену) указанную в параметре scene
  env.onvalue("scene",update_scene)

  function update_scene() {
    env.scene.clear();
    env.scene.add( env.object3d );
    env.scene.add( env.params.scene );
  }

  update_scene();

  // todo вот тут надо подумать, сцена тут на входе или что
  // короче на вход сцена идет или кто

}
*/