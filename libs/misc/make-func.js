/*
  дизайн:
  время функции ограничено. если надо увеличить то mf-timeout 10000
  возврат результата:
    - пустой return
    - return (значение)
*/

export function setup(vz, m) {
  vz.register_feature_set(m);
};

// обеспечивает завершение make-func-цыы
// todo масса идей.. мб множественный return.. - формально поток жеж.. красота..
// или таки идти императивным путем и если надо поток то давайте вернем поток?
// а что если return без аргумента тоже выходит?
export function feature_return( env )
{
  function send_result(a) {

    let p = env.ns.parent;
    while (p) {
      //console.log( "checking", p.getPath())
      if (p.is_feature_applied("spawn_frame")) {
        //console.log("see sf", p.getPath())

        let allowed = true;
        if (env.params.target) { // указана целевая make-func
          // сообразно надо проверить, является ли найденный этот spawn_frame запуском make-func из парента
          if (!(p.ns.parent === env.params.target )) {
            //console.log("target mismatch. found mf is", p.ns.parent.getPath(), "but target mf is ", env.params.target.getPath() )
            allowed = false
          }
        }

        if (allowed) {
          //console.log("return: setting output to spawn-frame",a, p.getPath())
          //env.vz.console_log_diag( env )
          //console.trace()
          p.setParam("output",a)
          break
        }
      }

      if (p.ns.parent)
        p = p.ns.parent
      else if (p.hosted) p = p.host;
    }
    if (!p) {
      console.warn( "return: cannot find spawn_frame")
    }
  }
  env.monitor_assigned( ["input",0],(a,b) => {
    send_result(a || b)
  })
  if (env.hasParam("input") || env.hasParam(0))
    send_result( env.params.input || env.params[0] )

  /* ладно пока не будем */ /// будем
  // почему то ссылки через пайпу не срабатывают сюда
  
    // чистый ретюрн.
    //console.log("see clean return", env.params, env.linksToObject())
    //send_result(null) // а закончится ли оно?
    // но быть может стоит сделать exit да и все. и не мудрить. это у императивов удачно совпало что
    // return можно юзать в качестве exit-а. а у нас stop может стоит сделать отдельно.
    env.feature("delayed");
    env.timeout( () => {

      if (!(env.paramAssigned("input") || env.paramAssigned(0))) {    
        //console.log("see clean return D", env.params, env.linksToObject())
        send_result(null);
      }

    },10); // время пайпе построиться...
    /*
    setTimeout( () => {
      console.log("see clean return T", env.params, env.linksToObject())
    },100)
    */
    
}

// выставляет ограничение по времени работы. Если <=0 то вечность
// идея - сделать вообще просто передачу параметра.
// и вообще можно реализовать через поиск объектов..
// find-objects-by-crit "spawn-frame" direction="up" | set-param ...
export function mf_timeout( env )
{
  function send_result(a) {
    let p = env.ns.parent;
    while (p) {
      if (p.is_feature_applied("spawn_frame")) {
        p.setParam("timeout_ms",a)
        break
      }
      p = p.ns.parent
    }
    if (!p) {
      console.warn( "mf_timeout: cannot find spawn_frame")
    }
  }
  env.onvalues_any( ["input",0],(a,b) => {
    send_result(a || b)
  })
  
}

// корневой объект для содержимого make-func
export function spawn_frame( env )
{
  /*
  let unsf = () => {}
  function subscribe_for_finish() {
    unsf(); 
    let cc = env.ns.getChildren();
    if (cc.length > 0) {
        let lastc = cc[ cc.length-1 ];
        unsf = lastc.monitor_defined("output",(v) => {
          console.log("spawn frame: catched output of last child,",v,env,
              "last-child:",lastc)
          console.log("all children:")
          cc.forEach( c => console.log(c))
          //console.log(cc)
          env.setParam("output",v);
        });
     }
     else {
        unsf = () => {}
     }
  }*/

  env.feature("delayed")
  env.perform_stop = () => {
    env.setParam("output","timeout-stop")
  }
  env.stop_tmr = () => {}
  env.set_timeout_ms = (t) => {
    if (env.stop_tmr) env.stop_tmr()
    if (t > 0)
        env.stop_tmr = env.timeout_ms( env.perform_stop, t )
    else env.stop_tmr = () => {}
  }
  if (!env.paramAssigned("timeout_ms"))
       env.setParam( "timeout_ms", 1000 ) // время работы по умолчанию
  env.onvalue("timeout_ms", env.set_timeout_ms )   
  //env.set_timeout_ms( 10*1000 ); 
  
  //subscribe_for_finish();
  //env.on("childrenChanged",subscribe_for_finish)
}

