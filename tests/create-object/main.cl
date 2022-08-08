load "lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

feature "foo" {
  foo-param=55;
};

// создает пустой объект и кладет его в output
feature "create-blank-object" code=`
  let obj = env.vz.createObj({parent:env});
  //let obj = env.vz.createObj({parent:env.findRoot()});
  //console.log('create object',obj.$vz_unique_id);
  /*
  obj.on("remove",() => {
    debugger;
  });
  */
  //console.log("create-blank-object",env.getPath() );
  env.onvalue('target_parent',(tp) => {
    tp.ns.appendChild( obj,'item_cbo',true );
  });
  env.setParam( "output",obj);
`;

// 0 - функция фичи
feature "apply-feature" code=`
  env.onvalues(["input",0],(input,feature) => {
    let arr = input;
    if (!Array.isArray(arr)) arr=[arr];
    arr = arr.filter( e => !!e );
    for (let subobj of arr) {
      subobj.feature( feature );
    };
    env.setParam("output", input);
  });
`;

// 0 - функция фичи
feature "create-object" {
  //co: output=(create-new-object | apply-feature @co->0);
  apply-feature input=(create-blank-object);
};

let b = (create-blank-object | apply-feature "foo");
let c = (create-blank-object | apply-feature (m_lambda "(env) => { env.setParam('sigma',33) }") );
let d = (create-object (m_lambda "(env) => { env.setParam('sigma',33) }"));

let f = (create-object (make-func { |env|
  @env | x-modify {
    x-set-params sigma=33 __manual=true;
    x-js "(env) => { console.log('x-js called',env); env.setParam('hello-from-js',55); }";
  }
}  ));

let g = (create-blank-object | x-modify { x-set-params teta=55 __manual=true; });

let h = (m_eval (make-func { |teta|
  create-blank-object target_parent=@/ | x-modify { x-set-params teta=@teta __manual=true}
}) 556 allow_undefined_input=true);

///////////////////

let feat1 = (make-func { |env|
  @env | x-modify {
    x-set-params sigma=33 __manual=true;
    x-js "(env) => { console.log('hello from x-js of feat1'); env.setParam('hello-from-feat1',551); }";
  }
});

let m1 = (create-object @feat1);

let feat2 = (feature code=`env.setParam('hello-from-feat2',true)`);
let m2 = (create-object @feat2);

feat3: feature code=`env.setParam('hello-from-feat3',true)`;
m3: feat3;

/*
feat4: feature code=@feat1;
@feat4 | get-cell "applied" | c-on "(tgt_env) => console.log('feat4 applied to',tgt_env)";
*/
// вот эта часть у нас пока не сильно работает. но вроде пока особой потребности не чувствуется..
// причина - фича не поспевает за кодом. фича есть - она применяется. а потом уже код инициализируется.
feat4: feature code=@feat1 {{
  ;
  @feat4 | get-cell "applied" | c-on "(tgt_env) => console.log('feat4 applied to',tgt_env)" {{ console_log "monitoring TTT" }};
}};
m4: feat4;

feat5: feature code=(make-func { |env|
  @env | x-modify {
    x-set-params sigma=55 __manual=true;
    x-js "(env) => { console.log('hello from x-js of feat5'); env.setParam('hello-from-feat1',551); }";
  }
});

m5: feat5;


screen auto_activate {
  column {
    text "result = see dev console";
    console_log "b=" @b;
    console_log "c=" @c;
    console_log "d=" @d;
    
    console_log "f=" @f;
    console_log "g=" @g;
    console_log "h=" @h;
    
    console_log "m1=" @m1;
    console_log "m2=" @m2;
    console_log "m3=" @m3;
    console_log "m4=" @m4;
    console_log "m5=" @m5;
    
    bt: button "btn";
    //@bt | dom-event-cell "click" | c-on "() => console.log('clicked')";
    //@bt | get-cell "click" | c-on "() => console.log('clicked2')";
    @bt | get-cell "click" | c-on (make-func { create-object @feat4->output });
  };
};