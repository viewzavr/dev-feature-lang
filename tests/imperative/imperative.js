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


    for (let i=0; i<env.params.args_count;i++)
    {
      let v = env.params[i];

      // волшебный момент
      if (v?.this_is_i_lambda) {
        
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
    if (env.params.code)
    {
      // возможность прямо код сюды вставлять
      if (typeof( env.params.code ) == 'function')
         func = env.params.code;
      else
         func = eval( env.params.code );
    }
  }

  // далее мы считаем что code - вызовет по умолчанию trailing-lambda
  // и это значит что мы сможем писать вещи так:
  /* r: i-lambda { i-console @r->0 }
  */

  ///// подтоговтим функцию вычисления лямбды которая есть аргумент
  let trailing_lambda = (...args) => {
    let res;
    for (let q of env.ns.getChildren()) {

      let v = q.params.output;

      // еще один волшебный момент
      if (v?.this_is_i_lambda) {

        v = v( ...args ); // легкий отстой.
        // мы а) впихиваем аргументы блока, а это неправильно мб. 
        // б) не передаем окружение блока. хотя окружение блока технически это.. наше окружение
        // у которого лишь параметр children есть массив окружений.. хм.. 
        // ладно щас практика покажет

        // я думаю это не отстой - а возможность не передавать этих аргументов.
        // тамошние лямбды сами себе аргументы какие надо соберут..
        // см 2022-05-03-2 императивность.txt QQQ
        // а {} не является лямбдой - лямбой является все окружение.
        // таким образом здесь {} это не лямбда, а список выражений, прицепленный к текущему окружению.
        // я его даже назову - attached_block
      };

      // тут бы return проверить - не вернули ли то что надо выходить. ну ладно пока.
      res = v;
    };
    return res;
  };

  env.setParam("attached_block",trailing_lambda); // назовем как вруби пока

  // вот так вот, по умолчанию функция это будет - передача управления в блок.
  // причем без аргументом - элементы блока если им надо сами соберут аргументы
  // вот так вот странно пока
  func = (...args) => trailing_lambda();

  env.onvalues_any(["code"],() => {
     update_code();
  });


}

export function i_sum( env ) {
  env.feature("i_lambda");
  env.setParam("code",f);

  function f(...args) 
  {
    //console.log("summing",...args);
    let sum = args[0];
    for (let i=1; i<args.length; i++)
      sum = sum + args[i];
    //console.log("Returning",sum)
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

  function apply() {

    if ((env.params.args_count || 0) <= 0) return; 

    let predicate_value = const_or_call( env.params[0] );

    console.log("predicate_value=",predicate_value,"env.params=",env.params)
    if (predicate_value) {
      return const_or_call( env.params[1] )
    }
    else
    {
      return const_or_call( env.params[2] )
    }
  }
  apply.this_is_i_lambda = true;

}