// параметр code либо дети { }
// запускает "подпроцесс" описанный в code
// завершает его, когда последний оператор подпроцесса вернет что-то отличное от undefined
// в своем параметре output
// либо когда вызовут return <что-то>
export function make_func( env )
{
  let env_list;
  let env_call_scope = env.$scopes.top();

  //let k = env.new_hosting_env().feature( "catch_children" )

  env.restoreChildrenFromDump = (dump, ismanual,$scopeFor) => {
    // короче выяснилось, что если у нас создана фича которая основана на repeater,
    // то у этого repeater свое тело поступает в restoreChildrenFromDump
    // а затем внешнее тело, которое сообразно затирает собственное тело репитера.
    if (!env_list) {
      //console.log("when consuming children",dump.children)
      env_list = Object.values( dump.children );
      env_list.env_args = dump.children_env_args;
      env_call_scope = $scopeFor;
      if (env_list.length > 0)
        env.setParam( env.params.make_func_output || "output",f);
    }
    return Promise.resolve("success");
  }

  env.onvalue("code",(list) => {
    env_list = list;
    if (env_list.length > 0)
        env.setParam( env.params.make_func_output || "output",f);
  });

  //env.$vz_children_autocreate_enabled = false;

  let unsub = () => {};
  env.on("remove",() => {
    //console.log("when removed", env.getPath())
    unsub()
  });

  let f = (...args) => {
    // теперь.. что мы вернем
    //console.log("make-func: call of f",...args)
    let spawn_obj = env.vz.createObj( { parent: env, name: "spawn" });
    spawn_obj.feature("spawn_frame")

    let k = new Promise( (resolve,reject) => {
      // console.log("make-func passing",args)
      let p = env.vz.callEnvFunction( env_list, spawn_obj, false, env_call_scope, ...args );
      p.then( () => {
        // короче такая защита чтобы дать еще 1 цикл для счета...
        // изначально было вообще смотреть расчеты в дереве
        // еще идея - delayed-restart т.е. если еще раз прислали output то подождать еще циклов
        // env.feature("delayed");
        // let finish = env.delayed( finish0 );

        // spawn_obj.ns.getChildren()[0].onvalue("output",finish);
        spawn_obj.monitor_defined("output",finish0)

        function finish0( res ) {
           // выяснилось что они во время удаления могут себе чистить output..
           // поэтому эту ситуацию мы отловим особо
           // может быть стоит просто однократно output читать, либо отписываться тут
           // от onvalue - тоже вариант
           if (spawn_obj.removed || spawn_obj.removing)
             return;
           //console.log("make-func: call of f finish, res=",res, env.getPath())
           spawn_obj.remove();
           //console.log("cleanup complete, resolving")
           resolve( res );
        }
      });

    });
    k.make_func_result=true;
    return k;
  }

  

};


/*
export function once( env ) {
  let env_list;
  let env_call_scope = env.$scopes.top();

  env.restoreChildrenFromDump = (dump, ismanual,$scopeFor) => {
    // короче выяснилось, что если у нас создана фича которая основана на repeater,
    // то у этого repeater свое тело поступает в restoreChildrenFromDump
    // а затем внешнее тело, которое сообразно затирает собственное тело репитера.
    if (!env_list) {
      //console.log("when consuming children",dump.children)
      env_list = Object.values( dump.children );
      env_list.env_args = dump.children_env_args;
      env_call_scope = $scopeFor;
      ready();
    }
    return Promise.resolve("success");
  }

  //env.$vz_children_autocreate_enabled = false;

  let unsub = () => {};
  env.on("remove",() => {
    //console.log("when removed", env.getPath())
    unsub()
  });

  let f = (...args) => {
    // теперь.. что мы вернем
    console.log("call of f",...args)
    let spawn_obj = env.vz.createObj( { parent: env, name: "spawn" });

    let k = new Promise( (resolve,reject) => {

      let p = env.vz.callEnvFunction( env_list, spawn_obj, false, env_call_scope, ...args );
      p.then( () => {
        spawn_obj.ns.getChildren()[0].onvalue("output",finish);

        function finish( res ) {
           spawn_obj.remove();
           resolve( res );
        }
      });

    });
    k.make_func_result=true;
    return k;
  }

  let ready = () => {
    ready = () => {};

    let resp = f();
    resp.then( (result) => env.setParam("output",result));
  }  

  env.onvalue("code",(list) => {
    env_list = list;
    ready();
  });  
}
*/