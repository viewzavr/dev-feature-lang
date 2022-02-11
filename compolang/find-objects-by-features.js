export function setup(vz, m) {
  vz.register_feature_set(m);
}

// root - с какого объекта искать
// features - список фич которые объект должен содержать, массив или строка
// пример: find_objects_bf root=@some features="alfa beta";
export function find_objects_bf( env  ) {

  env.addObjectRef("root");

  env.feature("delayed");

  let delayed_begin = env.delayed( begin, 50 );
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
    console.log("find_objects_bf begin: root=",root.getPath(),"\nfeatures=",features,"\nobj=",env.getPath())
    //if (root.getPath() == "/")  debugger;
    //unsub_all();
    if (unsub_list.length > 0)
        console.warn("find_objects_bf: reepated begin! unsub_list.length = ",unsub_list.length)
    env.emit("reset");

    if (!Array.isArray(features)) features = features.trim().split(/\s+/);

    // фичи записываются все через - и это используется в т.ч. в именах событий фич
    // поэтому приведем все к "стандартному" виду.
    features = features.map( str => str.replaceAll("_","-"));

    traverse_if( root,process_one_obj );

    function process_one_obj (obj) {
      let unsub = { f: () => {} };
      walk_on_obj_features( obj, features,0, () => {
        // наш клиент
        next_object_found( obj )
        //env.emit("next_object_found", obj );
      }, unsub );
      unsub_list.push( unsub );

      // ну это мы с узлом разобрались. теперь надо узнать когда новое происходит
      let apc_unsub = obj.on("appendChild",(cobj) => {
        //console.log("HOOOK appc",cobj.getPath(),features)
        process_one_obj(cobj)
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
    
    let u = obj.on("remove", () => { delete result_object_ids[id]; })
    unsub_list.push( u )

    next_unique_object_found( obj );
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
    env.setParam( "output", [...result_object_list] );
  }

  // unsub_item.f это возможность нам изнутри менять функцию отписки
  function walk_on_obj_features( obj, features_list,i, when_all_found, unsub_item ) {
    let next_feature = features_list[i];
    if (!next_feature) {
      when_all_found( obj );
      unsub_item.f = () => {};
      return;
    }; // приплыли

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
}