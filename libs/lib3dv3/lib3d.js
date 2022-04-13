import * as THREE from './three.js/build/three.module.js';
import * as utils from "./utils.js";

export function setup(vz, m) {
  vz.register_feature_set( m );
}

export function view3d( env ) {
  env.setParam("tag","canvas");
  env.feature("dom");
  //env.setParam("dom_style_zIndex",-1) 
}

export function render3d( env ) {
  
  env.scene = new THREE.Scene();
  env.setParam( "output",env.scene ); // вот, теперь у нас render3d выдает на выход сцену,
  // и это можно тоже где-то использовать - пожалуйста.. (непонятно зачем но забавно)
  // хотя может он и рендерер должен выдавать.. (но он и выдает..)

  // todo ориентироваться на dom-размеры..
  if (!env.params.camera) {
    var camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.1, 10000000 );
    env.setParam("camera",camera);    
  }

  //env.setParamOption("camera","internal",true);
  //env.renderer;

  let installed_w, installed_h;

  ///////////////////////////////////////  
  var unsub_target=()=>{};
  env.onvalue("target",(target) => {
    unsub_target();
    // тут еще пока вопросы, на что подписываться - на output (и там ф-я) или на dom (но это типа внутреннее же)
    unsub_target = target.onvalue("dom",(dom) => {
      //var dom = target?.params?.output || dom;
      
      if (dom.apply) dom=dom(); // там может быть функция сидит
      env.setParam("target_dom",dom); // это будет использоваться всяким orbit-control кроме всего
    });
  });
  env.on("remove",unsub_target);

  ///////////////////////////////////////
  env.onvalue("target_dom",(dom) => {
      
      if (env.renderer) env.renderer.dispose();

      env.renderer = new THREE.WebGLRenderer( {canvas: dom});
      env.setParam("renderer",renderer);
      //animate(); -- вынесено наружу, всегда рисуем
  });
  env.on("remove",() => {
    if (env.renderer) env.renderer.dispose();    
  })
  
  function animate() {
    requestAnimationFrame( animate );
    if (!env.renderer) return; // нечего рисовать то

    var cam = env.params.camera;
    if (cam.params) cam = cam.params.output; // случай когда камеру залинковали на объект
    // т.е render3d camera=@somecam

    // фича - управление размерами. Альтернативно можно сделать Resize Observer Api
    // и опять вечный вопрос компоновки. вот жеж оно опять вылазиет
    // пишем фичу - и надо сюда вписать и код выше. надо бы как-то по-другому..
    // хотя бы башню функций с приоритетами или что.. кстати почему у меня до сих пор такой нет
    // были начатки в cu..
    let de = env.renderer.domElement;
    if (de.clientWidth != installed_w || de.clientHeight != installed_h) {
      installed_w = de.clientWidth;
      installed_h = de.clientHeight;

      // вот тут криминал - мы пишем в камеру которую могут использовать и другие рендереры
      // но можно конечно переписывать каждый раз мы не гордые

      if (installed_h > 0) {
        cam.aspect = installed_w / installed_h;
        cam.updateProjectionMatrix();  
      }

      env.renderer.setSize( installed_w,installed_h, false );
    }  
    // если делаем на каждом такте то ном, однако..
    cam.aspect = installed_w / installed_h;
    cam.updateProjectionMatrix();  

    env.renderer.render( env.scene, cam );
  }
  animate(); // поехали с орехами..

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

    // todo можно будет сделать что render выдает свою scene

  }, () => {
    nested_items.clear();

    // времянка - шобы свет мешей работал
    
    const pointLight = new THREE.PointLight( 0xffffff, 1.5 );
    pointLight.position.set( 0, 100, 90 );
    nested_items.add( pointLight );        
    
    var light = new THREE.AmbientLight( 0x444444 );
    //var light = new THREE.AmbientLight( 0xffffff );
    nested_items.add( light );
    
  } )
  
  // теперь у нас в сцене есть то что задали во вложенных окружениях

  // фича - рендерить объект (сцену) указанную в параметре
  // пусть это будет параметр input для примера
  env.onvalue("input",update_scene)
  //env.onvalue("scene",update_scene)

  function update_scene() {
    env.scene.clear();
    // это то что рендерера просят нарисовать, вложив в нево объекты
    env.scene.add( nested_items );
    // это то что рендерера попросили нарисовать явно
    if (env.params.input?.isObject3D)
        env.scene.add( env.params.input );
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
  env.setParamOption("rescan_children_for_3d","internal",true)

  rescan();

  //env.object3d = object3d;
  if (!env.params.output)
     env.setParam( "output", object3d );

  env.addCheckbox("visible",true);

  env.onvalues(["output","visible"],(so,vis) => {
    so.visible = vis;
  });
}

/*
export function group3d( env ) {
  env.feature("node3d");
  env.setParam("output", env.object3d );
}
*/

// monitor_children_output занимается тем что мониторит окружения детей
// на предмет параметра output.
// когда видит какие-то изменения (дети изменились, или output чей-то изменился)
// то производит пересбор.
// clear_func - вызывается перед началом пересбора, а затем идет found_func на каждый найденный output
// и затем finish_func - сбор закончен
export function f_monitor_children_output( env, opts={} ) {
  
  var monitor_children_output = ( found_func, clear_func, finish_func ) => {
    clear_func ||= ()=>{};
    finish_func ||= ()=>{};

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
      finish_func();
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
  var cam = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.1, 10000000 );
  cam.vrungel_camera_env = env;
  // гуи
  env.addArray( "pos", [], 3 );
  env.addArray( "center", [], 3 );  

  env.onvalue( "pos", (v) => {
    console.log("onval pos",v)
    cam.position.set( v[0],v[1],v[2] );
  })
  env.onvalue( "center", (v) => {
    
    cam.lookAt(new THREE.Vector3(( v[0],v[1],v[2] )));
  })

  // todo переделать это просто под установку, я думаю
  // Бог уж с ней с камерой.
  env.addCmd("load_from_threejs",(ismanual,target) => {

    env.setParamWithoutEvents( "pos", [cam.position.x,cam.position.y,cam.position.z] );
    env.setParamManualFlag("pos",ismanual);
    if (target) { // плохонько но пока сойдет
      env.setParamWithoutEvents( "center", [target.x,target.y,target.z] );
      env.setParamManualFlag("center",ismanual);
    }
  });

  env.setParam("output",cam );
}

import {OrbitControls} from "./three.js/examples/jsm/controls/OrbitControls.js";

export function orbit_control( env ) {
  // смотрим на камеру верхнего окружения
  env.linkParam("camera","..->camera");

  env.onvalue("camera",update);
  env.ns.parent.onvalue("target_dom",update);

  var cc;
  function update() {
    var c = env.params.camera;
    if (c?.params)
        c = c.params.target_dom;
    var dom = env.ns.parent.params.target_dom;
    //if (typeof(dom) == "function") dom = dom(); // фишка такая
    // т.е. родителем должен быть некто
    if (!dom) {
      console.log("lib3d:orbit-control: parent.target_dom is blank!")
      return;
    };
    if (!c) return;

    if (cc) cc.dispose();
    
    cc = new OrbitControls( c, dom );

    cc.addEventListener( 'change', function() {
        if (c.vrungel_camera_env)
          c.vrungel_camera_env.load_from_threejs( true, cc.target );
          // так-то можно и аргумент - камеру )))
        //console.log( "oc changbed",c);
        //c.setParam
    });
  }

}
