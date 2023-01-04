// todo может быть стоит input после позиционных аргументов добавлять в m-eval - логичнее

export function setup(vz, m) {
  vz.register_feature_set(m);
}

// Мишин eval
// m-eval 'name-or-code-or-func' arg1 arg2 name1=v1 name2=v2;

export function m_eval( env ) {
  // env.setParam("output",undefined);
  env.setParamOption("output","internal",true);

  //console.error("compolang eval init",env.getPath())

    env.feature("delayed");
    let warn_code_not_found = env.delayed( () => {
        console.warn("m_eval: code not specified",env.getPath() );
        env.vz.console_log_diag( env )
    },600);

  function evl() {
    //console.log("evl called", env.getPath())
    //env.vz.console_log_diag( env )
    if (env.params.debug)
       debugger;

    if (!func) update_code();
    if (!func) {
      warn_code_not_found();
      return;
    }
    warn_code_not_found.stop();

    let args = [];

    // надо бы и инпут подсобрать
    //if (env.paramAssigned)
    if (env.hasParam("input") || env.hasLinksToParam( "input")) {
      let v = env.params.input;
      
      /* пусть тема инпута контролируется ток одним
      if (!env.params.allow_undefined && typeof(v) == "undefined") { // ну пока так.. хотя странно все это..
        console.warn("m-eval: return default / have undefined arg input");
        return env.params.default;      
      }
      */
      if (!env.params.allow_undefined_input && typeof(v) == "undefined") { // ну пока так.. хотя странно все это..
        //console.warn("m-eval: return default / no input");
        return env.params.default;
      }
      args.push( v );
    };

    for (let i=1; i<env.params.args_count;i++)
    {
      let v = env.params[i];

/*    todo будущее правильное вот так: QQQ
      if (!env.params.allow_undefined && !env.hasParam(i)) { // еще не присвоили.. - значит надо ждать
         return env.params.default; 
      }
*/      
      // надо не allow_undefined а allow_uncomputed.. а его проверять по hasParam
      // todo
      
      if (!env.params.allow_undefined && typeof(v) == "undefined") { // ну пока так.. хотя странно все это..
        /// 
        //console.warn("m-eval: return default / have undefined arg");
        return env.params.default;
      }
      
      args.push( v );
    }

    //console.log("compolang eval working",env.getPath(),args)

    let res = func.apply( env, args );

    // make-function
    //console.log("m-eval res=",res)
    if (res && res.make_func_result)
    {
       //console.log("m-eval res is make_func_result, waiting output",res)
       // получается у нас тут порядок пока не шибко то и определен
       res.then( (result) => {
          //console.log("m-eval res is make_func_result, got output",result)
          env.setParam("output",result);
       });
    }
    else
       env.setParam("output",res);

    //console.log("eval emitting done",env,res)
    env.emit("computed",res);
     // env.emit("done",res);
  }

  env.feature("delayed");
  var eval_delayed = env.delayed( evl )

/*
  var eval_delayed0 = env.delayed( evl )
  var eval_delayed = () => { 
    debugger;
    eval_delayed0();
  }
*/  

  env.on('param_changed', (name) => {
     if (name != "output" && name != "recompute" && name != 0) {
        //console.log("eval scheduled due to param change",name)

        //if (name == 0 || name == "0") update_code();

        if (env.params.react_only_on_input && name != "input") return;
        //console.log("eval scheduled due to param change",name,env.getPath())

        eval_delayed();
     }
  });

  let func;

  function update_code() {
    let code = env.params[0];
    if (code)
    {
      // возможность прямо код сюды вставлять
      if (typeof( code ) == 'function')
         func = code;
      else {
        var scope = js_access_compalang_scope( env );
        func = eval( code );
      }
    }
  }

/* вроде как это не надо - param-changed хватает. ну и там 0 отдельную реакцию повесили
   а то получается что 2 раза отрабатываем - там сразу и тут на след такте
*/   
/*
  env.onvalues_any([0],() => {
     update_code();
     eval_delayed();
     // итоого у нас уже вызов некий произойдет
  })
*/  
  // ну или ладно сделаем хотя бы monitor-values а не onvalues
  env.trackParam(0,(c) => {
     update_code();
     if (func) {
         //console.log("eval scheduled due to code change [0]",c,env.getPath())
         eval_delayed();
     }    
     // итоого у нас уже вызов некий произойдет
  })

  env.addCmd("recompute",eval_delayed);

// косяк евала иметь 2й вызов вычисления
// по сути оно с первым не связано и посему - они оба выполнятся
// кроме того неясно зачем это выполнять если итак будучи выставив код
// пойдет вычисление
//  var eval_delayed2 = env.delayed( evl,2 )
//  eval_delayed2();
};

