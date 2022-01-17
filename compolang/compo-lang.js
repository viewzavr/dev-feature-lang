// фича parseSimpleLang и базовые фичи языка load, loadPackage, pipe, register_feature

export function setup(vz, m) {
  vz.register_feature_set(m);
}

import * as P from "./lang-parser.js";
export function simple_lang(env) 
{
  env.parseSimpleLang = function( code, opts={} ) {
    try {
      var parsed = P.parse( code, { vz: env.vz, parent: (opts.parent || env), base_url:opts.base_url } );
      var dump = parsed2dump( env.vz, parsed, opts.base_url || "" );
      dump.keepExistingChildren = true; 
      return env.restoreFromDump( dump );
    }
    catch (e) 
    {

      console.error(e);
      
      if (typeof e.format === "function")
          console.log( e.format( [{text:code}] ));

      if (opts.diag_file) console.log("parse error in file ",opts.diag_file)  

    }
  }
  env.compalang = env.parseSimpleLang;
}

// преобразовать результат парсинга во вьюзавр-дамп
function parsed2dump( vz, parsed, base_url ) {
/* они почти похожи.
   надо обработать массив link - привести к объектам
   и пока во вьюзавре есть типы обработать type
*/
  // links
  /* я думал links запихать в объекты. но у нас функторы - они не активируют детей напрямую.
     поэтому links на этапе restore надо обрабатывать отдельно.
  for (var lname of Object.keys(parsed.links)) {
    var lrec = parsed.links[lname];
    var newlinkobj = { type: "link", params: {...lrec.params,tied_to_parent: true} }
    while (parsed.children[ lname ]) lname=lname+"y";
    parsed.children[ lname ] = newlinkobj;
  }
  */
  // type
  if (Object.keys( parsed.features ).length > 0) {
    var first_feature_name = Object.keys( parsed.features )[0];
    var first_feature_code = first_feature_name;
    //var first_feature = parsed.features[  ]
    if (vz.getTypeInfo(first_feature_code))
      parsed.type = first_feature_code;
  }
  for (let c of Object.keys(parsed.children)) {
    let cc = parsed.children[c];
    parsed2dump( vz, cc, base_url );
  }
  for (let cc of (parsed.features_list || [])) {
    parsed2dump( vz, cc, base_url );
  }
  parsed.forcecreate = true;
  parsed.features[ "base_url_tracing" ] = {params: {base_url}};
  //feature("base_url_tracing",{base_url});
  return parsed;
}

var compolang_modules = {};
// короче решено все делать через load и пусть она разбирается что там.
// а то уже взрыв мозга, что загружать, package или combolang.
export function load(env,opts) 
{
  env.feature("simple-lang");
  //env.parsed_alive = false;
  //env.finalize_parse = () => { current_parent = parents_stack.pop() };

  env.addString("files");

  env.trackParam("files",(files) => {
    console.log("load: gonna load files",files)
    if (!files) return;
    files.split(/\s+/).map( loadfile )
  });

  env.signalParam("files");

  function loadfile(file) {
     if (!file) return;

     if (file.endsWith( ".js")) {
       var file2 = env.compute_path( file );
       console.log("loading package",file,"=>",file2);
       return vzPlayer.loadPackage( file2 )
     }
     if (vzPlayer.getPackageByCode(file)) {
       return vzPlayer.loadPackage( file )
     }     

     if (compolang_modules[file])
      file = compolang_modules[file];
     else
      file = env.compute_path( file );

     let new_base_url = env.vz.getDir( file );
     console.log("load: loading",file)
     fetch( file ).then( (res) => res.text() ).then( (txt) => {
       // нужна sub-env для отслеживания base-url
       var subenv = env.create_obj( {} );
       subenv.feature("simple-lang");
       subenv.addLabel("source_file", file );
       //subenv.setParam("source_file", file );
       subenv.parseSimpleLang( txt, {vz: env.vz, parent: env.ns.parent,base_url: new_base_url, diag_file: file } );
       // было
       //subenv.parseSimpleLang( txt, {vz: env.vz, parent: env.ns.parent,base_url: new_base_url} );
     });
  }
}

