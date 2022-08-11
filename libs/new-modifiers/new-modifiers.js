/* новые модификаторы

   модификатор это окружение которое модифицирует несколько целевых окружений.
   целевые окружения определяются / поступают на вход по мере работы программы.
   целевые окружения указываются через сигнал attach(obj) и снимаются через detach(obj)
   
   отличается от старых модификаторов тем, что получается новый модификатор работает на множество целевых объектов (0, 1 или более)
   и узнает о них по событию attach.
*/

/* сделано так что модификаторы получают attach-событие если находятся в {{ - }} области.
   и это контрастирует с тем что x-modify реагирует на инпут.
   но он также реагирует и на эти события, что приводит к путанице.

   идея на будущее:
     x-modify работает только с input-ом.
     но инпут по умолчанию равен хосту/родителю.. блин вот эти умолчания...
     ну или что-то.. с этим надо сделать....

     плюс идея чтобы x-modify внутри себя посылал не attach а apply.
     тогда "модификацию" можно будет делать обычными императивными командами типа i-call-js.

     в общем еще подумать надо.
*/

/* 2022-06-23 надо сделать:
    F1 x-on2 новый работающий с позиционными аргументами (code=выглядит глупо)
      и он же работающий с {} окружением по-новому, через передачу аргументов
      (см 2022-06-22 разговор с Мишей.txt)
    F2 фичу - авто обработчик detach, которая вызывает функцию возвращенную в attach.
*/


/* старая заметка
  замысел ввести такой вид модификаторов который берет на вход input
  и вносит модификации.

  сейчас это сделано через оператор modify, который создает окружения модификаторов 
  и внедряет в фиче-субдерево целевых фич. это в чем-то удобно, конечно.
  но новая мысль заключается в том чтобы модификатор просто брал на вход
  input и производил действие.

  input при этом может быть как списком объектов, так и просто объектом.
  экземпляр модификатора при этом остается один.

  в чем преимущества:
  - уходит тема host как ненужная (но мб останется спецдерево)
*/

export function setup(vz, m) {
  vz.register_feature_set( m );
}

export function x_modify( env ) 
{
  env.feature("delayed");
  //env.feature("pass_input"); // ну так по приколу - чтобы писать x-modify | x-modify | ...

  let modified_objs = {}; // todo: set

  // выдать надо тож полезно
  function publish_modified_objs() {
    if (env.removed || env.removing) return;
    let v = Object.values(modified_objs).map( rec => rec.obj );
    env.setParam("output",v);
  }
  let publish_modified_objs_d = env.delayed( publish_modified_objs );

  function getobjid(obj) {
    if (!obj.$vz_unique_id)
        obj.feature("vzf_object_uniq_ids");
    return obj.$vz_unique_id;
  }

  // input - приаттачить всем объектам из input
  //         если уже ранее что-то аттачили, то раз-аттачить у объектов которые были в input и их в input не стало.

  // алгоритм
  // 1 всех кого еще не посылали - послать аттач
  // 2 тех кого посылали и нет в списке - послать детач
  let iter = 0;
  env.onvalue("input",(i) => {
    iter++;
    let orig_i = i;

    if (!Array.isArray(i)) i = [i];

    for (let obj of i) {
      let id = getobjid( obj );

      if (modified_objs[id]) {
         modified_objs[id].iter = iter;;
         continue;
      }

      modified_objs[id] = {iter:iter, obj:obj, modifications: {}};
      let modifs = modified_objs[id].modifications;
      
      for (let c of env.ns.getChildren()) {
        modifs[ getobjid(c) ] = true;
        //console.log("x-modify .input sending attach to children",c.getPath())
        c.emit("attach",obj);
      }
    }

    // отключение модификации у объектов которые исчезли из input
    for (let k of Object.keys( modified_objs )) {
      if (modified_objs[k].iter < iter) {
        let obj = modified_objs[k].obj;
        delete modified_objs[k];
        for (let c of env.ns.getChildren()) {
          c.emit("detach",obj);
        }
      }
    };

    //publish_modified_objs();
    // будем выдавать как пришло исходно - если там 1 штучка без массива то и ок
    // это позволяет делать так: let k = (create-blank-object | x-modify ....);
    env.setParam("output",orig_i);
  
  });

  env.on("remove",() => env.setParam( "input",[] )); // посмотрим хватит не хватит

  // второй протокол.. видимо, несовместим с первым

  env.on("attach",(obj) => {
    // конечно тут контра с input.. ну да ладно - зато полезно для работы x-modify
    // когда он в режиме отлова attach-событий и при этом ему динамически детей добавляют
    // возможно тут стоило бы изменить на работу с input в режиме {{}}, ну да ладно

    // оказался мегабаг.. гипермегабаг... то что эта штука реагирует на аттач-сигналы...
    // потому что {{ }} посылает сюда аттач.. а мы например работаем по input-ссылке
    // и как результат мы еще и патчим хост-объект а нам не надо..
    if (env.hasParam("input") || env.hasLinksToParam("input")) 
        return;
    // может быть даже лучшее решение будет если мы не будем attach детям посылать тем
    // которые типа x-modify - пусть там на input реагируют.  
    // плюс была идея туда apply посылать вместо attach/detach.
    // @todo

    // важно - делаем запись ток если записи нет (т.е. пришли не через input)
    if (!modified_objs[ getobjid( obj ) ])
        modified_objs[ getobjid( obj ) ] = {obj:obj};

    //console.log("x-modify forwarding attach to children",env.getPath())

    let r = modified_objs[ getobjid( obj ) ];
    r.modifications ||= {};
    for (let c of env.ns.getChildren()) {
        //console.log(c.getPath())
        r.modifications[ getobjid(c) ] = true;
        c.emit("attach",obj);
    }

    publish_modified_objs_d();
  })

  env.on("detach",(obj) => {
    for (let c of env.ns.getChildren()) {
        c.emit("detach",obj);
    }

    delete modified_objs[ getobjid( obj ) ];

    publish_modified_objs_d();
  })

  ////////////////////// todo:
  // on appendChild, on forgetChild...

  
  
  env.on("appendChild",(c) => {
    let iter_a = iter; 
    // надо задержку - там фича еще недоделанная может быть, а уже appendChild вызвали..
    env.timeout( () => {
      // и важно, если итерация сменилась - значит инпут сработал и нам уже реагировать не надо здесь
      // if (iter_a != iter) return;
      for (let k of Object.keys( modified_objs )) {
        if (!modified_objs[k].modifications[ getobjid(c)]) {
            modified_objs[k].modifications[ getobjid(c)] = true;  
            c.emit("attach",modified_objs[k].obj);
        }
      }
    },1 );
  });
  
  
  env.on("forgetChild",(c) => {
    for (let k of Object.keys( modified_objs )) 
      c.emit("detach",modified_objs[k].obj);
  });

}

