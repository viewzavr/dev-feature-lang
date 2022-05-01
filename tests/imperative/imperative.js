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

  env.onvalues_any(["code"],() => {
     update_code();
  })  

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