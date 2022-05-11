// ну на самом деле это не императивное а пошаговое.. ну ладно..


export function setup(vz, m) {
  vz.register_feature_set( m );
}

function compute_params( env ) {
  let res = {};
  for (let i of Object.keys(env.params)) {
    if (i == "output") continue; // самое себя не вызываем

    let v = env.params[i];

    // у нас за счет процессов аргумент уже вычислен и выдает на output - функцию
    // (таковое мы добились см выше) и если это наша функция - мы ее вызываем
    //console.log({i,v})
    if (v?.this_is_imperative_participant) {
      //console.log("calling v")
      v = v();
    }
    res[i] = v;
  }
  res.args_count ||= 0;
  return res;
}

// здесь args это уже "наша" форма параметров, т.е это словарь, в котором также есть позиционные
// аргументы и допом к ним - args_count значение. это может использоваться затем в args-окружении.
function eval_attached_block( env, args ) {
    //if (Array.isArray(args)) тут можно чето нашаманить
    //  args_rec.args_dict = {} // или .args_arr = 
    let args_rec = {args_dict: args};
    let res;
    for (let q of env.ns.getChildren()) {
      let v = q.params.output;

        // собственно применение apply к функции, заданной данным оператором..
        // но кстати, хотелось бы писать и так: q: 5; ну или q: alfa=5 beta=(compute...)
        // т.е. у окружения нет своей лямбды, но аргументы вычислить как бы надо..
        // но и не просто вычислить а записать их... чтобы потом использовать.. загадка...
        // можно кстати через создание доп-окружения: i-lambda { q: args; } или типа того
        if (v?.this_is_imperative_participant) {
          v = v.apply( args_rec );
          // просто передать управление, без параметров - если там нужны параметры то их возьмут
          // их окружения или из args-окружения (для этого мы передаем args_rec текущее)
          // тут бы return проверить - не вернули ли то что надо выходить. ну ладно пока.

          // пока будем присваивать "результат" только от того что было "нашим"
          res = v;
        };
      };
      return res;  
}

// лямбда для и-вычислений
// результат срабатывания apply-операции этой штуки это функция по вызову блока лямбды
// есть нюанс - тут заодно выполняется каррирование, т.е. лямбда будет передавать в блок
// аргументы вопрядке: аргументы-лямбды, внешние аргументы
// вероятно это лишнее
export function i_lambda( env ) 
{
  env.this_is_lambda_env = true;
  env.lambda_apply = apply;

  let lambda_process_result = () => apply;
  lambda_process_result.this_is_imperative_participant = true;

  env.setParam("output",lambda_process_result );
  env.addCmd( "apply", lambda_process_result );

  function apply(...external_positional_args) {
    // рассчитать аргументы.
    // передать себе в код.

    let args = compute_params( env );

    // докопировать пришедшие извне.. ну справа..
    let ptr = args.args_count;
    for (let i=0; i<external_positional_args.length; i++)
      args[ ptr + i ] = external_positional_args[i];
    args.args_count += external_positional_args.length;  

    let res = eval_attached_block( env, args );
    
    return res;
  }
  // apply.this_is_imperative_participant = true;
  // хоть оно тут и не используется, но зато будет использоваться в...

  // лямбда это как выяснено вещь состоящая из:
  // 1 параметры для алгоритма передачи параметров
  // 2 тело лямбды (код который надо выполнить)
};

export function i_call_block( env ) 
{
  env.feature("i-lambda");
  env.setParam("output",env.lambda_apply, true );
  env.addCmd( "apply", env.lambda_apply, true );
  env.lambda_apply.this_is_imperative_participant = true;
}

// todo - абстрагировать подгтовоку аргументов
export function i_call_js( env ) 
{
  env.setParam("output",apply);
  env.addCmd( "apply", apply );

  function apply(...external_positional_args) {
    // рассчитать аргументы.
    // передать себе в код.

    if (!func) update_code();
    if (!func) {
      if (env.params.code)
        console.error("i_call_js: code is specified but compiles to nothing",env.params.code,env.getPath())
        else
        console.error("i_call_js: code not specified",env.getPath())
      return;
    }

    let args_dict = compute_params( env ); // это словарь, включая позиционные
    let args = [];

    // закопируем позиционные
    for (let i=0; i<args_dict.args_count;i++)
      args.push( args_dict[i] );

    // и добавим внешние... но кстати.. еще же в this могут быть, из блока переданные...
    // хотя из блока ниче не передается.. ну оно через спец-окружение args точнее передатеся..

    // договоримся вот как пока: наличие input приводит к его добавке в позиционные аргументы в js-кодах
    // хотя опять же... а другие как? ну другие.. пока никак...
    if (args_dict.input)
      args.push( args_dict.input );

    // ладно добавим хотя бы внешние - справа..
    for (let i=0; i<external_positional_args.length; i++)
      args.push( external_positional_args[i] );


    let res = func.apply( env, args );

    return res;

  }
  apply.this_is_imperative_participant = true;

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

  env.onvalues_any(["code"],() => {
     update_code();
  });

   // решено что на js часто мы захотим обращаться к {} блоку.
   // здесь args это словарь-нотация. т.е. { 0: "hello", 1: "world", args_count: 2} 
   env.eval_attached_block = (args) => eval_attached_block( env, args );

};