export function register_compolang(env,opts) {
  env.onvalue("url",(url) => {
    if (!env.params.name)
    {
      console.error("COMPOLANG PACKAGE WITHOUT NAME CANNOT BE REGISTERED",code);
      return;
    }
    var code = env.params.name;
    var url = env.compute_path(url);
    compolang_modules[code] = url;
  });

  env.on("parsed",() => {
    env.remove();
  })
}

export function do_register_compolang( name,url ) 
{
  compolang_modules[code] = url;
}

export function register_compolang_func( env ) 
{
  env.register_compalang = (code,url) => {
    compolang_modules[code] = url;
  }
}

export function load_package(env,opts) 
{
  env.parsed_alive = false;
  env.trackParam("files",(files) => {
    console.log("load_package: gonna load files",files)
    if (!files) return;
    files.split(/\s+/).map( loadfile )
  })
  env.signalParam("files");

  function loadfile(file) {
    if (file.indexOf(".js") > 0) // это файл
        file = env.compute_path( file );
    // а иначе это похоже package-specifier (айди в таблице)

    console.log("load_package: loading",file);

    return vzPlayer.loadPackage( file );
  }
}

// потребность: удобный метод построения цепочек вычислений
// pipe { c1; c2; c3; }
// соединяет "детей" так: c2.input = @c1->output; c3.input = @c2->output
// открытый вопрос: куда идет output c3 ? это pipe.output = @c3->output ?
// кстати интересная идея от Кости - linestrips output это 3d object..
//import {delayed} from "viewzavr/utils.js";
export function pipe(env) 
{
  // var delayed = require("delayed");
  env.feature("delayed");
  var delayed_chain_children = env.delayed(chain_children)
  env.on('appendChild',delayed_chain_children);
  //delayed_chain_children(); // тырнем разик вручную

  let created_links = [];

  function chain_children() {
      let cprev;
      let cfirst;
      
      for (let c of env.ns.getChildren()) {
         if (c.is_link) continue;
         if (!cfirst) cfirst = c;
         // пропускаем ссылки.. вообще странное решение конечно.. сделать ссылки объектами
         // и потом об них спотыкаться
         if (cprev) {
           c.linkParam("input",`../${cprev.ns.name}->output`); // вообще странно все это
         }
         cprev = c;
      }
      // output последнего ставим как output всей цепочки
      if (cprev)
          env.linkParam("output",`${cprev.ns.name}->output`)
      else
          env.linkParam("output",``)
      // input первого ставим на инпут пайпы
      if (cfirst) {
          if (!cfirst.hasLinksToParam("input") && !cfirst.hasParam("input"))
            cfirst.linkParam("input",`..->input`)
      }
  }
}

// регистрирует фичу name, code где code это код тела функции на яваскрипте
export function register_feature( env, envopts ) {
  var children = {};
  env.restoreFromDump = (dump,manualParamsMode) => {
    env.vz.restoreParams( dump, env,manualParamsMode );
    env.vz.restoreLinks( dump, env,manualParamsMode );
    env.vz.restoreFeatures( dump, env,manualParamsMode );

    children = dump.children;
    compile();
    return Promise.resolve("success");
  }
  
  var apply_feature = () => {};

  env.addLabel("name");

/*
  env.onvalue("name",() => {
    env.vz.register_feature( env.params.name, (e,...args) => {
      apply_feature(e,...args)
    } );
  });
*/  

  function compile() {
    if (!env.params.name) {
      console.error("RESIGTER-FEATURE: feature have no name.")
      return;
    }

    var js_part = () => {};
    if (env.params.code) {
      var code = "(env,args) => { " + env.params.code + "}";
      try {
        js_part = eval( code );
      } catch(err) {
        console.error("REGISTER-FEATURE: error while compiling js!",err,"\n********* code=",code);
      }
    }
    var compalang_part = () => {};
    if (Object.keys( children ).length > 0) {
      var firstc = Object.keys( children )[0];
      compalang_part = (tenv) => {
        var edump = children[firstc];
        edump.keepExistingChildren = true; // смехопанорама
        // но иначе применение фичи может затереть созданное другими фичами или внешним клиентом
        edump.keepExistingParams = true;
        tenv.restoreFromDump( edump );  

        // делаем идентификатор для корня фичи F-FEAT-ROOT-NAME
        // todo тут надо scope env делать и детям назначать, или вроде того
        // но пока обойдемся так
        tenv.$env_extra_names ||= {};
        tenv.$env_extra_names[ firstc ] = true;
            
        //tenv.vz.createChildrenByDump( dump, obj, manualParamsMode );
      }
    }

    apply_feature = (e,...args) => {
      js_part( e,...args);
      compalang_part( e,...args);
    }

    env.vz.register_feature( env.params.name, (e,...args) => {
      apply_feature(e,...args)
    } );
  }

  //env.onvalue("code",compile );

  env.on("parsed",() => {
    env.remove();
  })
}



