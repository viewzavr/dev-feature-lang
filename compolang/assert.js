export function setup(vz, m) {
  vz.register_feature_set(m);
}

// assert "(a,b) => a>b" @alfa @beta;
export function assert( env ) {
  env.setParam('allow_undefined',true );
  env.feature("m_eval")
  env.trackParam('output',(v) => {
    if (!v) {
      console.error('assert: failed',env.params.info);
      if (env.$locinfo)
        console.log(env.$locinfo);
    }
  });

};

// some | assert_input "(a,input) => a>b" @alfa;
// решил добавлять правым аргументом, типа так естественне для ситуаций вида
// assert_input (some-assert-lambda); т.е. правило добавки аргументов - вроде как справа

export function assert_input( env ) {
  env.setParam('allow_undefined',true );
  env.feature("m_eval");
  env.trackParam('output',(v) => {
    if (!v) {
      console.error('assert: failed',env.params.info);
      if (env.$locinfo)
        console.log(env.$locinfo);
    }
  });

  // будем подавать вот так аргументы пока что допом. хотя это и смена протокола..
  
  let i = env.params.args_count;
  env.params.args_count++;

  env.trackParam('input',(v) => {
    env.setParam(i,v);
  });

};


// some-arr | map_assert_input "(a,input) => a>b" @alfa;
export function map_assert( env ) {
  env.setParam('allow_undefined',true );
  env.feature("m_apply")
  env.trackParam('input',(input) => {

  	let fn = env.params.output;
  	let counter=0;
  	for (let elem of input) {
  		fn(elem)
  		if (!v) {
	      	console.error('map_assert: failed at index ',counter,'elem',elem,env.params.info);
      		if (env.$locinfo)
        		console.log(env.$locinfo);
    	}
    	counter++;
  	}
    
  });


};