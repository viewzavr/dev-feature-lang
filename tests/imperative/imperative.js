// ну на самом деле это не императивное а пошаговое.. ну ладно..

export function setup(vz, m) {
  vz.register_feature_set( m );
}

export function i_lambda( env ) 
{
  env.setParam("output",apply);

  env.addCmd( "apply", apply );

  function apply() {
    // рассчитать аргументы.
    // передать себе в код.

    if (!func) update_code();
    if (!func) {
      console.error("i_code: code not specified",env.getPath())
      return;
    }

    let args = [];

    // семантика - пройтись по параметрам и вызвать их пересчет.
    // потом полученные результаты передать в свою функцию.

    // оп. а это оказывается работает только для позиционных параметров..
    // а я так хвалился, так хвалился.. тем что у нас будет и ключи-параметры..
    // а получается сейчас qqq: i-console-log alfa=15 не сработает..
    for (let i=0; i<env.params.args_count;i++)
    {
      let v = env.params[i];

      // волшебный момент
      console.log({i,v})
      if (v?.this_is_i_lambda) {
        //console.log("calling v")
        v = v();
      }
      
      args.push( v );
    }

    //console.log("compolang eval working",env.getPath(),args)

    let res = func.apply( env, args );

    return res;

  }
  apply.this_is_i_lambda = true;

  let func;

  function update_code() {
    let code = env.params.code;
    if (code)
    {
      // возможность прямо код сюды вставлять
      if (typeof( code ) == 'function')
         func = code;
      else
         func = eval( code );
    }
  }

  // далее мы считаем что code - вызовет по умолчанию trailing-lambda
  // и это значит что мы сможем писать вещи так:
  /* r: i-lambda { i-console @r->0 }
  */

  ///// подтоговтим функцию передачи управления операторам из блока {}.

  function update_attached_block() {
    let call_attached_block_operators = (...args) => {
      let res;
      let args_rec = {args_array: args};
      for (let q of env.ns.getChildren()) {

        let v = q.params.output;

        // собственно применение apply к функции, заданной данным оператором..
        // но кстати, хотелось бы писать и так: q: 5; ну или q: alfa=5 beta=(compute...)
        // т.е. у окружения нет своей лямбды, но аргументы вычислить как бы надо..
        // но и не просто вычислить а записать их... чтобы потом использовать.. загадка...
        if (v?.this_is_i_lambda) {
          v = v.apply( args_rec );
          // просто передать управление, без параметров - если там нужны параметры то их возьмут
          // их окружения или из args-окружения (для этого мы передаем args_rec текущее)
          // тут бы return проверить - не вернули ли то что надо выходить. ну ладно пока.

          // пока будем присваивать "результат" только от того что было "нашим"
          res = v;
        };
        
      };
      
      return res;
    };
    call_attached_block_operators.this_is_i_lambda = true; // тоже отметим

    env.setParam("attached_block",call_attached_block_operators);
    env.addCmd("eval_attached_block",call_attached_block_operators)
    env.eval_attached_block = call_attached_block_operators;

    env.setParam("has_attached_block", env.ns.getChildren().length > 0);
  };

  env.on("appendChild",update_attached_block);
  update_attached_block();

  // лямбда это как выяснено вещь состоящая из:
  // 1 параметры для алгоритма передачи параметров
  // 2 тело лямбды (код который надо выполнить)
  // тело у нас может быть в 2 формах задано пусть:
  // а) js код (func), б) операторы в кавычках {}
  // сообразно мы делаем так что func по умолчанию равен выполнению {} кавычек.
  // при этом, в варианте (б) мы не работаем над темой передачи параметров
  // т.к. считается что эта тема будет решена отдельно за счет обращения из операторов
  // к переменным окружений, или к спец-окружению args.

  // на будущее - может быть стоит писать не js="(a,b) => ...."
  // а все-таки js=" код " а параметры приделать автоматически.
  // это позволило бы решать и вопрос с аргументами для тела на компаланге..
  // ну пусть пока тк.

  //func = (...args) => return env.callCmd("eval_attached_block",...args);
  func = (...args) => env.eval_attached_block(...args);

  env.onvalues_any(["code"],() => {
     update_code();
  });

}

export function i_sum( env ) {
  env.feature("i_lambda");
  env.setParam("code",f);

  function f(...args) 
  {
    // console.log("summing",...args);
    let sum = args[0];
    for (let i=1; i<args.length; i++)
      sum = sum + args[i];
    // console.log("Returning",sum)
    return sum;
  }

}

export function i_mul( env ) {
  env.feature("i_lambda");
  env.setParam("code",f);

  function f(...args) 
  {
    let sum = args[0];
    for (let i=1; i<args.length; i++)
      sum = sum * args[i];
    return sum;
  }

}

export function i_console_log( env ) {
  env.feature("i_lambda");
  env.setParam("code",f);

  function f(...args) 
  {
    console.log(...args);
  }

}

export function i_less( env ) {
  env.feature("i_lambda");
  env.setParam("code",f);

  function f(...args) 
  {
    if (args.length != 2) return false;
    return args[0] < args[1];
  }

}

export function i_more( env ) {
  env.feature("i_lambda");
  env.setParam("code",f);

  function f(...args) 
  {
    if (args.length != 2) return false;
    return args[0] > args[1];
  }

}

function const_or_call( v ) {
  if (v?.this_is_i_lambda)
    v = v();
  return v;
}

export function i_if( env ) {
  env.feature("i_lambda");

  // тут уже свой алгоритм должен быть, не стандартный
  
  env.addCmd( "apply", apply );
  env.apply = apply; // хак на хаке

  env.setParam("output",apply);

  function apply() {

    if ((env.params.args_count || 0) <= 0) return; 

    let predicate_value = const_or_call( env.params[0] );

    //console.log("predicate_value=",predicate_value,"env.params=",env.params)
    if (predicate_value) {
      if (env.params.has_attached_block)
        return env.eval_attached_block();
      else
        return const_or_call( env.params[1] )
    }
    else
    {
      return const_or_call( env.params[2] )
    }
  }
  apply.this_is_i_lambda = true;

}

// назначение - разместить аргументы, с которыми пришли к текущему блоку
// в данном окружении (i-args);
// пример: i-repeat 10 { aa: i-args; i_console_log @aa->0; }

export function i_args( env ) {
  env.feature("i_lambda");

  env.addCmd( "apply", apply );
  env.apply = apply; // хак на хаке
  env.setParam("output",apply);

  function apply() {
     //console.log( 'this is',this );
     // перекидываем аргументы в текущее окружение
     if (this.args_array) {
       for (let i =0; i<this.args_array.length; i++)
         env.setParam( i, this.args_array[i] );
       for (let i= this.args_array.length; i < env.params.args_count; i++)
         env.setParam( i, undefined );
       env.params.args_count = this.args_array.length;
     }
     else
     {
      for (let i=0; i < env.params.args_count; i++)
         env.setParam( i, undefined );
       env.params.args_count = 0; 
     }
  }
  apply.this_is_i_lambda = true;
}  

export function i_call( env ) {
  env.feature("i_lambda");
  env.setParam("code",f);

  function f(...args) 
  {
    let func = args[0];
    if (typeof(func) == "function") {
      let res = func.apply( env, args.slice(1,-1) );
      return res;
    }
    else {
       console.error("i-call: first arg is not a function",args)
    }
  }

}