register_feature name="param_base" code=`
  env.tgt = () => {
    return env.hosted ? env.host : env.ns.parent;
  }
  env.paramname = () => {
    return env.params.name || env.ns.name;
  }

  env.onvalue( "value", (v) => {
    //console.log("combo param value changed",v)
    // короче история такая. этот value меняется в т.ч. от польз ввода, получается
    // когда нам его значение присылают (см ниже trackParam)
    // и если мы вызываем просто setParam то сбиваем manual-флаг исходному
    // поэтому решено что правильно если будет такая проверка тут
    let oldv = env.tgt().getParam( env.paramname() );
    if (oldv != v) {
        env.tgt().setParam( env.paramname(),v); 
    }
    // env.tgt().setParam( env.paramname(),v );
  });

`;

register_feature name="param_combo" code=`
  env.feature("param_base");
  
  env.onvalue( "values", setup );
  env.onvalue( "value", (v) => {
    update_index(v);
  });

  var t;
  function setup() {
    var nv = env.params.value || env.params.values[0];
    let tgt = env.tgt()
    //tgt.addComboValue( env.paramname(),nv,env.params.values );

    // todo получается у нас в addComboValue тупняк - если мы даем значение
    // то сигнала никто не получит... или это логично?
    tgt.addComboValue( env.paramname(),undefined,env.params.values );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      //console.log("combo param value changed m2",v);
      env.setParam("value",v);
      update_index(v);
    });
    if (!env.params.value) {
      env.setParam("value",nv);
    }
  }
  env.on("remove",() => {
    if (t) t(); t = null;
  });

  function update_index(v) {
    if (env.params.values) {
       let ind = env.params.values.indexOf(v);
       env.setParam("index",ind);
    }
  }
`;

register_feature name="param_slider" code=`
  env.feature("param_base"); 
  env.onvalue( "min", setup );
  env.onvalue( "max", setup );
  env.onvalue( "step", setup );
  
  var t;
  function setup() {
    let tgt = env.tgt();
    tgt.addSlider( env.paramname(),env.params.value, env.params.min, env.params.max, env.params.step );
    if (t) t();
    t = tgt.trackParam( env.ns.name,(v) => {
      env.setParam("value",v);
    });
  }
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

register_feature name="param_checkbox" code=`
  env.feature("param_base"); 

  var t;
  function setup() {
    let tgt = env.tgt();
    tgt.addCheckbox( env.paramname(), env.params.value );
    if (t) t();
    t = tgt.trackParam( env.ns.name,(v) => {
      env.setParam("value",v);
    });
  }
  setTimeout( setup, 0 );  // треш конечно
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

register_feature name="param_file" code=`
  env.feature("param_base"); 
  var t;

  function setup() {
    let tgt = env.tgt();
    tgt.addFile( env.paramname(),env.params.value );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      env.setParam("value",v);
    });
  }
  //setup();
  setTimeout( setup, 0 );  // треш конечно
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

register_feature name="param_files" code=`
  env.feature("param_base"); 
  var t;
  env.onvalue( "value", (v) => {
    env.setParam("count", v.length );
    env.setParam("max", v.length-1 );
  });
  function setup() {
    let tgt = env.tgt();
    tgt.addFiles( env.paramname(),env.params.value );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      env.setParam("value",v);
    });
  }
  //setup();
  setTimeout( setup, 0 );  // треш конечно
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

register_feature name="param_label" code=`
  env.feature("param_base"); 
  var t;
  env.onvalue( "value", (v) => {
    env.tgt().setParam( env.ns.name,v) 
  });
  function setup() {
    let tgt = env.tgt();
    tgt.addLabel( env.paramname(),env.params.value );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      env.setParam("value",v);
    });
  }
  //setup();
  setTimeout( setup, 0 );  // треш конечно
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

register_feature name="param_float" code=`
  env.feature("param_base"); 
  var t;

  function setup() {
    let tgt = env.tgt();
    tgt.addFloat( env.paramname(),env.params.value );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      env.setParam("value",v);
    });
  }
  //setup();
  setTimeout( setup, 0 );  // треш конечно
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

register_feature name="param_string" code=`
  env.feature("param_base"); 
  var t;

  function setup() {
    let tgt = env.tgt();
    tgt.addString( env.paramname(),env.params.value );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      env.setParam("value",v);
    });
  }
  //setup();
  setTimeout( setup, 0 );  // треш конечно
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

register_feature name="param_text" code=`
  env.feature("param_base"); 
  var t;

  function setup() {
    let tgt = env.tgt();
    tgt.addText( env.paramname(),env.params.value );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      env.setParam("value",v);
    });
  }
  //setup();
  setTimeout( setup, 0 );  // треш конечно
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

register_feature name="param_color" code=`
  env.feature("param_base"); 
  var t;

  function setup() {
    let tgt = env.tgt();
    tgt.addColor( env.paramname(),env.params.value );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      env.setParam("value",v);
    });
  }
  //setup();
  setTimeout( setup, 0 );  // треш конечно
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

register_feature name="param_ref" code=`
  env.feature("param_base"); 
  var t;

  function setup() {
    let tgt = env.tgt();
    // todo поработать с рутом потом
    //tgt.addParamRef( env.paramname(),env.params.value,null,null, tgt.findRoot() );
    tgt.addParamRef( env.paramname(),env.params.value,null,null, null );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      env.setParam("value",v);
    });

    // криминал это все, на name зависим
    env.onvalue("crit_fn",(str) => {
     var f = eval( str );
     let tgt = env.tgt();
     tgt.setParamOption( env.paramname(), "crit_fn", f );
     tgt.callCmd("rescan-"+env.paramname());
    })
  }
  //setup();
  setTimeout( setup, 0 );  // треш конечно
  env.on("remove",() => {
    if (t) t(); t = null;
  });

`;

// todo
register_feature name="param_objref" code=`
  env.feature("param_base"); 
  var t;

  function setup() {
    let tgt = env.tgt();
    // todo поработать с рутом потом
    tgt.addObjRef( env.paramname(),env.params.value,null,null, tgt.findRoot() );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      env.setParam("value",v);
    });

    // криминал это все, на name зависим
    env.onvalue("crit_fn",(str) => {
     var f = eval( str );
     let tgt = env.tgt();
     tgt.setParamOption( env.paramname(), "crit_fn", f );
     tgt.callCmd("rescan-"+env.paramname());
    })
  }
  //setup();
  setTimeout( setup, 0 );  // треш конечно
  env.on("remove",() => {
    if (t) t(); t = null;
  });

`;

register_feature name="param_editablecombo" code=`
  env.feature("param_base"); 
  var t;

  env.onvalue( "values", (v) => {
    env.tgt().setParamOption( env.paramname(),"values",v) 
  });
  function setup() {
    let tgt = env.tgt();
    tgt.addEditableCombo( env.paramname(),env.params.value );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      env.setParam("value",v );
    });
  }
  //setup();
  setTimeout( setup, 0 );  // треш конечно
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;


register_feature name="param_cmd" code=`
  env.feature("param_base"); 
  env.feature("func");
  
  function setup() {
    //console.log("=================== param_cmd name=",env.paramname())
    let tgt = env.tgt();
    tgt.addCmd( env.paramname(),(...args) => {
       //env.callCmdByPath( env.params.cmd,...args)
       env.callCmd("apply");
    } );
  }

  setTimeout( setup, 0 );  // треш конечно
  //setup();
  
`;