// регистрирует пакет name,url
export function register_package( env ) {
  env.onvalue("url",(url) => {
    if (!env.params.name)
    {
      console.error("PACKAGE WITHOUT NAME CANNOT BE REGISTERED",code);
      return;
    }
    var code = env.params.name;
    var url = env.compute_path(url);
    vzPlayer.addPackage( {code,url});
  });

  env.on("parsed",() => {
    env.remove();
  })
}

//////////////////////

function add_dir_if( path, dir ) {
  if (path[0] == "/") return path;
  if (path.match(/\w+\:\/\//)) return path;
  if (path[0] == "." && path[1] == "/") path = path.substring( 2 );
  if (path.trim() == "") return null; // if blank path specified, that means no data should be displayed. F-BLANK
  return dir + path;
}

export function base_url_tracing( env, opts ) 
{
  env.$base_url = opts.base_url;
  env.compute_path = (file) => {
    //if (Array.isArray(file))
    if (typeof(file) === "string")
      return add_dir_if( file, env.$base_url );
      //return add_dir_if( file, opts.base_url );
    return file;
  }
}

//////////////////////////////////////////
// устанавливает параметр при вызове команды apply
// * value - значение которое устанавливать
// * target - полная ссылка на цель (объект->параметр)
//   либо
//   * пара object="some-path" и param="..."
//   либо
//   * имя name и тогда будет выставлено значение параметру объекта host
export function setter( env )
{
   env.addParamRef("target","");
   env.addObjectRef("object","");

   env.addCmd( "apply",() => {
      if (env.params.target) {
        var arr = env.params.target.split("->");
        var tobj = env.findByPath( arr[0] );
        if (tobj) {
          tobj.setParam( arr[1], env.params.value, env.params.manual );
        } else console.log("setter: target obj not found",arr);
      }
      else
      if (env.params.object) {
        env.params.object.setParam( env.params.param, env.params.value, env.params.manual );
      }
      else
      if (env.params.name) {
        env.host.setParam( env.params.name, env.params.value, env.params.manual );
      }
      else
        console.log("setter: has no target defined");
   } );
}

// отличается от setter тем что сразу же делает
// по сути это то же самое что compute.. только на вход не код а value..
export function set_param( env, opts )
{
   env.feature("setter");
   env.callCmd("apply");
   env.onvalues_any(["target","object","param","name","value","manual"], () => {
       
       env.callCmd("apply");      
   })
}


/*
export function setter( obj, options )
{
   obj.addParamRef("target","");
   obj.addObjectRef("object","");

   obj.addCmd( "apply",() => {


      if (obj.params.target) {
        var arr = obj.params.target.split("->");
        var tobj = obj.findByPath( arr[0] );
        if (tobj) {
          tobj.setParam( arr[1], obj.params.value, obj.params.manual );
        } else console.log("setter: target obj not found",arr);
      }
      else
      if (obj.params.object) {
        obj.params.object.setParam( obj.params.param, obj.params.value, obj.params.manual );
      }
      else
        console.log("setter: has no target defined");
   } );

}
*/

// выполняет указанный код при вызове команды apply
// вход: cmd, code, и еще children - у них будет вызвано apply
export function feature_func( env )
{
   env.feature("call_cmd_by_path");

   env.addCmd( "apply",(...args) => {
      if (env.params.code) {
        var func = new Function( "env","args", env.params.code );
        func.call( null, env, args );
        //eval( obj.params.code );
      }
      if (env.params.cmd) {
        env.callCmdByPath(env.params.cmd,...args)
      }
      for (let c of env.ns.getChildren()) {
        c.callCmd("apply",...args);
      }
   } )
}

// автоматический вызов команды apply при изменении любых параметров
// (кстати странно - даже выходных получается)
export function auto_apply( obj ) {
  function evl() {
    obj.callCmd("apply");
  }
  obj.feature("delayed");
  var eval_delayed = obj.delayed( evl )

  obj.on('param_changed', (name) => {
    if (name == "output") return;
    if (obj.getParamOption(name,"iotype") == "output") return;
    eval_delayed();
  });
}


export function js( env )
{
  env.onvalue("code",(code) => {
     try {
       eval( code );
     }
     catch (e) 
     {
       console.error(e);
     }
  });
}

// добавляет команду в целевое окружение
// сама прикидывается func и поэтому можно прицепить code и все такое
export function add_cmd( env ) {
  
  env.feature("func");
  env.onvalue("name",(name) => {

    env.host.addCmd(name,f);

    function f() {
      env.callCmd("apply");
    }
  });
}

export function call_cmd_by_path(env) {

  env.callCmdByPath = ( target_path, ...args ) => {
      if (!target_path) return;
      if (typeof(target_path) == "function") {
        return target_path( ...args )
      }
      var arr = target_path.split("->");
      if (arr.length != 2) {
        //console.error("btn: cmd arr length not 2!",arr );
        // на самом деле можно ходить по стрелкам
        return;
      }
      var objname = arr[0];
      var paramname = arr[1];
      //var sobj = obj.findByPath( objname );
      //R-LINKS-FROM-OBJ
      var sobj = env.findByPath( objname );
      if (!sobj) {
        console.error("callCmdByPath: cmd target obj not found",objname );
        return; 
      }
      if (!sobj.hasCmd( paramname)) {
        if (typeof( sobj[paramname] ) === "function") {
          sobj[paramname].apply( sobj );
          return;
        }
        console.error("btn: cmd target obj has nor such cmd, nor function",objname,paramname );
        return; 
      }
      sobj.callCmd( paramname );
  }

}

//////////////////////////////////
export function repeater( env, fopts, envopts ) {
  var children;
  /* оказалось что env.restoreFromDump уже вызывают, 
     если repeater первый в register-feature стоит.. - то он не успел получается это переопределить
     поэтому я перешел на переопределение restoreChildrenFromDump...

  env.restoreFromDump = (dump,manualParamsMode) => {
    children = dump.children;
    env.vz.restoreParams( dump, env,manualParamsMode );
    env.vz.restoreLinks( dump, env,manualParamsMode );
    env.vz.restoreFeatures( dump, env,manualParamsMode );
    
    return Promise.resolve("success");
  }*/

  env.restoreChildrenFromDump = (dump, ismanual) => {
    // короче выяснилось, что если у нас создана фича которая основана на repeater,
    // то у этого repeater свое тело поступает в restoreChildrenFromDump
    // а затем внешнее тело, которое сообразно затирает собственное тело репитера.
    if (!children) {
      children = dump.children;
      if (pending_perform)
        env.signalParam("model");
    }
    return Promise.resolve("success");
  }

  var created_envs = [];

  var pending_perform;
  env.onvalue("model",(model) => {
     for (let old_env of created_envs) {
       old_env.remove();
     }

     if (!children) {
        pending_perform=true;
        return;
     }
     pending_perform=false;

     var firstc = Object.keys( children )[0];

     if (!firstc) {
       // children чето не приехали.. странно все это..
       console.error("repeater: children is blank during model change...");
       return;
     }

     if (!model.forEach) {
       //console.error("repeater: passed model is not iterable.",model,env.getPath())
       return;
     }

     model.forEach( (element,eindex) => {
       var edump = children[firstc];
       edump.keepExistingChildren = true; // но это надо и вложенным дитям бы сказать..

       var p = env.vz.createSyncFromDump( edump,null,env.ns.parent );
       p.then( (child_env) => {
          // todo epochs
          child_env.setParam("modelData",element);
          child_env.setParam("modelIndex",eindex);

          created_envs.push( child_env );
       });
     });
  })
}

////////////////////////////
export function compute( env ) {
  env.setParam("output",undefined);
  env.setParamOption("output","internal",true);

  var imsetting_params_maybe;
  function evl() {
    if (env.params.code) {
     var params = env.params;
     imsetting_params_maybe = true;
     try {

      let res = eval( env.params.code );

      if (env.params.param) {
        debugger;
        env.host.setParam( env.params.param,res );
      }
     } catch(err) {
      console.error("COMPUTE ERROR",err);
      console.log( env.params.code );
     } finally {
      imsetting_params_maybe=false;
     }
    }
  }

  env.feature("delayed");
  var eval_delayed = env.delayed( evl )

  env.on('param_changed', () => {
    if (!imsetting_params_maybe)
       eval_delayed()
  } );
  eval_delayed();

  env.addCmd("recompute",eval_delayed);
}


// отличается от compute тем что то что код return-ит и записывается в output
export function compute_output( env ) {
  env.setParam("output",{});
  env.setParamOption("output","internal",true);

  function evl() {
    if (env.params.code) {
     var params = env.params;
     var func = new Function('env',env.params.code)
     var res = func( env );

    //var res = eval( env.params.code );
    env.setParam("output",res);
    }
  }

  env.feature("delayed");
  var eval_delayed = env.delayed( evl )

  env.on('param_changed', (name) => {
     if (name != "output")
        eval_delayed();
   });

  env.addCmd("recompute",eval_delayed);

  eval_delayed();
}

// искалка объектов. вход строка pattern выход output набор найденных окружений.
// см criteria-finder.js
export function find_objects( env  ) {
  env.feature("find_by_criteria");

  env.addObjects( "pattern","",(objects_list) => {
    //console.log("FIND-OBJECTS-OBJ returns",objects_list)
    env.setParam("output",objects_list);
    env.setParam("found_objects_count",objects_list?.length)
  })
  env.onvalue("pattern",(v) => {
    //console.log(v);
    //debugger;
  })
  env.addString("found_objects_count");
}

// ловит события, направляет куда скажут
export function connection( env, options )
{
   env.feature("func"); // см выше

   var tracking = () => {};;
   env.onvalues(["event_name","object"],(en,obj) => {
      tracking();
      //console.log("GPN tracking name=",en,obj)
      tracking = obj.on( en, (...args) => {
         //console.log("GPN tracking DETECTED! name=",en,obj) 
         env.apply(...args); // вызов метода окружения func
      })
   })

   env.on("remove",() => {
    tracking(); tracking = ()=>{};
   })
   
}

export function mapping( env, options )
{
  env.onvalues(["values","input"],(values,input) => {
    var v = values[input];
    env.setParam("output",v);
  });
  env.addString("input");
}

export function console_log( env, options )
{
  function print() {
    console.log( env.params.text, env.params.input );
  }
  env.onvalue("text",print);
  env.onvalue("input",print);
  
  env.addString("text");
}

export function feature_debugger( env )
{
  if (env.params.msg)
    console.log( env.params.msg );

  debugger;
}

export function onremove( env )
{
  env.feature("func");
  env.host.on("remove",() => {
    env.callCmd("apply");
  })
}

export function onevent( env  )
{
  env.feature("func");
  var u1 = () => {};
  env.onvalue( "name", (name) => {
    u1();
    u1 = env.host.on( env.params.name ,() => {
      env.callCmd("apply");
    })
  })
  env.on("remove",u1);
  
}

/// if
/// вход: condition - условие (будет проверено оператором ?)
///       children - два дитя, первое если true второе false
/// сообразно if проверяет условие и создает либо первого либо второго
/// todo можно кейс еще сделать
export function feature_if( env, options )
{
  var created_envs = [];

  // засада в том что undefined нам не присылают первоначально
  var activated=false;
  env.onvalue("condition",(cond) => {
    var res = cond ? true : false;
    env.setParam("condition_result",res);
    perform( res ? 0 : 1 );
    activated=true;
  });
  if (!activated) perform( 1 );

  env.addString("condition_result");

  // далее натырено с репитера
  var children;
  env.restoreChildrenFromDump = (dump, ismanual) => {
    children = dump.children;
    if (typeof(pending_perform) !== "undefined") perform( pending_perform );
    return Promise.resolve("success");
  }

  var pending_perform;
  function perform( num ) {
     for (let old_env of created_envs) {
       old_env.remove();
     }
     created_envs=[];

     if (!children) {
       pending_perform=num;
       return;
     }
     pending_perform=undefined;

     var selected_c = Object.keys( children )[ num ];
     if (!selected_c) {
      //pending_perform
      return;
     }

     var edump = children[selected_c];
     edump.keepExistingChildren = true; // но это надо и вложенным дитям бы сказать..
     var p = env.vz.createSyncFromDump( edump,null,env.ns.parent );
     p.then( (child_env) => {
          created_envs.push( child_env );
      });
   };

}

/// template
/// вход: 
///    children - список вложенных окружений
/// выход:
///    output - дамп списка вложенных окружений

export function template( env, options )
{
  // далее натырено с репитера
  env.restoreChildrenFromDump = (dump, ismanual) => {
    
    // приведем к массиву.. вопросы конечно это вызывает, зачем нам тогда хеш, ну ладно пока..
    var arr = [];
    for (let c of Object.keys(dump.children))
       arr.push( dump.children[c] );

    //env.setParam("output", dump.children )
    env.setParam("output", arr );
     
    return Promise.resolve("success");
  }
}

// deploy 
// см F-ENVS-TO-PARAMS
// вход: input - список фич для деплоя из 1 элемента
// результат: deploy заменяется на результат
// может по другому назвать, paste?
// что делать если input меняется? отменять? как?..

// короче находясь в режиме модификатора этот деплой должен действовать по-другому
// а именно деплоить все заложенные фичи а не 1, и не в себя а в качестве своих sibling


// возможно будет стоит разделить их на 2 версии
// плюс может быть добавить ключи типа deploy_features input=... to=@someobj;
// и аналогично с deploy - там можно to по умолчанию родителя или себя поставить.
export function deploy( env )
{
  
  env.onvalue("input",(input) => {
     input ||= [];
     if (env.hosted)
        deploy_in_host_env(input);
     else
        deploy_normal_env(input);
        
  })

 let original_dump;
 function deploy_normal_env(input) {
     //console.log("DEPLOY INPUT=",input);
     let edump = input[0];
     edump.keepExistingChildren = true; // но это надо и вложенным дитям бы сказать..

     // попробуем сохранять состояние и пере-создавать его
     if (original_dump)
         env.restoreFromDump( original_dump )
    else
         original_dump = env.dump();

     //var p = env.vz.createSyncFromDump( edump,env );
     env.restoreFromDump( edump );
 }

 // todo мб стоит отслеживать списки фич.. хотя мы их еще не научились толком удалять...
 // но уже скоро научимся..
 function deploy_in_host_env(input) {
    for (let rec of input)
      env.vz.importAsParametrizedFeature( rec, env.host );
 }

}

// создает все объекты из поданного массива описаний
// подключая их к родителю
// тут кстати напрашивается сделать case - фильтрацию массива... ну и if через это попробовать сделать например...
// вариантов много получается...
export function deploy_many( env, opts )
{
  
  env.onvalue("input",(input) => {
     deploy_normal_env_all(input);
  })

 // режим "repeater-mode" - развернуть всех в родителя (хотя может и можно не в родителя)
 var created_envs = [];
 function close_envs() {
     for (let old_env of created_envs) {
       old_env.remove();
     }
     created_envs = [];
 }
     
 function deploy_normal_env_all(input) {
     close_envs();
     for (let edump of input) {
        edump.keepExistingChildren = true; // но это надо и вложенным дитям бы сказать..
        var p = env.vz.createSyncFromDump( edump,null,env.ns.parent );
        p.then( (child_env) => {
           created_envs.push( child_env );
        });
     }
 }
 env.on("remove",close_envs)
}