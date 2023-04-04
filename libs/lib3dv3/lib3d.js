// todo

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

///let vz_renderers_counter=0;

export function render3d( env ) {

  let w_counter=0;
  
  env.scene = new THREE.Scene();
  env.setParam( "output",env.scene ); // вот, теперь у нас render3d выдает на выход сцену,
  // и это можно тоже где-то использовать - пожалуйста.. (непонятно зачем но забавно)
  // хотя может он и рендерер должен выдавать.. (но он и выдает..)

  // todo ориентироваться на dom-размеры..
  var default_camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.01, 10000000 );
  var private_camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.01, 10000000 );
  env.setParam('private_camera',private_camera);
  /*
  if (!env.params.camera) {
    env.setParam("camera",default_camera);
  }
  */

  //env.setParamOption("camera","internal",true);
  //env.renderer;

  let installed_w=1, installed_h=1;

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

      env.renderer = new THREE.WebGLRenderer( 
        {canvas: dom, 
         preserveDrawingBuffer : true // надо для скриншотов
         ,logarithmicDepthBuffer: true  // без этого наши точки глючат.. да и поверхности глючат..
         // Early Fragment Test
        }); // alpha: true

      // надо для renderstats с учетом subrenderers
      env.renderer.info.autoReset = false;
      env.renderer.autoClear = false;

      //env.renderer.$vz_renderer_id = vz_renderers_counter++;

      env.setParam("renderer",env.renderer);
      //animate(); -- вынесено наружу, всегда рисуем
  });
  env.on("remove",() => {
    if (env.renderer) {
      console.log('disposing renderer',env.renderer)
      env.renderer.dispose();    
    }
  })

  env.onvalue('camera',(cam) => {
    if (cam?.params) 
        cam = cam.params.output; // случай когда камеру залинковали на объект
    if (!cam || !cam.isCamera) return;

    cam.add( private_camera ); // рулите мноею

    //cam.updateWorldMatrix(true,true);
  })
  
  function animate() {
    requestAnimationFrame( animate );
    if (!env.renderer) return; // нечего рисовать то

/*
    var cam = env.params.camera;
    if (cam?.params) 
        cam = cam.params.output; // случай когда камеру залинковали на объект
    if (!cam || !cam.isCamera) 
         cam=default_camera;
*/         
    let cam = private_camera;
    // т.е render3d camera=@somecam

    // фича - управление размерами. Альтернативно можно сделать Resize Observer Api
    // и опять вечный вопрос компоновки. вот жеж оно опять вылазиет
    // пишем фичу - и надо сюда вписать и код выше. надо бы как-то по-другому..
    // хотя бы башню функций с приоритетами или что.. кстати почему у меня до сих пор такой нет
    // были начатки в cu..
    let de = env.renderer.domElement;
    if (de.clientWidth != installed_w || de.clientHeight != installed_h) {
    //if (Math.abs(de.clientWidth - installed_w) + Math.abs(de.clientHeight-installed_h) > 100) {
      installed_w = de.clientWidth;
      installed_h = de.clientHeight;

      // вот тут криминал - мы пишем в камеру которую могут использовать и другие рендереры
      // но можно конечно переписывать каждый раз мы не гордые

      if (installed_h > 0) {
        cam.aspect = installed_w / installed_h;
        // console.log("updated cam aspect", cam.aspect)
        cam.updateProjectionMatrix();  
      }

      //console.log("renderer setsize",installed_w,installed_h,de, de.offsetWidth)
      env.renderer.setSize( installed_w,installed_h, false );
    }  
    // если делаем на каждом такте то ном, однако..
    // непонятно зачем делать это на каждом шаге..
    // и плюс выяснилось нужна проверка что там не 0, а то ломается матрица проецирования
    // выяснилось - понятно зачем. потому что может быть несколько рендереров, а камера одна
    /*
    cam.aspect = installed_w / installed_h;
    if (isNaN( cam.aspect))
      debugger;
    cam.updateProjectionMatrix();  
    */
    //cam.updateMatrixWorld();
    cam.updateWorldMatrix(true);
    // todo - оптимизировать это, там стока не надо умножений
    // передать final-camera во фрустум куллер

    // хак временных (хыхы)
    update_scene();

    // мы перешли на ручной учет статистики, https://threejs.org/docs/#api/en/renderers/WebGLRenderer.info
    // сейчас она общая для всех окошек стала
    // а без этого reset она будет для последнего отрендеренного окошка
    env.renderer.info.reset();
    env.renderer.clear(); // вручную чистим - чтобы subrender-еры не чистили

    env.renderer.render( env.scene, cam );

    // а теперь добавим вот чо
    if (env.params.subrenderers) {
      for (let r of env.params.subrenderers)
        r.subrender( env.renderer );
    }

    env.emit("frame",env.renderer); // ТПУ
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
    /* вроде как не надо - ниже само добавится
    if (env.params.input?.isObject3D)
        env.scene.add( env.params.input );
    */    
    add( env.params.input );
    // и еще списком - но может это стоит в node3d отдать..

    function add( item ) {
      if (!item) return;

      if (item.isObject3D)
        env.scene.add(item);
      else
        if (Array.isArray(item))
          item.forEach( add );
      else {
        // общемто зачем нам это
        if (w_counter++ < 100)
            console.error("render3d: wrong input item", env.getPath(), "item=",item)  
      }
    }
    

    /*
    if (Array.isArray(env.params.input)) {
      for (let q of env.params.input)
        if (q?.isObject3D)
           env.scene.add( q );
    }      
    */
  }

  update_scene();

  // todo вот тут надо подумать, сцена тут на входе или что
  // короче на вход сцена идет или кто

}