//////////////////////////////////////////////////
// процесс, возвращающий функцию. код написан на языке js

// m_js 'name-or-code'
// из идей - приделать сюда тоже позиционную передачу аргументов..  и чтобы env было равно родителю так-то
// см также x-js

export function m_js( env ) {
  env.onvalue( 0, (code) => {
    let f = eval( code );
    env.setParam("output",f);
  });
};

//////////////////////////////////////////////////
// процесс, по команде apply выполняющий заданную функцию с заданными аргументами
// m-apply 'name-or-code-or-func' arg1 arg2 name3=value3 name4=value4

// это все-таки не apply а лямбда. ну с аргументами, жизнь такая, ей привязываться надо а по другому
// у нас связки данных мира compalang и мира js не делается.

// на сд еще вопрос надо ли нам команду apply - это же наша выдумка личная. может быть достаточно было бы
// сказать что вот m_apply работает так что идет еще и по детям и вызывает у них кто в output функцию дает её
// а и заодно результат последней возвращает. что-то такое. и тогда команда apply была бы не нужна?..
// ну и еще тема подготовки аргументов - что вызывать их как функции.. функциональная история..

// все-таки это лямбда. ну т.е. процесс генерирующий лямбду.
export function m_lambda( env,opts ) {
  env.feature("m_apply",opts);
}

function js_access_compalang_scope( env ) {
  return new Proxy({}, {
    set: function(target, prop, value, receiver) {
      //target[prop] = value
      env.$scopes[0].$add( prop, value );
      //console.log('property set: ' + prop + ' = ' + value)
      return true
     },
    get: function(target, prop, receiver) {

      let s = env.$scopes[0];

      //console.log('access to scope. env.$scopes is', env.$scopes)

      let item = s[prop];
      //if (!item)
      //     return false;
      /* можно поползать */
      // оказалось что мы запускаем вложенные скопы on-message={ |a b c| .. }
      while (!item && s.$lexicalParentScope)
      {
        s=s.$lexicalParentScope; 
        item = s[prop]
      }
      if (!item)
           return false;
      /*
      if (!item) {
        s=s.$lexicalParentScope; // ну хотя бы раз надо заползти... хотя это дорого начинается..
        item = s[prop]
        if (!item)
           return false;
      }
      */
      
      if (item.setParam && item.is_feature_applied('is_positional_env')) // там сидит позиционное
          return item.params[0];
      if (item.is_cell)  
          return item.get();

      return item;  
      //return Reflect.get(...arguments);
    } 
    })
}

export function m_apply( env, opts )
{
   //env.lambda_start_arg ||= 0;
   env.lambda_start_arg = opts?.lambda_start_arg || 0;

   env.feature("call_cmd_by_path");

  // пусть у лямбды аутпут будет js-функция для вызова
  
  env.setParam("output", (...args) => {
    //return env.callCmd("apply",...args);
    // ускоренье в тыщу раз:
    return env.apply(...args);
  })
  
  // изменились параметры - меняем параметр .output
  env.on("param_changed",(name) => {
    if (name == "output") return;
    //console.log("mapplay update-func 2")
    env.setParam("output", (...args) => {
      //return env.callCmd("apply",...args);
      return env.apply(...args);
    });
  });

  let func;
  function update_func() {
    let code = env.params[ env.lambda_start_arg ];

    var scope = js_access_compalang_scope( env );

    func = eval( code );
  }
  env.onvalues_any([ env.lambda_start_arg ],update_func);

   //console.log( "feature_func: installing apply cmd",env.getPath());
   env.setParamOption("apply","visible",false);
   env.addCmd( "apply",(...extra_args) => {
      if (env.removed) {
         console.warn("lambda called but its env is removed", env.getPath())
         env.vz.console_log_diag( env )
         return;
      }

      // получается нам apply может прилететь пока мы даже еще onvalues не обработали.. нормально..
      if (!func) update_func();
      if (!func) {
        console.error("lambda: code is not defined but apply is called", env.getPath());
        return;
      }
      //console.log("lambda apply",env.getPath())

      let args = [];
      for (let i=(env.lambda_start_arg+1); i<env.params.args_count;i++) {
        let v = env.params[i];

        if (env.params.check_params && v == null) { // ну пока так.. хотя странно все это..
          return;
        }
        
        args.push( v );
      }

      for (let i=0; i<extra_args.length;i++) 
        args.push( extra_args[i] );

      //args = args.concat( extra_args );


      return func.apply( env,args )
   } );
}

