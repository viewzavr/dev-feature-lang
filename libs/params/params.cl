load "new-modifiers";
load "params-on-custom.cl";

feature "x-param-combo" {
  r: x-patch-r @r->name @r->titles? @r->values
  code="(name,titles,values,obj) => {
    if (name && values) {
      obj.addComboValue( name, undefined, values );
      // немного криминально
      // но я ожидаю что добавляя комбо оно таки выберет первый вариант..
      // мб в будущем ключ value добавить но тогда и всем..
      if (obj.params[name] == null)
        obj.setParam( name, values[0] );
    }
    if (name && titles)
      obj.setParamOption( name,'titles',titles);
    else
      obj.setParamOption( name,'titles',null);
  }
  ";
};

/*
feature "x-param-editable-combo" {
  r: x-patch-r @r->name @r->titles? @r->values
  code="(name,titles,values,obj) => {
    if (name && values)
      obj.addEditableCombo( name, undefined, values );
    if (name && titles) 
      obj.setParamOption( name,'titles',titles);
    else
      obj.setParamOption( name,'titles',null);
  }    
  ";
};
*/

feature "x-add-cmd" {
  //r: code=@.->0 name=@.->1;
  //мечты мечты.. но кстати зато можно порожденные объекты в output хреначить..
  // но опять же а как репитер тут сделаешь? ведь тогда апутупом будет репитер.. ну и ладно..

  r: x-patch-r @r->name @r->code
    code="(name,fn,obj) => {
      if (name) {
        obj.addCmd( name, fn, true );
      }
    }
    ";
};

// x-add-cmd "name" fn;
feature "x-add-cmd2" {
  r: 
  x-modify {

    x-patch-r2 "(name,fn,obj) => {
        if (name) {
          obj.addCmd( name, fn, true );
        }
    }
    " @r->0 @r->1;

  };
};

feature "x-param-objref" {
  r: x-patch-r @r->name @r->root
    code="(name,root, obj) => {
      if (name) {
        obj.addObjRef( name, undefined );
        if (root) {
          obj.setParamOption(name,'tree_func',() => root);
        }
      }
    }
    ";
};

feature "x-param-checkbox" {
  r: x-patch-r @r->name
    code="(name,obj) => {
      if (name) {
        obj.addCheckbox( name, undefined );
      }
    }
    ";
};


/* наша попытка работать с род. окружением
feature "x-param-checkbox" {
  r: x-modify name=@~->0 value=@~->1?
  {
    x-patch-r @r->name @r->value 
    code="(name,val,obj) => {
      if (name) {
        console.log('yyy',name,val);
        obj.addCheckbox( name, undefined );
      }
    }
    ";
  };
};

feature "x-param-checkbox" {
  r: x-patch-r @r->name {
     q: i-args;
     i-call-cmd @q->obj "addCheckbox" @r->name @r->value | i-get "remove";
  };
};
*/

feature "x-param-slider" {
  r: x-patch-r @r->name @r->min? @r->max? @r->step? @r->sliding? sliding=true
  code="(name,min,max,step,sliding, obj) => {

    if (!name) return;
    obj.addSlider( name, undefined, min, max, step );
    obj.setParamOption( name, 'sliding', sliding );
  }
  ";
};

feature "x-param-string" {
  r: x-patch-r @r->name
  code="(name,obj) => {
    
    if (!name) return;
    obj.addString( name, undefined );
  }
  ";
};

feature "x-param-text" {
  r: x-patch-r @r->name
  code="(name,obj) => {
    
    if (!name) return;
    obj.addText( name, undefined );
  }
  ";
};

feature "x-param-label" {
  r: x-patch-r @r->name
  code="(name,obj) => {
    
    if (!name) return;
    obj.addLabel( name, undefined );
  }
  ";
};

feature "x-param-file" {
  r: x-patch-r @r->name
  code="(name,obj) => {
    
    if (!name) return;
    obj.addFile( name, undefined );
  }
  ";
};

feature "x-param-files" {
  r: x-patch-r @r->name
  code="(name,obj) => {
    
    if (!name) return;
    obj.addFiles( name, undefined );
  }
  ";
};

// кстати идея мб неск параметров? x-param-float names=....;
feature "x-param-float" {
  r: x-patch-r @r->name
  code="(name,obj) => {
    
    if (!name) return;
    obj.addFloat( name, undefined );
  }
  ";
};

/*
    x-param-slider name="test" max=200;
    x-on "param_test_changed" code=`(a,b,c) => console.log('sl changed',a,b,c)`;
*/

feature "x-param-option" {
  r: x-patch-r @r->name @r->option @r->value
  code="(name,option,val,obj) => {
    if (name && option && obj)
      obj.setParamOption( name, option, val );
  }";
};

feature "x-param-options" {
  r: x-patch-r 
  code="(name,obj,ee) => {
    //let name = env.params[0];
    for (let k of env.getParamsNames())
      if (k != 0 && k != 'code' && k != 'output' && k != 'apply' && k != "args_count")
         obj.setParamOption( name, k, env.params[k] );
  }";
};

feature "get-param-option" code=`
  function pass_option( obj, paramname, optionname ) {
    let v = obj.getParamOption( paramname, optionname );
    env.setParam('output',v);
  }

  let unsub = () => {};
  env.onvalues([0,1,2],(obj,paramname,optionname) => {
     unsub();
     pass_option(obj,paramname,optionname);
     unsub = env.trackParamOption( paramname, optionname,() => {
        pass_option(obj,paramname,optionname);
     });
  });

  env.on("remove",unsub);
`;

