register_feature name="combo" code=`
  
  env.onvalue( "values", setup );
  env.onvalue( "value", (v) => {
    env.ns.parent.setParam( env.ns.name,v) 
  });
  var t;
  function setup() {
    var nv = env.params.value || env.params.values[0];
    env.ns.parent.addComboValue( env.ns.name,nv,env.params.values );
    if (t) t();
    t = env.ns.parent.trackParam( env.ns.name,(v) => {
      env.setParam("value",v);
    });
    if (!env.params.value) env.setParam("value",nv);
  }
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

register_feature name="slider" code=`
  env.onvalue( "min", setup );
  env.onvalue( "max", setup );
  env.onvalue( "step", setup );
  env.onvalue( "value", (v) => env.ns.parent.setParam( env.ns.name,v) );
  var t;
  function setup() {
    env.ns.parent.addSlider( env.ns.name,env.params.value, env.params.min, env.params.max, env.params.step );
    if (t) t();
    t = env.ns.parent.trackParam( env.ns.name,(v) => {
      env.setParam("value",v);
    });
  }
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

register_feature name="file_param" code=`
  var t;
  env.onvalue( "value", (v) => env.ns.parent.setParam( env.ns.name,v) );
  function setup() {
    env.ns.parent.addFile( env.ns.name,env.params.value );
    if (t) t();
    t = env.ns.parent.trackParam( env.ns.name,(v) => {
      env.setParam("value",v);
    });
  }
  setup();
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;
