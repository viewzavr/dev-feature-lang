/*
Миша идея - а зачем when объекты то удаляет?
думаю: в принципе до restart-а можно и не удалять. так-то.
*/

export function setup(vz, m) {
  vz.register_feature_set(m);
}

// create_envs parent envlist-function arg1 arg2 ...
/*
export function create_envs(env)
{
  env.onvalue( "" )
}
*/

// корень для логики csp. смысл сохранить дамп, для рестарта.
export function csp( env ) {

  let orig = env.restoreFromDump;

  env.restoreFromDump = (dump,manualParamsMode, $scopeFor ) => {
    env.dump_for_restart = dump;
    return orig( dump, manualParamsMode, $scopeFor );
  };

};

// when @obj "event" then={ ..... }
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

  env.onvalue("then",(list) => {
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

// при поступлении не-null значения...
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

  env.onvalue("then",(list) => {
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

// when_cell @cell then={ ..... }
// см comm3.js
// но эт ток на новых событиях... кстати... или кстати нет? да, ток на новых...
// т.е. это не промиса как бы... а хочется еще и с промисой попробовать...

export function when_cell( env ) {
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

  env.onvalue("then",(list) => {
    env_list = list;
  });

  //env.$vz_children_autocreate_enabled = false;

  let unsub = () => {};
  env.on("remove",() => {
    //console.log("when removed", env.getPath())
    unsub()
  })

  env.onvalues([0],(cell) => {
    unsub();
    //console.log("when_cell subscribing to evnt of cell",cell);
    if (!cell || !cell.is_cell) {
      console.error('cell arg is not a cell')
      return;
    }
    //console.log("cell.is_value_assigned()",cell.is_value_assigned())
    unsub = cell.on( "assigned",fn );

    if (env.params.existing && cell.is_value_assigned())
        fn( cell.get() );

    function fn (...args) {
      let parent = env.ns.parent;
      env.ns.parent.ns.removeChildren();
      // родителя почистили и переходим в новую стадию
      
      env.vz.callEnvFunction( env_list, parent, false, env_call_scope, ...args )
    }
    
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
    console.log("csp restart for",obj)
    let d = env_list[0];

    if (!d) {

      if (obj.dump_for_restart) {
         obj.ns.removeChildren();
         console.log("restarting from dump",obj.dump_for_restart)
         return obj.restoreFromDump( obj.dump_for_restart, false, env.$scopes.top() );  
      };
      console.error("csp restart: no list, child and dump_for_restart. Dont know how to restart.", env)
      return null;  
    }

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