//////////////////////////////////////////////////////////

// набор модификаторов по добавлению информации о гуи параметров в объект

register_feature name="param_base" code=`
  env.feature("delayed");

  env.tgt = () => {
    return env.hosted ? env.host : env.ns.parent;
  }
  env.paramname = () => {
    return env.params.name || env.ns.name;
  }

  env.onvalue( "value", (v) => {
    // console.log("combo param value changed",v)
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
  env.onvalue( "titles", setup );
  
  env.onvalue( "value", (v) => {
    update_index(v);
  });

  env.onvalue("index",(i) => {
    let v = (env.params.values || [])[i];
    if (typeof(v) != 'undefined')
        env.setParam("value",v);
  });

  var t;
  function setup() {
    
    let tgt = env.tgt()

    var nv = tgt.getParam( env.paramname() ) || env.params.value || ((env.params.values || []) [ env.params.index ]);
    //tgt.addComboValue( env.paramname(),nv,env.params.values );

    if (env.params.titles) 
      tgt.setParamOption( env.paramname(),"titles",env.params.titles);
    else
      tgt.setParamOption( env.paramname(),"titles",null);
    // делаем это перед addComboValue потому что там будет событие gui changed      

    // todo получается у нас в addComboValue тупняк - если мы даем значение
    // то сигнала никто не получит... или это логично?

    //console.log("param_combo: calling add-combo-value, vals=",env.params.values)

    tgt.addComboValue( env.paramname(),undefined,env.params.values || [] );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      //console.log("combo param value changed m2",v);
      env.setParam("value",v);
      //update_index(v);
    });
    if (typeof(env.params.value) == "undefined" && typeof(nv) != "undefined") {
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
  var installed_gui;
  function setup() {
    let tgt = env.tgt(); 

    // это не помогает - мы то в имя колонки выставляем,то в item_NNN...
    if (installed_gui == env.paramname()) return; // это потому что мы на имя реагируем

    if (installed_gui) tgt.removeGui( installed_gui );
    installed_gui = env.paramname();
    
    tgt.addCheckbox( env.paramname(), env.params.value );
    if (t) t();
    t = tgt.trackParam( env.ns.name,(v) => {
      env.setParam("value",v);
    });
  }
  env.onvalue("name",setup);

  // хак треша
  if (!env.paramname().startsWith("item"))
      env.delayed( setup )();  // треш конечно

  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

register_feature name="param_file" code=`
  env.feature("param_base"); 
  var t;

  //console.log("param_file: init",env.getPath());
  function setup() {

    let tgt = env.tgt();
    //console.log("param_file: setting up",env.getPath(),tgt);
    tgt.addFile( env.paramname(),env.params.value );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      env.setParam("value",v);
    });
  }
  //setup();
  
  env.delayed( setup )();  // треш конечно
  
  env.on("remove",() => {
    //console.log("param_file: removed",env.getPath());
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
  env.delayed( setup )();  // треш конечно
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

register_feature name="param_label" code=`
  env.feature("param_base"); 
  var t;

  env.createLinkTo( {param:"value",from:"~->0",soft:true });

  env.onvalue( "value", (v) => {
    env.tgt().setParam( env.ns.name,v ) 
  });

  function setup() {
    let tgt = env.tgt();
    if (env.removed) return; // явно лучше сделаем этот случай
    if (!tgt) return; // бывало что removed

    tgt.addLabel( env.paramname(),env.params.value );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      env.setParam("value",v);
    });
  }
  //setup();
  env.delayed( setup )();  // треш конечно
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
  env.delayed( setup )();  // треш конечно
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

/* вроде как пока лейбелом обходимся
register_feature name="param_status" code=`
  env.feature("param_base"); 
  var t;

  function setup() {
    let tgt = env.tgt();
    tgt.addStatus( env.paramname(),env.params.value );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      env.setParam("value",v);
    });
  }

  env.delayed( setup )();  // треш конечно
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;
*/

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
  env.delayed( setup )();  // треш конечно
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
  env.delayed( setup )();  // треш конечно
  env.on("remove",() => {
    if (t) t(); t = null;
  });
`;

// ссылка на параметр
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
  env.delayed( setup )();  // треш конечно
  env.on("remove",() => {
    if (t) t(); t = null;
  });

`;

// ссылка на объект
register_feature name="param_objref" code=`
  env.feature("param_base"); 
  var t;

  function setup() {
    let tgt = env.tgt();
    // todo поработать с рутом потом
    tgt.addObjRef( env.paramname(),env.params.value );
    if (t) t();
    t = tgt.trackParam( env.paramname(),(v) => {
      env.setParam("value",v);
    });

    // криминал это все, на name зависим
    env.onvalue("crit_fn",(str) => {
       var f = eval( str );
       let tgt = env.tgt();
       tgt.setParamOption( env.paramname(), "crit_fn", f );
       //tgt.callCmd("rescan-"+env.paramname());
    })
  }
  //setup();
  env.delayed( setup )();  // треш конечно
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
  env.delayed( setup )();  // треш конечно
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

  env.delayed( setup )();  // треш конечно
  //setup();
  
`;
