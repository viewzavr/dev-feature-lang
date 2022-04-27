/* новые модификаторы

   модификатор это окружение которое модифицирует несколько целевых окружений.
   целевые окружения определяются / поступают на вход по мере работы программы.
   целевые окружения указываются через сигнал attach(obj) и снимаются через detach(obj)
   s
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
  env.onvalue("input",(i) => {
    iter++;

    if (!Array.isArray(i)) i = [i];

    for (let obj of i) {
      let id = getobjid( obj );

      if (modified_objs[id]) {
         modified_objs[id].iter = iter;;
         continue;
      }

      modified_objs[id] = {iter:iter, obj:obj};
      
      for (let c of env.ns.getChildren()) {
        c.emit("attach",obj);
      }
    }

    for (let k of Object.keys( modified_objs )) {
      if (modified_objs[k].iter < iter) {
        let obj = modified_objs[k].obj;
        delete modified_objs[k];
        for (let c of env.ns.getChildren()) {
          c.emit("detach",obj);
        }
      }
    };
  
  });

  env.on("remove",() => env.setParam( "input",[] )); // посмотрим хватит не хватит

  // второй протокол.. видимо, несовместим с первым

  env.on("attach",(obj) => {
    //modified_objs[ getobjid( obj ) ] = 1;
    
    for (let c of env.ns.getChildren()) {
        c.emit("attach",obj);
    }
  })

  env.on("detach",(obj) => {
    for (let c of env.ns.getChildren()) {
        c.emit("detach",obj);
    }
    //delete modified_objs[ getobjid( obj ) ];
  })

  ////////////////////// todo:
  // on appendChild, on removeChild...

}

export function x_on( env  )
{
  env.feature("func");

  let detach = {};

  env.on("attach",(obj) => {

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

    let unsub = () => resarr.map( (f) => f.bind ? f() : false )
    detach[ obj.$vz_unique_id ] = () => {
       unsub();
       delete detach[ obj.$vz_unique_id ];
    }   

    return unsub; 

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