// отличается от x-modify тем что вход берет из списка list
export function x_modify_list( env ) 
{

  env.feature("pass_input"); // ну так по приколу - чтобы писать x-modify | x-modify | ...

  let modified_objs = {}; // todo: set

  function getobjid(obj) {
    if (!obj.$vz_unique_id)
        obj.feature("vzf_object_uniq_ids");
    return obj.$vz_unique_id;
  }

  // input - приаттачить всем объектам из input
  //         если уже ранее что-то аттачили, то раз-аттачить у объектов которые были в input и их в input не стало.

  // алгоритм
  // 1 всех кого еще не посылали - послать аттач
  // 2 тех кого посылали и нет в списке - послать детач
  let iter = 0;
  env.onvalues(["input","list"],(i,list) => {
    iter++;

    if (!Array.isArray(i)) i = [i];

    for (let obj of i) {
      let id = getobjid( obj );

      if (modified_objs[id]) {
         modified_objs[id].iter = iter;
      }
      else
      {
        modified_objs[id] = {iter:iter, obj:obj, modifications: {}};
      }
      let existing_modifications = modified_objs[id].modifications;
      
      for (let c of list) {
        let modifier_id = getobjid( c );
        if (existing_modifications[modifier_id]) {
            existing_modifications[modifier_id].iter = iter;
            continue;
        }
        c.emit("attach",obj);
        let detach_code = () => { 
            c.emit("detach",obj);
        }
        existing_modifications[modifier_id] = { iter: iter, detach_code: detach_code };
      }

      // уберем модификации которые больше не активны для данного объекта
      for (let kc of Object.keys( existing_modifications )) {
        if (existing_modifications[kc].iter < iter) {
          existing_modifications[kc].detach_code();
          delete existing_modifications[kc];
        }
      }
    }

    // отключение модификации у объектов которые исчезли из input
    for (let k of Object.keys( modified_objs )) {
      if (modified_objs[k].iter < iter) {
        let obj = modified_objs[k].obj;
        let applied_modifications = modified_objs[k].modifications;
        delete modified_objs[k];
        Object.values( applied_modifications || {}).map( f => f.detach_code() );
      };
    };
  
  });

  env.on("remove",() => env.setParam( "input",[] )); // посмотрим хватит не хватит
}

