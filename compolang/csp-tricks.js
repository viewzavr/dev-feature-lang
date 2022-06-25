export function setup(vz, m) {
  vz.register_feature_set(m);
}

export function when( env ) {
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
    }
    return Promise.resolve("success");
  }

  env.onvalue("list",(list) => {
    env_list = list;
  });

  //env.$vz_children_autocreate_enabled = false;

  let unsub = () => {};
  env.on("remove",() => {
    //console.log("when removed", env.getPath())
    unsub()
  })

  env.onvalues([0,1],(obj,event) => {
    unsub();
    //console.log("when subscribing to evnt",event)
    unsub = obj.on( event,(...args) => {
      let parent = env.ns.parent;
      env.ns.parent.ns.removeChildren();
      // родителя почистили и переходим в новую стадию
      
      env.vz.callEnvFunction( env_list, parent, false, env_call_scope, ...args )
    } );
  })

}

export function when_value( env ) {
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
    }
    return Promise.resolve("success");
  }

  env.onvalue("list",(list) => {
    env_list = list;
  });

  //env.$vz_children_autocreate_enabled = false;

  let unsub = () => {};
  env.on("remove",() => {
    //console.log("when removed", env.getPath())
    unsub()
  })

  env.onvalue(0,(value) => {
    unsub();
    let parent = env.ns.parent;
    env.ns.parent.ns.removeChildren();
    // родителя почистили и переходим в новую стадию
    env.vz.callEnvFunction( env_list, parent, false, env_call_scope, value )
  })

}

// вот эта штука рестартует указанный объект с новой логикой
// сохраняя при этом сам объект
// может быть этого делать и не стоит
export function restart( env ) {
  let env_list;

  env.restoreChildrenFromDump = (dump, ismanual) => {
    // короче выяснилось, что если у нас создана фича которая основана на repeater,
    // то у этого repeater свое тело поступает в restoreChildrenFromDump
    // а затем внешнее тело, которое сообразно затирает собственное тело репитера.
    if (!env_list) {
      env_list = Object.values( dump.children );
    }
    return Promise.resolve("success");
  }

  env.onvalue("list",(list) => {
    env_list = list;
  });

  env.onvalue(0,(obj) => {
    let d = env_list[0];
    d.keepExistingChildren=true;
    // пущай все вычищает
    let parent = env.ns.parent;
    obj.ns.removeChildren();    
    
    // грязный хак - надо рестартануть оригинальный объект
    for (let k of Object.keys( d.features )) {
      if (k == "base_url_tracing") continue;
      if (obj.is_feature_applied(k))
        obj.unfeature( k );
    }

    //console.log("Restart performing",obj,d)
    
    obj.restoreFromDump( d, false, env.$scopes.top() );
  });

};  

// вариант с пересозданием объекта логики к хренам
// кстати фишка их может быть несколько, новых объектов
export function hard_restart( env ) {
  let env_list;

  env.restoreChildrenFromDump = (dump, ismanual) => {
    // короче выяснилось, что если у нас создана фича которая основана на repeater,
    // то у этого repeater свое тело поступает в restoreChildrenFromDump
    // а затем внешнее тело, которое сообразно затирает собственное тело репитера.
    if (!env_list) {
      env_list = Object.values( dump.children );
    }
    return Promise.resolve("success");
  }

  env.onvalue("list",(list) => {
    env_list = list;
  });

  env.onvalue(0,(obj) => {
    let d = env_list[0];
    d.keepExistingChildren=true;
    // пущай все вычищает
    let parent = env.ns.parent;

    //console.log("Restart performing",obj,d)

    let objparent = obj.ns.parent;
    obj.remove();

    //dump, _existingObj, parent, desiredName, manualParamsMode, $scopeFor )
    //env.vz.createSyncFromDump( d, null, objparent, obj.ns.$name, false,env.$scopes.top() )
    env.vz.callEnvFunction( env_list, objparent, false, env.$scopes.top() )
  });

};  