export function setup(vz, m) {
  vz.register_feature_set(m);
};

// параметр code либо дети { }
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
    }
    return Promise.resolve("success");
  }

  env.onvalue("code",(list) => {
    env_list = list;
  });

  //env.$vz_children_autocreate_enabled = false;

  let unsub = () => {};
  env.on("remove",() => {
    //console.log("when removed", env.getPath())
    unsub()
  });

  let f = (...args) => {
    // теперь.. что мы вернем
    //console.log("call of f",...args)
    let spawn_obj = env.vz.createObj( { parent: env, name: "spawn" });

    let k = new Promise( (resolve,reject) => {
      //console.log("make-func passing",args)
      let p = env.vz.callEnvFunction( env_list, spawn_obj, false, env_call_scope, ...args );
      p.then( () => {
        // короче такая защита чтобы дать еще 1 цикл для счета...
        // изначально было вообще смотреть расчеты в дереве
        // еще идея - delayed-restart т.е. если еще раз прислали output то подождать еще циклов
        env.feature("delayed");
        let finish = env.delayed( finish0 );

        spawn_obj.ns.getChildren()[0].onvalue("output",finish);

        function finish0( res ) {
           // выяснилось что они во время удаления могут себе чистить output..
           // поэтому эту ситуацию мы отловим особо
           // может быть стоит просто однократно output читать, либо отписываться тут
           // от onvalue - тоже вариант
           if (spawn_obj.removed || spawn_obj.removing)
             return;
           //console.log("call of f finish, res=",res, env.getPath())
           spawn_obj.remove();
           resolve( res );
        }
      });

    });
    k.make_func_result=true;
    return k;
  }

  env.setParam( env.params.make_func_output || "output",f);

};



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