export function x_on( env  )
{
  //env.feature("lambda");
  env.feature("func");

  let detach = {};

  env.on("attach",(obj) => {
    //console.log("x-on: attach to obj",obj.getPath())

    var u1 = () => {};

    // todo вынести это наружу attach-а    
    let k1 = env.onvalue( "name", connect );
    let k2 = env.onvalue( 0, connect );

    function connect(name,name0) {
      name ||= name0;

      u1();
      //console.log("on: subscribing to event" , name, obj.getPath() )
      u1 = obj.on( name ,(...args) => {
        //console.log("on: passing event" , name )

        let fargs = [ obj ].concat( args );
        // получается крышеснос
        // мб там как-то на this повлиять и пусть в нем будет obj и пр

        // но нам надо таки.. уметь послать объект, на котором это все приключилось.
        // а то там мало ли объектов

        // но это абсолютнейший крышеснос, неявное появление параметра. надо что-то с этим делать

        // update: подтверждаю, полнейший крышеснос, абсолютный.
        // надо как-то переходить на ключи видимо

        /* не работает
        if (name == "remove") {
           // особый случай
           env.set_feature_applied("func",false);
           env.feature("func");
        }
        */

        env.callCmd("apply",...fargs);
        // идея - можно было бы всегда в args добавлять объект..
      })

      //console.log("on: connected",name,env.getPath())
        env.emit("connected", obj);
     }

     detach[ obj.$vz_unique_id ] = () => { 
        k1(); k2(); u1();
        delete detach[ obj.$vz_unique_id ];
     };

     return detach[ obj.$vz_unique_id ] 
  });

  env.on("detach",(obj) => {
    let f = detach[ obj.$vz_unique_id ];
    if (f) {
      f();
      // delete detach[ obj.$vz_unique_id ];
    }
  });
  // ну вроде как remove нам не надо? modify же все разрулит?
  // так да не так. если объект сам удаляется по каким-то причинам.
  // или если он кстати динамически добавляется.
  // это должен получается modify тоже разруливать...

}

// реагирует на сигнал attach, применяя указанный код к окружению

export function x_patch( env  )
{
  env.feature("func");

  let detach = {};

  env.on("attach",(obj) => {

    let resarr = env.callCmd("apply",obj);
    
    if (!resarr) resarr = [];
    if (!Array.isArray(resarr)) resarr = [resarr];
    resarr = resarr.flat(5);

    let unsub = () => resarr.map( (f) => f?.bind ? f() : false )
    detach[ obj.$vz_unique_id ] = () => {
       unsub();
       delete detach[ obj.$vz_unique_id ];
    }

    return detach[ obj.$vz_unique_id ]; 
  });

  env.on("detach",(obj) => {
    let f = detach[ obj.$vz_unique_id ];
    if (f) {
      f();
      //delete detach[ obj.$vz_unique_id ];
    }
  });
  // ну вроде как remove нам не надо? modify же все разрулит?
  // так да не так. если объект сам удаляется по каким-то причинам.
  // или если он кстати динамически добавляется.
  // это должен получается modify тоже разруливать...

}

// модификатор модификатора..?
// замысел был что сделать индивидуальную нахлобучку модификатору
// и типа применение модификатора только если выполнено условие
/*
export function x_active( env ) {
  env.addCheckbox("active",true);

  let attached_objects_list = {};

  env.on("attach",(obj) => {

  });

  env.on("detach",(obj) => {
  });

  apply => pass-apply... а ведь он многократный...

}
*/

