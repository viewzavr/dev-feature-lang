export function setup(vz, m) {
  vz.register_feature_set(m);
}

// todo слушать уведомления при добавлении subfeature-элементов... сейчас они не слушаются.

// root - с какого объекта искать
// features - список фич которые объект должен содержать, массив или строка (все из них)
// recursive - если объект удовлетворяет, следует ли ли идти в его поддерево?
// include_root - включать ли root в обзор

// пример: find_objects_bf root=@some features="alfa beta";

// идея надо не root а input!
export function find_objects_bf( env  ) {

  // сделано т.к. у нас по нескольку новых объектов за так может появляться
  env.feature("delayed");
  env.do_publish = env.delayed( () => {
     // todo optimize добавить счетчик $vz_param_state_counter см geta.js
     env.setParam( "output", [...result_object_list] ) 
   });
  
  function publish_result() {
    env.do_publish();
  }

  let result_object_ids = {};
  env.on("reset",() => {result_object_ids = {}});
  let result_object_list = [];
  env.on("reset",() => {result_object_list = []});    

  let perobject_unsub_list = {};

  //if (!env.hasParam("root")) env.setParam("root","/");  

  env.addObjectRef("root","/");

  if (!env.hasParam("features") && !env.hasLinksToParam("features"))
       env.createLinkTo( {param:"features",from:"~->0",soft:true });

  // субфича - явный флаг recursive для поиска внутри найденных объектов
  if (!env.hasParam("recursive"))
    env.setParam("recursive",true)

  if (!env.hasParam("include_root"))
      env.setParam("include_root",true);

  if (!env.hasParam("include_subfeatures"))
    env.setParam("include_subfeatures",true);

  ////// отладка
  let log = () => {};
  env.onvalue("debug",(v) => {
    if (v) log = (...args) => {
      console.log(...args)
      env.vz.console_log_diag( env )
    };
    else log = () => {};
  })

  //env.feature("delayed");
  // env.setParam("output",[]); // не будем смущать население
  // ну или посмущаем

  let delayed_begin = env.delayed( begin, 10 );
  env.monitor_values(["root","features"],(r,f) => {
    if (!r) {
      env.emit("reset");
      publish_result();
      return;
    }

    //delayed_begin.stop();
    // begin( r,f );

    if (r.getPath() == "/") // отсечем случай когда данные нам еще не выставили просто
      delayed_begin( r,f );
    else {
      delayed_begin.stop();
      //debugger;
      begin( r,f );
    }

  });

  let unsub_list = []; // это массив элементов вида [ {f:func}, {f:func}, func, func, ....] то есть вперемешку

  function unsub_all() {
    unsub_a_list( unsub_list );
    
    for (let k of Object.keys( perobject_unsub_list ))
      unsub_a_list( perobject_unsub_list[k] );
  }

  function unsub_a_list(list) {

    list.forEach( rec => { 
        if (rec.f) 
           rec.f(); 
         else {
           if (typeof(rec) != "function")
            debugger;
          rec(); 
        }
    } );
    list.length = 0;
  }

  // пообъектные отписки
  
  function add_obj_unsub( obj, f ) {
    if (!obj.$vz_unique_id )
    {
      //debugger;
      obj.feature("vzf_object_uniq_ids");
    }
    perobject_unsub_list[ obj.$vz_unique_id ] ||= [];
    perobject_unsub_list[ obj.$vz_unique_id ].push( f );
  }
  function unsub_for_obj( obj ) {
    unsub_a_list( perobject_unsub_list[ obj.$vz_unique_id ] || [] );
  }

  env.on("remove",unsub_all);
  env.on("reset",unsub_all);

  function begin(root,features, include_subfeatures ) {
    //console.log("find_objects_bf begin: root=",root.getPath(),"\nfeatures=",features,"\nobj=",env.getPath())
    //if (root.getPath() == "/")  debugger;
    //unsub_all();
    //if (unsub_list.length > 0) console.warn("find_objects_bf: repeated begin! unsub_list.length = ",unsub_list.length)

    env.emit("reset"); // вызовет всеобщую отписку
    publish_result(); // либо пустой массив будет либо заполнится чем-нибудь уже на этом такте

    if (Array.isArray(features))
    {

    }
    else
    {
      if (typeof(features) !== "string") 
        return;
      features = features.trim().split(/\s+/);
    }  

    // фичи записываются все через - и это используется в т.ч. в именах событий фич
    // поэтому приведем все к "стандартному" виду.
    features = features.map( str => str.replaceAll("_","-"));

    traverse_if( root,(obj,depth) => process_one_obj( obj, features, depth ), env.params.include_subfeatures, env.params.depth );
  }

  function process_one_obj (obj, features, depth ) {

      if (depth < -1) return false // закончили обход

      unsub_for_obj( obj );
      if (env.params.debug)
        console.log("find-objects process_one_obj",obj.getPath(),features, depth, "root=",env.params.root ? env.params.root.getPath(): null )
      //if (depth < 0) debugger

      // 1. ходить по фичам объекта и если все нашли - то фиксируем это
      let unsub = { f: () => {} };
      walk_on_obj_features( obj, features,0, () => {
        // наш клиент
        // доп условие
        
        //debugger;
        //next_object_found( obj )
        if (env.params.include_root || (!env.params.include_root && obj !== env.params.root)) {
            log("fobf: next object found",features,obj,depth, "root=",env.params.root );
            next_object_found( obj,features, depth )
        }
        //env.emit("next_object_found", obj );
      }, unsub );
      add_obj_unsub( obj, unsub );

      // доп случай когда надо пересканировать, см. ниже
      // идея - нельзя ли тут нам как-то красиво подписать объект appendChild на вот это событие перенаправить?...
      let apc_unsub2 = obj.on("rescan-find-objects",() => {
        // process_one_obj(obj)
        traverse_if( obj,(obj,depth) => process_one_obj( obj, features, depth ),env.params.include_subfeatures, depth );
        // тут место для утечки - если объект уже был подписан и просканирован, то мы получается
        // сейчас повторно на-подписываемся.
        // нам бы тогда сохранять, на кого мы уже подписки все нужные оформили?
      });
      add_obj_unsub( obj, apc_unsub2 );

      // завершить обход, если объект найден, а рекурсивность не требуется
      if (is_object_in_found_set( obj ) && !env.params.recursive)
        return false;

      // 2. если в объект добавили узла-дитя, то проверять эту дитя
      //console.log("fobf: subs to obj-append-child",obj.getPath());
      let apc_unsub = obj.on("appendChild",(cobj) => {
         //console.log("fobf: obj-append-child",cobj.getPath());
         //log("fobf: obj-append-child",features, cobj.$features_applied, cobj);
         if (!is_object_in_found_set( obj ) || env.params.recursive)
              process_one_obj(cobj,features, depth-1 );
            // тут бы traverse_if + отслеживание если уже отслеживаем
      });
      add_obj_unsub( obj, apc_unsub );
  
      return true; // продолжаем обход
      
  }; // process_one_obj  


  //env.on("next_object_found",(obj))
  // здесь могут быть дубликаты
  function next_object_found(obj,features, depth) {
    let id = obj.$vz_unique_id;
    if (result_object_ids[id]) return; // такое уже у нас есть
    result_object_ids[id] = id;
    
    let u = obj.on("remove", () => { 
       delete result_object_ids[id]; 
       uniq_object_disappeared( obj );
    })
    // unsub_list.push( u ); // отдельный список
    // вот не знаю то ли сюда то ли в add_obj_unsub( obj, u2 );
    add_obj_unsub( obj, u );

    // теперь надо поймать все фичи если вдруг уйдет какая
    for (let f of features) {

      let u2 = obj.on("feature-unapplied-"+f, () => { 
        delete result_object_ids[id]; 
        uniq_object_disappeared( obj );
        // убрались из резульатов и опять себя мониторим
        process_one_obj( obj,features,depth );
      })
      add_obj_unsub( obj, u2 );
    }

    next_unique_object_found( obj );
  }

  function is_object_in_found_set( obj ) {
    return result_object_ids[ obj.$vz_unique_id ];
  }
  

  function next_unique_object_found( obj ) {
    result_object_list.push( obj );
    // можно тут событие добавить если кому интересно будет..

    // не работает это в теме передачи ссылок.. там сравнивается и сообразно не пропускается
    // и сигнала не получается..
    //env.setParamWithoutEvents("output", result_object_list );
    //env.signalParam( "output" );
    //env.setParam( "output", [...result_object_list] );
    publish_result();
  }

  function uniq_object_disappeared( obj ) {
     result_object_list = result_object_list.filter( i => i != obj );
     publish_result();
     //env.setParam( "output", [...result_object_list] );
     //let i = result_object_list.indexOf( obj );
  }



  // unsub_item.f это возможность нам изнутри менять функцию отписки
  function walk_on_obj_features( obj, features_list,i, when_all_found, unsub_item ) {
    let next_feature = features_list[i];
    if (!next_feature) { // все фичи найдены
      when_all_found( obj );
      unsub_item.f = () => {};
      return true;
    };

    if (obj.is_feature_applied(next_feature))
      return walk_on_obj_features( obj, features_list, i+1, when_all_found, unsub_item);

    unsub_item.f = obj.once("feature-applied-"+next_feature,() => {
      walk_on_obj_features( obj, features_list, i+1, when_all_found, unsub_item );
    });
  }

}

