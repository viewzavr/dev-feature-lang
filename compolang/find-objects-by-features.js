export function setup(vz, m) {
  vz.register_feature_set(m);
}

// todo слушать уведомления при добавлении subfeature-элементов... сейчас они не слушаются.

// root - с какого объекта искать
// features - список фич которые объект должен содержать, массив или строка
// пример: find_objects_bf root=@some features="alfa beta";
export function find_objects_bf( env  ) {

  env.addObjectRef("root");

  // субфича - явный флаг recursive для поиска внутри найденных объектов
  if (!env.hasParam("recursive"))
    env.setParam("recurvsive",true)

  env.feature("delayed");
  // env.setParam("output",[]); // не будем смущать население
  // ну или посмущаем

  let delayed_begin = env.delayed( begin, 10 );
  env.onvalues(["root","features"],(r,f) => {
    if (r.getPath() == "/") // отсечем случай когда данные нам еще не выставили просто
      delayed_begin( r,f );
    else {
      delayed_begin.stop();
      begin( r,f );
    }
  });

  let unsub_list = []; // это массив элементов вида [ {f:func}, {f:func}, func, func, ....] то есть вперемешку
  function unsub_all() {

    unsub_list.forEach( rec => { 
        if (rec.f) 
           rec.f(); 
         else {
           if (typeof(rec) != "function")
            debugger;
          rec(); 
        }
    } );
    unsub_list = [];
  }
  env.on("remove",unsub_all);
  env.on("reset",unsub_all);

  function begin(root,features) {
    //console.log("find_objects_bf begin: root=",root.getPath(),"\nfeatures=",features,"\nobj=",env.getPath())
    //if (root.getPath() == "/")  debugger;
    //unsub_all();
    if (unsub_list.length > 0)
        console.warn("find_objects_bf: reepated begin! unsub_list.length = ",unsub_list.length)
    env.emit("reset"); // вызовет всеобщую отписку
    publish_result(); // либо пустой массив будет либо заполнится чем-нибудь уже на этом такте

    if (!Array.isArray(features)) features = features.trim().split(/\s+/);

    // фичи записываются все через - и это используется в т.ч. в именах событий фич
    // поэтому приведем все к "стандартному" виду.
    features = features.map( str => str.replaceAll("_","-"));

    traverse_if( root,process_one_obj );

    function process_one_obj (obj) {
      //if (env.params.debug)
        //console.log("find-objects process_one_obj",obj.getPath(),features)


      // 1. ходить по фичам объекта и если все нашли - то фиксируем это
      let unsub = { f: () => {} };
      walk_on_obj_features( obj, features,0, () => {
        // наш клиент
        next_object_found( obj )
        //env.emit("next_object_found", obj );
      }, unsub );
      unsub_list.push( unsub );

      // доп случай когда надо пересканировать, см. ниже
      // идея - нельзя ли тут нам как-то красиво подписать объект appendChild на вот это событие перенаправить?...
      let apc_unsub2 = obj.on("rescan-find-objects",() => {
        // process_one_obj(obj)
        traverse_if( obj,process_one_obj );
        // тут место для утечки - если объект уже был подписан и просканирован, то мы получается
        // сейчас повторно на-подписываемся.
        // нам бы тогда сохранять, на кого мы уже подписки все нужные оформили?
      });
      unsub_list.push( apc_unsub2 );

      // завершить обход, если объект найден, а рекурсивность не требуется
      if (is_object_in_found_set( obj ) && !env.params.recursive)
        return false;

      // 2. если в объект добавили узла-дитя, то проверять его
      let apc_unsub = obj.on("appendChild",(cobj) => {
         if (!is_object_in_found_set( obj ) || env.params.recursive)
              process_one_obj(cobj);
            // тут бы traverse_if + отслеживание если уже отслеживаем
      });
      unsub_list.push( apc_unsub );

  
      return true; // продолжаем обход
      
    }; // process_one_obj
  }

  
  let result_object_ids = {};
  env.on("reset",() => {result_object_ids = {}});

  //env.on("next_object_found",(obj))
  // здесь могут быть дубликаты
  function next_object_found(obj) {
    let id = obj.$vz_unique_id;
    if (result_object_ids[id]) return; // такое уже у нас есть
    result_object_ids[id] = id;
    
    let u = obj.on("remove", () => { 
       delete result_object_ids[id]; 
       uniq_object_disappeared( obj );
    })
    unsub_list.push( u )

    next_unique_object_found( obj );
  }

  function is_object_in_found_set( obj ) {
    return result_object_ids[ obj.$vz_unique_id ];
  }

  let result_object_list = [];
  env.on("reset",() => {result_object_list = []});

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

  // сделано т.к. у нас по нескольку новых объектов за так может появляться
  env.feature("delayed");
  env.do_publish = env.delayed( () => env.setParam( "output", [...result_object_list] ) );
  function publish_result() {
    env.do_publish();
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
function traverse_if( obj, fn ) {
  if (!fn( obj )) return;
  var cc = obj.ns.getChildren();
  for (var cobj of cc) {
    traverse_if( cobj,fn );
  }
  // экспериментально - пойдем ка по прицепленным фичам
  cc = obj.$feature_list_envs || [];
  for (var cobj of cc) {
    traverse_if( cobj,fn );
  }

  // возможность указать дополнительный маршрут
  // важно - проверки на циклы нет
  cc = obj.$find_objects_follow_list || [];
  for (var cobj of cc) {
    traverse_if( cobj,fn );
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