// вызывает функцию, указанную в первом аргументе
// кстати вот интересно.. процесс не вызывает, процесс генерирует функцию, которая есть
// вызов другой функции, вот в чем прикол то. ну и еще локальные аргументы процесса бы учеть
// которые в env заданы.
export function i_call( env ) {
 env.setParam("output",apply);
  env.addCmd( "apply", apply );

  function apply() { 
    let func = env.params[0];

    if (!func) {
      console.error("i-call: func is not specified");
      return;
    }
    if (func.this_is_lambda_env) {
      func = func.params.output();
    }
    else
    if (func.params) {
        func = func.params.output;
        if (!func) {
          console.error("i-call: func arg is specified as object, but it has no function in .output field")
          return;
        };
    }

    let args = [];

    // семантика - пройтись по параметрам и вызвать их пересчет.
    // потом полученные результаты передать в свою функцию.

    // оп. а это оказывается работает только для позиционных параметров..
    // а я так хвалился, так хвалился.. тем что у нас будет и ключи-параметры..
    // а получается сейчас qqq: i-console-log alfa=15 не сработает..
    for (let i=1; i<env.params.args_count;i++)
    {
      let v = env.params[i];

      // у нас за счет процессов аргумент уже вычислен и выдает на output - функцию
      // (таковое мы добились см выше) и если это наша функция - мы ее вызываем
      //console.log({i,v})
      if (v?.this_is_imperative_participant) {
        //console.log("calling v")
        v = v();
      }
      
      args.push( v );
    }

    //console.log("compolang eval working",env.getPath(),args)

    let res = func.apply( env, args );

    return res;

  }
  apply.this_is_imperative_participant = true;
}

// назначение - разместить аргументы, с которыми пришли к текущему блоку
// в данном окружении (i-args);
// пример: i-repeat 10 { aa: i-args; i_console_log @aa->0; }
// см также call_attached_block_operators

export function i_args( env ) {
  env.feature("i_lambda");

  env.addCmd( "apply", apply,true );
  env.setParam("output",apply);

  function apply() {
     //console.log( 'this is',this );
     // перекидываем аргументы в текущее окружение
     // это аргументы сделанные списоком которые

     if (this.args_dict) {
       for (let k of Object.keys( this.args_dict )) {
         env.setParam( k, this.args_dict[k])
       }
       // todo почистить
     }
     else
     {
       // todo почистить
       env.params.args_count = 0; 
     }
  }
  apply.this_is_imperative_participant = true;
};

//////////////////////////////////////////////
function const_or_call( v ) {
  if (v?.this_is_imperative_participant)
    v = v();
  return v;
}

export function i_if( env ) {
  env.feature("i_lambda");

  // тут уже свой алгоритм должен быть, не стандартный
  // типо как особая форма
  
  env.addCmd( "apply", apply, true );
  env.setParam("output",apply);

  function apply() {

    if ((env.params.args_count || 0) <= 0) return; 

    let predicate_value = const_or_call( env.params[0] );

    //console.log("predicate_value=",predicate_value,"env.params=",env.params)
    if (predicate_value) {
      if (env.ns.getChildren().length > 0)
        return env.lambda_apply();
      else
        return const_or_call( env.params[1] )
    }
    else
    {
      return const_or_call( env.params[2] )
    }
  }
  apply.this_is_imperative_participant = true;

}

////////////////////////////////////

export function i_repeat( env ) {
  env.feature("i_call_js");
  env.setParam("code",f);

  function f(count) {
     for (let i=0; i<count; i++)
     {
        //env.callCmd('eval_attached_block',i);
        // env.eval_attached_block( [i] );
        //eval_attached_block( env, [i] );
        eval_attached_block( env, {0:i,args_count:1} );
     }
  }

}

/* // версия на компаланге:
feature "i-repeat" {
  i_call_js code="(count) => {
     for (let i=0; i<count; i++)
     {
        //env.callCmd('eval_attached_block',i);
        // можно вернуть если надо будет
        env.eval_attached_block( i,{0:i,args_count:1} );
     }
  }";
};
*/

//////////////////////////////////////////////

export function i_sum( env ) {
  env.feature("i_call_js");
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

/*
export function i_join( env ) {
  env.feature("i_call_js");
  env.setParam("code",f);

  function f(...args) 
  {
    return args.join( env.params.separator || ",");
  }
}
*/

export function i_mul( env ) {
  env.feature("i_call_js");
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
  env.feature("i_call_js");
  env.setParam("code",f);

  function f(...args) 
  {
    console.log(...args);
  }

}

export function i_less( env ) {
  env.feature("i_call_js");
  env.setParam("code",f);

  function f(...args) 
  {
    if (args.length != 2) return false;
    return args[0] < args[1];
  }

}

export function i_more( env ) {
  env.feature("i_call_js");
  env.setParam("code",f);

  function f(...args) 
  {
    if (args.length != 2) return false;
    return args[0] > args[1];
  }

}