// поиск - обход всех детей с вызовом fn
function traverse_if( obj, fn, include_subfeatures, depth_avail_left ) 
{
  //if (typeof(depth_avail_left) != "undefined" && depth_avail_left < 0) return
  let next_depth = depth_avail_left-1

  if (!fn( obj,next_depth )) return;

  // if (next_depth < 0) return
  
  var cc = obj.ns.getChildren();
  for (var cobj of cc) {
    traverse_if( cobj,fn,include_subfeatures, next_depth );
  }

  if (include_subfeatures) {

    // экспериментально - пойдем ка по прицепленным фичам
    cc = obj.$feature_list_envs || [];
    for (var cobj of cc) {
      traverse_if( cobj,fn,include_subfeatures, next_depth );
    }
  }

  // возможность указать дополнительный маршрут
  // важно - проверки на циклы нет
  cc = obj.$find_objects_follow_list || [];
  for (var cobj of cc) {
    traverse_if( cobj,fn,include_subfeatures, next_depth );
  }
}

/* F_ANON
   доп фича - уметь указать в объекте, куда ему еще следует зайти в поисках find-objects
   используется нами для поиска переселенных объектов (когда подчинненое не является дитем а поселено дитем 
   в другое место, но нам надо и в него по семантике зайти)
*/
export function find_objects_follow(env) {
  env.onvalues_any(["to"],(v) => {
    if (v && !Array.isArray(v)) v=[v];
    let oldlist = env.host.$find_objects_follow_list;
    env.host.$find_objects_follow_list = v;
    // ну кстати надо там еще и отписывать старых... так-то....

    //console.log("find_objects_follow emitting for", env.host.getPath())
    env.host.emit( "rescan-find-objects",v,oldlist );
  })
}