//////////////////////////////////////////////////

// операция компоновки объектов (процессов)
// compose_input - список объектов для операции
/*
входы:
- с одинаковыми именами объединяются т.е. то что идет на вход - рассылается обоим
- с разными именами - поступают тому чье имя.
выходы:
- с одинаковыми именами - объединяются в вектор
- с разными именами (уник) - продолжают быть собой

 реализация: 
  * по факту у нас нет входов выходов а только наметки..
  * не страшно выглядит если мы будем просто все входящие параметры широковещать обоим да и все
    если будет внутри объект реагировать ну ок, если нет - то и ладно

 update: вроде как по факту у нас это все уже есть в отдельных операциях.
 сборка выходов: @arr | map_geta "some-name"
 сборка входов: @arr | x-modify { x-set-params alfa=5 beta=7 };
*/
export function compose_p(env) {
  let uu = create_unsub_list(env);
  let input = [];

  let compose_input_name = "input";
  // засада если это input то мы тем input не раскинем...
  // но предполагаю что compose_p инпут нужен будет чаще
  // а если тем надо будет, ну сделаем им __input передачу
  // ну или parallel я еще хотел сделать..
  // короче дилемма

/*
  if (env.params.use_children) {
    input = env.ns.children;
    env.on("childrenChanged",())
  }
*/  
  
  // входы - широковещаем
  env.on("param_changed",pass_broadcast_input);

  function pass_broadcast_input( p,v ) {
     if (p == compose_input_name) return;
     // таким образом то что мы выдали на gather_output - здесь отсечется.
     if (env.getParamOption( p,"isoutput") ) return;

     for (let c of input) {
        c.setParamOption( p,"isinput", true );
        c.setParam( p,v );
     };    
  }

  // собираем выходы
  env.onvalue( compose_input_name, (inp) => {
    start_gathering_output( inp )
    /*
    if (env.params.use_children)
       inp = env.ns.children;
     else
       inp = env.params.input;
    // вот мы и приехали в ситуацию когда чилдрены должны быть чистыми
    // и причем неясно по какому признаку - они и не дом и не...
    // но ссылок, репитеров, инсерт-чилрденов, ифов нам тут не надо.. 

    короче отложим это пока
    */
  });

  function start_gathering_output(inp) {
    uu.unsubscribe();

    if (!Array.isArray(inp)) {
      input = [];
      console.warn("compose: input is not array", inp, env.getPath(), env);
      return;
    }
    inp = inp.filter(n => n);

    if (inp.length == 0)
      console.warn("compose_p: input len is 0");

    input = inp;

    // зададим текущие входы
    for (let p of env.getParamsNames()) {
      pass_broadcast_input( p, env.getParam(p) );
    }

    for (let c of input)
    {
      // будем ждать сигналов от процесса для передачи на общий выход
      uu.subscribe( c.on("param_changed", gather_output ));
      // разошлем текущие значения на выходы
      for (let p of c.getParamsNames())  // todo optimize дублирование
        gather_output( p, c.getParam(p) );
    }
  }

  function gather_output(name,value) {
     //.. выходной параметр объекта поменялся..
     
     let count = 0;
     for (let c of input) {
       if (c.hasParam( name )) { 
          if (c.getParamOption( name,"isinput" )) {
            //console.log("compose:")
            // быстро выяснено что это был входной параметр - отсекаем
            return;
          }
          if (c.getParamOption( name,"manual" )) {
            return;
          }
          count++;
          if (count > 1) break;
       }
     };
     
     let acc;
     if (count > 1) // режим сборки в массив
     {
        acc = input.map( (c) => c.getParam(name));
     }
     else
     { // обычный режим
        acc = value;
     }
     env.setParamOption( name, "isoutput", true );
     env.setParam( name, acc );
  }; // gather_output

}

function create_unsub_list(env)
{
  let unsub_arr = [];
  
  unsub_arr.unsubscribe = () => {
    unsub_arr.map( f => f() );
    unsub_arr.length = 0;
  }
  unsub_arr.subscribe = (f) => {
    unsub_arr.push( f );
  }

  env.on("remove",unsub_arr.unsubscribe)

  return unsub_arr;
}