// reactive - перевызывает код при изменении аргументов
export function x_patch_r( env  )
{
  env.feature("lambda");

  // env.addCheckbox("active",true);
  // env.feature("m-apply");

  // 1. дадим поменяться нескольким параметрам
  // 2. если идет remove-процесс то наше param-changed по идее не сработает (его удалят на delayed)
  // именно вклинивание сюда позволило мне решить ситуацию, когда параллельно шли процессы
  // удаления дерева, как следствие удаление модификаторов, изменение параметров,
  // и как следствие пере-применение других модификаторов (вот этих, x-partch-r)
  // что влекло работу затем recreator и конструирование на участках поддерева до которых еще не дошел remove
  // - и все это на этапе удаления общего дерева..
  env.feature("delayed");
  let recall_attached = env.delayed( () => {
    for (let rec of Object.values( attached_list )) {
       let obj = rec.obj;
       // console.log('x-patch-r: re-patch object', obj.getPath())
       if (rec.unsub) rec.unsub();
       rec.unsub = env.callCmd("apply",obj );

       // да хрен с ним, не будем менять пока unsub..
       // но вообще это на туду что надо быть
    }
  });

  env.on("param_changed", recall_attached );

/*
  env.on("param_changed",(name) => {
    if (name == "code") return;

    for (let rec of Object.values( attached_list )) {
       let obj = rec.obj;
       env.callCmd("apply",obj, rec.unsub );
       // да хрен с ним, не будем менять пока unsub..
    }
  })
  */

  
  let attached_list = {};

  env.on("attach",(obj) => {
    //console.log('x-patch-r: attach called',obj.getPath() );

    let resarr = env.callCmd("apply",obj);
    
    if (!resarr) resarr = [];
    if (!Array.isArray(resarr)) resarr = [resarr];
    resarr = resarr.flat(5);

    let unsub = () => resarr.map( (f) => f.bind ? f() : false )

    attached_list[ obj.$vz_unique_id ] = {
      obj: obj,
      unsub: unsub
    };

/*
    detach[ obj.$vz_unique_id ] = () => {
       unsub();
       delete detach[ obj.$vz_unique_id ];
    }
*/    

    return () => {
       //console.log('x-patch-r: a-unsub detach called',obj.getPath() );
       unsub();
       delete attached_list[ obj.$vz_unique_id ];
    };

  });

  env.on("detach",(obj) => {
    // console.log('x-patch-r: detach called',obj.getPath() );
    let rec = attached_list[ obj.$vz_unique_id ];
    let f = rec ? rec.unsub : undefined;
    if (f) {

      f();
      delete attached_list[ obj.$vz_unique_id ];
      //delete detach[ obj.$vz_unique_id ];
    }
  });
  // ну вроде как remove нам не надо? modify же все разрулит?
  // так да не так. если объект сам удаляется по каким-то причинам.
  // или если он кстати динамически добавляется.
  // это должен получается modify тоже разруливать...

}


//////////////////////

// синоним
export function x_js( env ) {
  x_patch_r2( env );
}

// reactive - перевызывает код при изменении аргументов
// x-patch-r2 "(env,arg1,arg2) => что хотим делаем с env" arg1 arg2;
// warning сейчас наоборот идет и это неправильно
export function x_patch_r2( env  )
{
  env.feature("m_lambda");

  // env.addCheckbox("active",true);
  // env.feature("m-apply");

  // 1. дадим поменяться нескольким параметрам
  // 2. если идет remove-процесс то наше param-changed по идее не сработает (его удалят на delayed)
  // именно вклинивание сюда позволило мне решить ситуацию, когда параллельно шли процессы
  // удаления дерева, как следствие удаление модификаторов, изменение параметров,
  // и как следствие пере-применение других модификаторов (вот этих, x-partch-r)
  // что влекло работу затем recreator и конструирование на участках поддерева до которых еще не дошел remove
  // - и все это на этапе удаления общего дерева..
  env.feature("delayed");
  let recall_attached = env.delayed( () => {
    for (let rec of Object.values( attached_list )) {
       let obj = rec.obj;
       // console.log('x-patch-r: re-patch object', obj.getPath())
       if (rec.unsub) {
         if (rec.unsub.bind)
             rec.unsub();
         // todo - make-func результаты  
       }  
       rec.unsub = env.callCmd("apply",obj );

       // да хрен с ним, не будем менять пока unsub..
       // но вообще это на туду что надо быть
    }
  });

  env.on("param_changed", recall_attached );


  let attached_list = {};

  env.on("attach",(obj) => {
    //console.log('x-patch-r: attach called',obj.getPath() );

    let resarr = env.callCmd("apply",obj);
    
    if (!resarr) resarr = [];
    if (!Array.isArray(resarr)) resarr = [resarr];
    resarr = resarr.flat(5);

    let unsub = () => resarr.map( (f) => f.bind ? f() : false )

    attached_list[ obj.$vz_unique_id ] = {
      obj: obj,
      unsub: unsub
    };

    return () => {
       //console.log('x-patch-r: a-unsub detach called',obj.getPath() );
       unsub();
       delete attached_list[ obj.$vz_unique_id ];
    };

  });

  env.on("detach",(obj) => {
    // console.log('x-patch-r: detach called',obj.getPath() );
    let rec = attached_list[ obj.$vz_unique_id ];
    let f = rec ? rec.unsub : undefined;
    if (f) {
      f();
      delete attached_list[ obj.$vz_unique_id ];
      //delete detach[ obj.$vz_unique_id ];
    }
  });

}

