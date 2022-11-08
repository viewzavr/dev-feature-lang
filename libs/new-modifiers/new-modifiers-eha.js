/* новые модификаторы F-NEW-EHA

   y-on "channel" { |obj value|
      // тело процесса
   }
   y-patch { |obj|
      // тело процесса модификации
   }

   todo переписать с применением m_auto_detach_algo
*/

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

export function y_on( env  )
{
  env.setParam( "make_func_output","f")
  env.feature("make-func");

  /// теперь я думаю даже так:
  // let func = vz.feature.func( env ); func.setParam('sigma',4); func.apply ....
  // codea

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

        env.params.f.call( env, ...fargs )

        // env.callCmd("apply",...fargs);
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

export function y_patch( env  )
{
  env.setParam( "make_func_output","f")
  env.feature("make-func");

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

// реализация алгоритма и без всяких фич
// идея - добавить сюда еще и input.. и полная красота..
// ну или x-modify пусть подключат? (как фичу)
function m_auto_detach_algo( env,attach_func )
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
