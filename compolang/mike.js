export function setup(vz, m) {
  vz.register_feature_set(m);
}

// Мишин eval
// m-eval 'name-or-code-or-func' arg1 arg2 name1=v1 name2=v2;

export function m_eval( env ) {
  env.setParam("output",undefined);
  env.setParamOption("output","internal",true);

  //console.error("compolang eval init",env.getPath())

    env.feature("delayed");
    let warn_code_not_found = env.delayed( () => {
        console.warn("m_eval: code not specified",env.getPath(),env );
    },20);  

  function evl() {

    if (!func) update_code();
    if (!func) {
      warn_code_not_found();
      return;
    }
    warn_code_not_found.stop();


    let args = [];

    for (let i=1; i<env.params.args_count;i++) 
    {
      let v = env.params[i];
      // надо не allow_undefined а allow_uncomputed.. а его проверять по hasParam
      // todo
      if (!env.params.allow_undefined && typeof(v) == "undefined") { // ну пока так.. хотя странно все это..
        /// 
        return;
      }
      args.push( v );
    }

    //console.log("compolang eval working",env.getPath(),args)

    let res = func.apply( env, args );

    env.setParam("output",res);
  }

  env.feature("delayed");
  var eval_delayed = env.delayed( evl )

  env.on('param_changed', (name) => {
     if (name != "output")
        eval_delayed();
  });

  let func;

  function update_code() {
    let code = env.params[0];
    if (code)
    {
      // возможность прямо код сюды вставлять
      if (typeof( code ) == 'function')
         func = code;
      else
        func = eval( code );
    }
  }

  env.onvalues_any([0],() => {
     update_code();
     eval_delayed();
     // итоого у нас уже вызов некий произойдет
  })

  env.addCmd("recompute",eval_delayed);

  var eval_delayed2 = env.delayed( evl,2 )
  eval_delayed2();
};

//////////////////////////////////////////////////
// процесс, возвращающий функцию. код написан на языке js

// m_js 'name-or-code'
// из идей - приделать сюда тоже позиционную передачу аргументов..

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
export function m_lambda( env ) {
  env.feature("m_apply");
}

export function m_apply( env )
{
   env.feature("call_cmd_by_path");

  // пусть у лямбды аутпут будет js-функция для вызова
  
  env.setParam("output", (...args) => {
    return env.callCmd("apply",...args);
  })
  
  env.on("param_changed",(name) => {
    if (name == "output") return;
    //console.log("mapplay update-func 2")
    env.setParam("output", (...args) => {
      return env.callCmd("apply",...args);
    });
  });

  let func;
  function update_func() {
    let code = env.params[0];
    func = eval( code );
  }
  env.onvalues_any([0],update_func);

   //console.log( "feature_func: installing apply cmd",env.getPath());
   env.addCmd( "apply",(...extra_args) => {
      if (env.removed) {
         console.log("lambda remove ban - it is removed", env.getPath())
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
      for (let i=1; i<env.params.args_count;i++) 
        args.push( env.params[i] );

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
