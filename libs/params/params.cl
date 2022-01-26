register_feature name="param_base" code=`
  env.tgt = () => {
    return env.hosted ? env.host : env.ns.parent;
  }
  env.paramname = () => {
    return env.params.name || env.ns.name;
  }
`;

register_feature name="param_combo" code=`
  env.feature("param_base");
  
  env.onvalue( "values", setup );
  env.onvalue( "value", (v) => {
    console.log("combo param value changed",v)
    env.tgt().setParam( env.paramname(),v );
    update_index(v);
  });
  var t;
  function setup() {
    var nv = env.params.value || env.params.values[0];
    let tgt = env.tgt()
    tgt.addComboValue( env.paramname(),nv,env.params.values );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      console.log("combo param value changed m2",v);
      env.setParam("value",v);
      update_index(v);
    });
    if (!env.params.value) env.setParam("value",nv);
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
  env.onvalue( "value", (v) => {
    env.tgt().setParam( env.paramname(),v)
  });
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
  env.onvalue( "value", (v) => {
    env.tgt().setParam( env.ns.name,v );
  });
  var t;
  function setup() {
    let tgt = env.tgt();
    tgt.addCheckbox( env.paramname(), env.params.value );
    if (t) t();
    t = tgt.trackParam( env.ns.name,(v) => {
      env.setParam("value",v);
    });
  }
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

register_feature name="param_file" code=`
  env.feature("param_base"); 
  var t;
  env.onvalue( "value", (v) => {
    //debugger;
    //console.log("file_param value changed",v)
    env.tgt().setParam( env.ns.name,v) 
  });
  function setup() {
    let tgt = env.tgt();
    tgt.addFile( env.paramname(),env.params.value );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      env.setParam("value",v);
    });
  }
  setup();
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
  setup();
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

register_feature name="param_float" code=`
  env.feature("param_base"); 
  var t;
  env.onvalue( "value", (v) => {
    env.tgt().setParam( env.ns.name,v) 
  });
  function setup() {
    let tgt = env.tgt();
    tgt.addFloat( env.paramname(),env.params.value );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      env.setParam("value",v);
    });
  }
  setup();
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

register_feature name="param_string" code=`
  env.feature("param_base"); 
  var t;
  env.onvalue( "value", (v) => {
    env.tgt().setParam( env.ns.name,v) 
  });
  function setup() {
    let tgt = env.tgt();
    tgt.addString( env.paramname(),env.params.value );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      env.setParam("value",v);
    });
  }
  setup();
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;


register_feature name="param_cmd" code=`
  env.feature("param_base"); 
  env.feature("func");
  
  function setup() {
    let tgt = env.tgt();
    tgt.addCmd( env.paramname(),(...args) => {
       //env.callCmdByPath( env.params.cmd,...args)
       env.callCmd("apply");
    } );
  }
  setup();
  
`;