/*
  выяснилось что если много рендереров то браузер ломается (тормоза сильные и webglcontext lost)
  поэтому новая идея - делает 1 renderer большой на фон и несколько псевдо-рендереров
  в духе примера threejs  https://threejs.org/examples/webgl_multiple_elements.html

  получается такая картина:
  a: view3d/render3d - ставится на фон
  b: dom/subrenderer - размещаются где нужны рендер "окна" поверх view3d
  и ставится связь: a subrenderers=*b

  todo тут можно отнаследоваться от renderer и заменить только функцию рендеринга
  интересно как это связано с composition over inher, когда объекты получают на управление другие
  объекты (сиречь пачку каналов)..
*/
export function subrenderer( env,opts )
{
   let w_counter = 0;
   
  env.scene = new THREE.Scene();
  env.setParam( "output",env.scene ); // вот, теперь у нас render3d выдает на выход сцену,
  // и это можно тоже где-то использовать - пожалуйста.. (непонятно зачем но забавно)
  // хотя может он и рендерер должен выдавать.. (но он и выдает..)

  // todo ориентироваться на dom-размеры..
  let camin = 0.00001
  var default_camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, camin, 10000000 );
  var private_camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, camin, 10000000 );
  
  //private_camera = new THREE.OrthographicCamera( window.innerWidth / - 2, window.innerWidth / 2, window.innerHeight / 2, window.innerHeight / - 2, 0.01, 10000000 );
  //console.log("pr",private_camera)
  
  private_camera.layers.enable(1);

  env.setParam('private_camera',private_camera);
  // в threejs камера завязана на размеры экраны (внезапно)
  // отсюда следует что если мы хотим одну камеру на несколько областей то надо ввести иерархию
  // наверху эта одна камера, а внизу субкамеры которые следуют за той и учитывают размеры области


  // итого иерархия это camera => private_camera и вот уже private_camera учитывает размеры области и используется при рендеринге
  // а получается положение свое она берет из camera (как ее ребенок) (что нам и требуется)

  ////////////////////////////////////// тема камеры
  env.onvalue('threejs_camera',(cam) => {
    if (!cam || !cam.isCamera) return;
    
    // threejs таков, что чтобы orbitcontrol работал он должен работать с правильным типом камеры
    // поэтому мы пересоздаем целевую камеру каждый раз при смене режима орто-неорто
    // но и далее - необходимо чтобы и финальная камеры была такого же типа
    // поэтому вот пересоздаем
    //console.log("sr cam changed",cam)
    if (cam.isPerspectiveCamera && private_camera.isOrthographicCamera) {
      private_camera = new THREE.PerspectiveCamera( 75, 1, camin, 10000000 );
      installed_w = installed_h = 1
      //console.log("sr switching to persp");
    } else
    if (private_camera.isPerspectiveCamera && cam.isOrthographicCamera) {
      private_camera = new THREE.OrthographicCamera( 0,1,1,0, -10000, 10000000 );
      installed_w = installed_h = 1
      //console.log("sr switching to ortho");
    }
    private_camera.layers.enable(1);
    env.setParam('private_camera',private_camera);

    cam.add( private_camera ); // рулите мноею

    //cam.updateWorldMatrix(true,true);
  })  

  let installed_w=1,installed_h=1;

  env.subrender = function (external_renderer)
  {
    if (!env.params.target_dom) return;
    let element = env.params.target_dom;

    let cam = private_camera;
    //debugger
    // т.е render3d camera=@somecam
    
    

    // фича - управление размерами. Альтернативно можно сделать Resize Observer Api
    // и опять вечный вопрос компоновки. вот жеж оно опять вылазиет
    // пишем фичу - и надо сюда вписать и код выше. надо бы как-то по-другому..
    // хотя бы башню функций с приоритетами или что.. кстати почему у меня до сих пор такой нет
    // были начатки в cu..
    let de = element;
    if (de.clientWidth != installed_w || de.clientHeight != installed_h) {
    //if (Math.abs(de.clientWidth - installed_w) + Math.abs(de.clientHeight-installed_h) > 100) {
      installed_w = de.clientWidth;
      installed_h = de.clientHeight;

      // вот тут криминал - мы пишем в камеру которую могут использовать и другие рендереры
      // но можно конечно переписывать каждый раз мы не гордые

      if (installed_h > 0) {
        if (cam.isOrthographicCamera) {
          cam.left = -installed_w / 2
          cam.right = installed_w / 2
          cam.top = installed_h / 2
          cam.bottom = - installed_h / 2
          //console.log("this o-cam",cam)
        }
        else
          cam.aspect = installed_w / installed_h;
        // console.log("updated cam aspect", cam.aspect)
        cam.updateProjectionMatrix();
      }
      //console.log("renderer setsize",installed_w,installed_h,de, de.offsetWidth)
    }  
    // если делаем на каждом такте то ном, однако..
    // непонятно зачем делать это на каждом шаге..
    // и плюс выяснилось нужна проверка что там не 0, а то ломается матрица проецирования
    // выяснилось - понятно зачем. потому что может быть несколько рендереров, а камера одна
    /*
    cam.aspect = installed_w / installed_h;
    if (isNaN( cam.aspect))
      debugger;
    cam.updateProjectionMatrix();  
    */
    //cam.updateMatrixWorld();

    //console.log('zz',cam.parent?.zoom )
    if (cam.parent && cam.parent?.zoom != cam.zoom) {
      cam.zoom = cam.parent.zoom // нет слов
      cam.updateProjectionMatrix();
    }
    
    cam.updateWorldMatrix(true);
    // todo - оптимизировать это, там стока не надо умножений
    // передать final-camera во фрустум куллер

    // хак временных (хыхы)
    update_scene();
  
    ///////////////////////// установка окна    



          // get its position relative to the page's viewport
          const rect = element.getBoundingClientRect();

/*
          // check if it's offscreen. If so skip it
          if ( rect.bottom < 0 || rect.top > renderer.domElement.clientHeight ||
             rect.right < 0 || rect.left > renderer.domElement.clientWidth ) {

            return; // it's off screen

          }
          */

          // set the viewport
          const width = rect.right - rect.left;
          const height = rect.bottom - rect.top;
          const left = rect.left;
          const bottom = external_renderer.domElement.clientHeight - rect.bottom;
          
          external_renderer.getViewport(orig_vp);
          external_renderer.getScissor(orig_sc);
          external_renderer.setViewport( left, bottom, width, height );
          let orig_sc_b = external_renderer.getScissorTest();
          external_renderer.setScissorTest( true );
          external_renderer.setScissor( left, bottom, width, height );
          
          external_renderer.render( env.scene, cam );

          external_renderer.setViewport( orig_vp );
          external_renderer.setScissorTest( orig_sc_b );
          external_renderer.setScissor( orig_sc );

          env.emit("frame"); // ТПУ
          //console.log(55)
  }

  let orig_vp = new THREE.Vector4(), orig_sc = new THREE.Vector4();

  /////////////////////////////////////// кандидат на вылет

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

  //////////////////////////////////////

  env.feature("renderer_bg_color");

  // фича - собрать объекты вложенные в render3d
  //env.feature("node3d",{output_name:"nested_object3d"});
  var nested_items = new THREE.Object3D();
  //env.feature("node3d",{object3d:nested_items});


  var mon = env.feature("f_monitor_children_output");
  //env.monitor_children_output;
  mon( (o) => {
    if (o.isCamera) {
      env.setParam("threejs_camera",o);
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

  // фича - рендерить объект (сцену) указанную в параметре
  // пусть это будет параметр input для примера
  env.onvalue("input",update_scene)
  //env.onvalue("scene",update_scene)

  function update_scene() {
    env.scene.clear();
    // это то что рендерера просят нарисовать, вложив в нево объекты
    env.scene.add( nested_items );
    // это то что рендерера попросили нарисовать явно
    //if (env.params.input?.isObject3D)
    //    env.scene.add( env.params.input );
    // и еще списком - но может это стоит в node3d отдать..
    // ну да, в каком-то смысле input это и является сценой.
    add( env.params.input );

    function add( item ) {
      if (!item) return;

      if (item.isObject3D)
        env.scene.add(item);
      else
        if (Array.isArray(item))
          item.forEach( add );
      else {
        // общемто зачем нам это
        if (w_counter++ < 100)
            console.error("render3d: wrong input item", env.getPath(), "item=",item)  
      }

      if (item.is_node3d)
        item.rescan_children_for_3d(); // там тож пусть порядок наведут
    }
    

    /*
    if (Array.isArray(env.params.input)) {
      for (let q of env.params.input)
        if (q?.isObject3D)
           env.scene.add( q );
    }      
    */
  }

  update_scene();
}

/*
function scan_scene_items( root_item ) {
}
*/

// сиречь узел. занимается тем что собирает вложенные окружения.
export function node3d( env, opts={} ) {
  var object3d = opts.object3d || new THREE.Object3D();

  // такой вот трюк.. мы сохраняем ссылку на функцию обновления compolang node3d - в threejs объекте. потому что потом только к нему и есть доступ у рендерера
  // но в целом это тупняк. рендерер должен рисовать не своих детей а сцену.
  object3d.is_node3d = true;
  object3d.rescan_children_for_3d = rescan; 

  if (!env.paramConnected("position"))
    env.setParam("position",[0,0,0])
  env.onvalues(["position","output"],(pos,tobj) => {
    
    tobj.position.x = pos[0]
    tobj.position.y = pos[1]
    tobj.position.z = pos[2]
  })

  env.on("childrenChanged", rescan );
  env.trackParam("input", rescan );

  var tracked=[];
  function rescan() {

    function add(item) {
        if (Array.isArray(item)) {
          item.forEach( add );
        }
        if (!item?.isObject3D) return;
        if (item.is_node3d)
          item.rescan_children_for_3d(); // там тож пусть порядок наведут      
        object3d.add( item );
      }    

    tracked.forEach( (t) => t() ); tracked=[];
    
    object3d.clear();
    // вот может не только чилдренов монитроить а и доп списки?
    for (var c of env.ns.getChildren()) {
      
      tracked.push( c.trackParam("output",rescan) ); // следим за изменениями
      var o = c.params.output;
      add( o ); // добавляем результат от этого дитя
    
    }

    // добавим еще элемент или список из инпут
    add( env.params.input )

    env.setParam("object3d_count",object3d.children.length);
  }

  env.addCmd("rescan_children_for_3d",rescan);
  env.setParamOption("rescan_children_for_3d","internal",true)

  rescan();

  //env.object3d = object3d;
  if (!env.paramAssigned("output"))
     env.setParam( "output", object3d );

  env.addCheckbox("visible",true);

  env.onvalues_any(["output","visible"],(so,vis) => {
    if (so)
       so.visible = vis ? true : false;
  });

  // добавим поведение сохранять ссылку на вз-объект
  // и поведение - по умолчанию идет слой 0
  env.onvalues_any(["output"],(output) => {
    output.$vz_object = env
    //output.layers.enable( 0 )
  })
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
  // значение znear 0.00000001 дает любопытнейший глюк збуфера
  // значение znear 0.001 ТОЖЕ дает любопытнейший глюк збуфера
  //var cam = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.001, 100000 );
  //var cam = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.01, 1000*1000 );
  
  //let width = window.innerWidth;
  //let height = window.innerHeight;
  //cam = new THREE.OrthographicCamera( width / - 2, width / 2, height / 2, height / - 2, 0.01, 1000*1000 );
  
  //cam.vrungel_camera_env = env;
  let cam
  let a1, a2;
  
  // гуи
  env.addVector( "pos", [0,0,10], 3 );
  env.addVector( "center", [0,0,0], 3 );  
  // env.addGui( {"type": "custom", "editor":"vector-editor"});
  env.addSlider("theta",0,-180,180,0.1);
  
  env.addCheckbox("ortho",false)
  env.setParam("ortho_zoom",1)
  
  env.trackParam( "ortho", recreate_camera )
  
  let camin = 0.00001
  recreate_camera()
  
  
  function recreate_camera(v) {
    // console.log("ortho=",v)
    let width = 100;
    let height = 100;

    if (v)
      cam = new THREE.OrthographicCamera( width / - 2, width / 2, height / 2, height / - 2, camin, 1000*1000 );
    else
      cam = new THREE.PerspectiveCamera( 75, width/height, camin, 1000*1000 );
    cam.vrungel_camera_env = env;
    
    if (env.params.ortho) // только в орто-режиме потому что я хочу оставаться в ск (положение камеры, точка взгляда)
        cam.zoom = env.params.ortho_zoom
    
    //console.log("recreating camera",env.getPath(),cam,"using pos",env.params.pos)

    env.setParam( "pos", env.params.pos.slice(0) )
    env.setParam( "center", env.params.center.slice(0) )
    /*
    v = env.params.pos
    cam.position.set( v[0],v[1],v[2] );
    v = env.params.center
    cam.lookAt( new THREE.Vector3( v[0],v[1],v[2] ) );
    */
    cam.updateWorldMatrix(true,true);
    cam.updateProjectionMatrix();
    env.setParam("output",cam );
  }
  env.onvalue( "ortho_zoom",(v) => {
    if (env.params.ortho)
        cam.zoom = env.params.ortho_zoom
  })

  env.onvalue( "pos", (v) => {
    if (v !== a1 && v) {
      if (isFinite(v[0]) && isFinite(v[1]) && isFinite(v[2]))
      {
        cam.position.set( v[0],v[1],v[2] );
        //cam.updateWorldMatrix(true,true);
      }
      // todo оптимизировать - вызывать на тике рендера если надо
      v = env.params.center
      cam.lookAt( new THREE.Vector3( v[0],v[1],v[2] ) );
      //cam.lookAt( new THREE.Vector3( 0,0,0 ) );
      //cam.updateProjectionMatrix();
      //console.log("camera onval pos",env.getPath(),v,cam)
    }
  })
  env.onvalue( "center", (v) => {
    //console.log("onval center",v)
    if (v !== a2 && v) {
       if (isFinite(v[0]) && isFinite(v[1]) && isFinite(v[2])) {
         cam.lookAt( new THREE.Vector3( v[0],v[1],v[2] ) );
//         cam.updateWorldMatrix(true,true);
       }
       //cam.updateProjectionMatrix();
     }
  })

  // todo переделать это просто под установку, я думаю
  // Бог уж с ней с камерой.

  env.addCmd("reset",() => {
    //console.log("env see cmd reset")
    env.setParam( "pos",[10,10,10]);
    env.setParam( "center",[0,0,0]); // look_at?
  })
  
  function get_radius() {
    return Math.sqrt( (env.params.pos[0] - env.params.center[0])*(env.params.pos[0] - env.params.center[0])
    + (env.params.pos[1] - env.params.center[1])*(env.params.pos[1] - env.params.center[1])
    + (env.params.pos[2] - env.params.center[2])*(env.params.pos[2] - env.params.center[2]) )
  }
  
  env.addCmd("look_x",() => {
    env.setParam( "pos",[env.params.center[0] + get_radius(), env.params.center[1],env.params.center[2]]); // по идее не 10 а текущий радиус
    //env.setParam( "center",[0,0,0])
  })
  
  env.addCmd("look_y",() => {
    env.setParam( "pos",[env.params.center[0] , env.params.center[1]+ get_radius(),env.params.center[2]]); // по идее не 10 а текущий радиус
    // env.setParam( "pos",[0,10,0]); // по идее не 10 а текущий радиус
    // env.setParam( "center",[0,0,0])
  })
  
  // todo tween.js прикрутить?
  env.addCmd("look_z",() => {
    // console.log("radius is", get_radius() )
    env.setParam( "pos",[env.params.center[0], env.params.center[1],env.params.center[2] + get_radius()]); // по идее не 10 а текущий радиус
//    env.setParam( "pos",[0,0,10]); // по идее не 10 а текущий радиус
//    env.setParam( "center",[0,0,0])
  })  

  env.setParamOption("external_set","visible",false);
  env.addCmd("external_set",(position,target) => {

      env.setParam( "pos", [position.x,position.y,position.z],true );
    //env.setParamManualFlag("pos",ismanual);
    //if (target) { // плохонько но пока сойдет
      env.setParam( "center", [target.x,target.y,target.z],true );
      //env.setParamManualFlag("center",ismanual);
    //}
  });

  env.setParam("output",cam );
}

// todo https://github.com/yomotsu/camera-controls

import {OrbitControls,MapControls} from "./three.js/examples/jsm/controls/OrbitControls.js";

export function map_control( env ) {
  env.setParam('type','map');
  env.feature('orbit_control');

  let damping_unsub = () => {};
  env.onvalues(["threejs_control","damping","renderer"],(cc,damping,renderer) => {
    // F-CAMERA-DAMPING
    
    cc.enableDamping = damping;
    damping_unsub();
    if (damping) {
      damping_unsub = renderer.on("frame", cc.update );
    }
     else damping_unsub = () => {};
  });
  env.on("remove",() => damping_unsub() )
}

// параметры: camera, target_dom
export function orbit_control( env ) {
  
  var cc;
  let unsub = () => {};

  // смотрим на камеру верхнего окружения
  if (!env.paramAssigned("threejs_camera"))
       env.linkParam("threejs_camera","..->threejs_camera");
  if (!env.paramAssigned("target_dom"))
     env.linkParam("target_dom","..->target_dom"); // т.е. там рендерер подразумевается или кто..     

  env.addComboValue("type","orbit",["orbit","map"])

  env.onvalues(["type","threejs_camera","target_dom"],update);

  env.on("remove",() => {
    unsub();
    if (cc) cc.dispose();
  })
  
  function update() {
    unsub(); unsub = () => {};

    //console.log("orbit-control: update, cam=",env.params.camera)

    var c = env.params.threejs_camera;
    var dom = env.params.target_dom;
    //if (typeof(dom) == "function") dom = dom(); // фишка такая
    // т.е. родителем должен быть некто
    if (!dom) {
      //console.log("lib3d:orbit-control: parent.target_dom is blank!")
      return;
    };
    if (!c || !c.isCamera) return;

    if (cc) cc.dispose();

    //console.log('making orbit controls over camera c',c, 'and dom ',dom);

    if (env.params.type == 'map')
      cc = new MapControls( c, dom );
    else
      cc = new OrbitControls( c, dom );

    env.setParam("threejs_control",cc);
    
    if (c.isOrthographicCamera) {
      cc.panSpeed = 6;
    }
    //console.log("configured cc panspeed",cc.panSpeed)

    //console.log("made",cc)

    // криво косо но пока так

    let skip_camera_update=false;
    let skip_camera_reaction=false;

    if (c.vrungel_camera_env) {
      // короче оказалось что там свое некое тета возникает в этот момент
      // и нам его надо закопировать в камеру
      // c.vrungel_camera_env.setParam( "theta", 360 * cc.getAzimuthalAngle() / (2*Math.PI) );
      // короче оказалось что это мешает переключаться между экранами

      let u1 = c.vrungel_camera_env.trackParam("center",update_control_target)
      let u2 = c.vrungel_camera_env.trackParam("theta",update_control_theta );

      unsub = () => { u1(); u2(); };
      update_control_target( c.vrungel_camera_env.params.center );
      //update_control_theta( c.vrungel_camera_env.params.theta );

      function update_control_target (c) {
        if (skip_camera_reaction) return;
        if (c == null) {
          console.warn("lib3d control: invalid input value for center (lookat)",c)
          return 
        }
        skip_camera_update=true;
        // защита от зацикливания
        //let eps = 0.0001;
        let eps = 0;
        if (Math.abs( c[0] - cc.target.x) > eps || Math.abs( c[1] - cc.target.y ) > eps || Math.abs( c[2] - cc.target.z ) > eps )
        { 
          // console.log('orbitcontrols',env.$vz_unique_id,"target of camera changed, updating me",c)
          cc.target.set( c[0], c[1], c[2] );
          cc.update();
        }
        skip_camera_update=false;
        // вроде как pos ставить не надо т.к. оно и так из камеры его берет
      };

      function update_control_theta(t) {
         if (skip_camera_reaction) return;
         skip_camera_update=true;
         //cc.spherical.theta = 2*Math.PI / 360;
         ///debugger;
         //cc.setAzimuthalAngle( 2*Math.PI / 360 )
         //if (t >= 0)
         let eps = 0.000001; // 0.5 * 2 * Math.PI / 360;
         let nv = 2*Math.PI *t / 360;
         if (Math.abs( cc.getAzimuthalAngle() - nv) > eps) {
            //console.log('orbitcontrols',env.$vz_unique_id,': theta of camera changed, differs from me, setting manual. val=', nv, 'my orig val=',cc.getAzimuthalAngle())
            cc.manualTheta = nv;
            cc.update();
         }
         skip_camera_update=false;
      }

    }

    let flag=false;
    cc.addEventListener( 'change',update_from_control );

    let ounsub = unsub;
    unsub = () => {
      ounsub(); cc.removeEventListener( 'change', update_from_control );
    }

    function update_from_control() {
        if (skip_camera_update)
        {
          //skip_camera_update = false;
          return;
        }

        if (c.vrungel_camera_env) {
          skip_camera_reaction = true;
          //console.log('orbitcontrols',env.$vz_unique_id,': i send new pos and center to camera ',c.position, cc.target)
          c.vrungel_camera_env.external_set( c.position, cc.target, ( cc.getAzimuthalAngle() * 360 / (2*Math.PI)) );
          //console.log('orbitcontrols',env.$vz_unique_id,': i send new theta to camera ',cc.getAzimuthalAngle())
          c.vrungel_camera_env.setParam("theta", ( cc.getAzimuthalAngle() * 360 / (2*Math.PI)), false);
          if (c.zoom)
              c.vrungel_camera_env.setParam("ortho_zoom", c.zoom, true )
          skip_camera_reaction = false;
        }
          // так-то можно и аргумент - камеру )))
        //console.log( "oc changbed",c);
        //c.setParam

    }

  }

}