// реализация фичи F2
// отслеживает функцию, возвращенную attach, и вызывает ее при detach или повторном attach
// update: у нас нет механизма отлова событий других и получения от них результатов
// поэтому переходим к логике что вызывается метод с именем apply.
/*
export function x_auto_detach( env  )
{

  let attached_list = {};

  env.on("attach",(obj) => {

    // уже прицеплены
    if (attached_list[ obj.$vz_unique_id ])
        return;

    let resarr = env.callCmd("apply",obj);
    
    if (!resarr) resarr = [];
    if (!Array.isArray(resarr)) resarr = [resarr];
    resarr = resarr.flat(5);

    let unsub = () => resarr.map( (f) => f.bind ? f() : false )

    attached_list[ obj.$vz_unique_id ] = {
      obj: obj,
      unsub: unsub
    };

    return () => {
       //console.log('x-patch-r: a-unsub detach called',obj.getPath() );
       unsub();
       delete attached_list[ obj.$vz_unique_id ];
    };

  });

  env.on("detach",(obj) => {
    // console.log('x-patch-r: detach called',obj.getPath() );
    let rec = attached_list[ obj.$vz_unique_id ];
    let f = rec ? rec.unsub : undefined;
    if (f) {
      f();
    }
    if (rec) {
      delete attached_list[ obj.$vz_unique_id ];
    }
  });

}
*/

// реализация алгоритма и без всяких фич
// идея - добавить сюда еще и input.. и полная красота..
// ну или x-modify пусть подключат? (как фичу)
export function m_auto_detach_algo( env,attach_func )
{

  let attached_list = {};

  env.on("attach",(obj) => {

    // уже прицеплены
    if (attached_list[ obj.$vz_unique_id ])
        return;

    let resarr = attach_func(obj);
    
    if (!resarr) resarr = [];
    if (!Array.isArray(resarr)) resarr = [resarr];
    resarr = resarr.flat(5);

    let unsub = () => resarr.map( (f) => f.bind ? f() : false )

    attached_list[ obj.$vz_unique_id ] = {
      obj: obj,
      unsub: unsub
    };

    return () => {
       //console.log('x-patch-r: a-unsub detach called',obj.getPath() );
       unsub();
       delete attached_list[ obj.$vz_unique_id ];
    };

  });

  env.on("detach",(obj) => {
    // console.log('x-patch-r: detach called',obj.getPath() );
    let rec = attached_list[ obj.$vz_unique_id ];
    let f = rec ? rec.unsub : undefined;
    if (f) {
      f();
    }
    if (rec) {
      delete attached_list[ obj.$vz_unique_id ];
    }
  });

  // можно было бы в on remove все повыключать но по идее нас
  // итак выключат - x-modify а может быть и {{ }} - фичи (хотя они не факт...)

}

// теперь про x-on2. назовем его m_on
/*
  можно так: 
    m_on event-name { |obj,event-name,...event-args|
       m_lambda "() => debugger";
    }
  но вообще я хотел изначально кодом:

  m_on event-name "(obj,event_name,...event_args) => {
  }";

*/

// мб на будущее event-name мб массивом 

// отлов событий
// on-модификатор в стиле m-лямбды
// m_on "event-name" "code" arg1 arg2;
export function m_on( env  )
{
  //env.lambda_start_arg = 1;
  env.feature("m_lambda", {lambda_start_arg:1} );
  //env.vz.m_lambda( env, 1 ); это следующий этап

  m_auto_detach_algo( env,(obj) => {
    //console.log("x-on: attach to obj",obj.getPath())

    var u1 = () => {};

    // todo вынести это наружу attach-а    
    let k1 = env.onvalue( "name", connect );
    let k2 = env.onvalue( 0, connect );

    return () => { 
        k1(); k2(); u1();
    };

    function connect(name,name0) {
      name ||= name0;

      u1();
      console.log("m-on: subscribing to event" , name, "of obj",obj.getPath() )
      u1 = obj.on( name ,(...args) => {
        console.log("m-on: passing event" , name, "of obj",obj.getPath() )

        let fargs = [ obj ].concat( args );
        // получается мы вызываем m-lambda приписав к вызову.. справа..
        // такие аргументы: obj, event-arg1, event-arg2, ....
        env.callCmd("apply",...fargs);
      })

      //console.log("on: connected",name,env.getPath())
        env.emit("connected", obj);
     }
     
  });

}