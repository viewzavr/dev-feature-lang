// реализация функций из co23.md
// F-CO23

export function setup(vz, m) {
  vz.register_feature_set(m);
}

//////////////////////////////////////////////////

// F-JS-INLINE
// реализация n-func
// nfunc code=code positional_args=["list","of","names"] named_args1=... named_arg2=...
// см также в pegjs код js_inline 
export function n_func( env ) 
{
  //env.monitor_values
  //console.log( "n-func feature called")
  

  env.on("param_changed",(pn,pv) => {
  	if (pn == "output") return;
  	//console.log("param-changed:",pn,pv)
  	prepare()
  })

  prepare()

  function prepare() {
  	//console.log("calling prepare");
  	//console.trace()
  	//let p = (env.params.positional_params || []).join(",");
  	//let func_code
  	if (!env.params.code) {
  		console.error("n-func: code is null")
  		env.setParam("output",null)
  		return
  	}

  	let arr = [];
  	let vals = [];

  	let my_params = {"output":true,"positional_args":true,"code":true}

  	let processed_h = {}
  	for (let k of env.getParamsNames()) {
  		if (my_params[k]) continue;
  		arr.push( k )
  		vals.push( env.params[k] )
  		processed_h[k] = true;
  		if (!env.hasParam(k)) return; // не присвоен? выходим
  	}
  	// ну так пока не оч красиво но зато действенно
  	for (let k of env.linksToObjectParamsNames()) {
  		if (my_params[k]) continue;
  		if (processed_h[k]) continue;
  		arr.push( k )
  		vals.push( env.params[k] )
  		if (!env.hasParam(k)) return; // не присвоен? выходим - потому что как мы будем проводить вычисление, обещая коду что данные есть, а их еще нет?
  	}

  	let code = env.params.code;
  	// короче практика показала что это какой-то вынос мозга..
  	// идея - поживем пока с явным return
  	//if (code.indexOf("return") < 0 && code.indexOf(";") < 0 && code.indexOf("if") < 0) 
  	//    code = `return (${code})`; // смело, но удобно. но видимо не исчерпает..

  	let all_args = arr.concat( env.params.positional_args || [] )
  	let f1 = (new Function( all_args, code ))
  	// console.log("f1=",code)

  	let output_f = function (...args) {
  		let all_vals = vals.concat( args )
  		let res = f1.apply( env, all_vals )
  		return res
  	}

  	env.setParam("output", output_f)
  }
}

///////////////////////////////////////////////////////////////////

/* reaction

   варианты:	
   reaction @channel func
   reaction @channel { |x| .... }   
   @channel | reaction func
   @channel | reaction { |x| .... }

   или все-таки лучше так: ?

   reaction (join-channels (event @btn "click") (event @btn "clack"))

   я думаю сейчас - лучше так. там можно разно управлять каналами будет - чтобы то ли 1 сигнал присылало, то ли что.
   в общем - значение. это удобно и гибко и всяко ортогонально.
*/   

export function reaction( env ) {
  env.setParam( "make_func_output","f")
  env.feature("make_func");

  let unsub = () => {}
  let func

  env.onvalues_any(['input',0,1],() => {
    
  	unsub(); unsub = () => {};

  	let channel
  	if (env.paramConnected("input")) {
  		if (env.hasParam("input")) {
  			channel = env.params.input;
  			func = env.params[0] || env.params.f
  		} else return
  	}
  	else {
  		if (env.hasParam(0)) {
  			channel = env.params[0]
  			func = env.params[1] || env.params.f
  		}
  		else
  			return
  	}

    if (!channel?.is_cell) {
      console.warn("reaction: input is not channel",channel)
      env.vz.console_log_diag( env )
      unsub = () => {}
      return
    }

    // особый случай - вместо функции целевой канал. по сути это аналог connect получается.
    
    if (func.is_cell) {
    	let target_cell = func;
    	func = (...args) => target_cell.set(...args)
      func.target_is_cell = true
    	//надо тогда учесть еще is_event_args
    }
    
    unsub = channel.on('assigned',(v) => {
      //console.log("cc-on passing",v)
      emit_val( v )
    })

    // возможность отреагировать и на уже записанные данные
    if (env.params.existing) emit_val( channel.get() )

  })
  env.on('remove',() => unsub())

  function emit_val( v ) {
  	  //if (!func) return

      if (v?.is_event_args && !func.target_is_cell) {
        // развернуть...
        func.apply( env, v )
      }
      else
        func.call( env, v )    
  }

}


// event, param, cmd, и прочие реализованы в comm3.js

