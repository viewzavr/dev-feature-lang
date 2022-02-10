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
  for (let pv of (Object.values(parsed.params) || [])) {
     if (Array.isArray(pv) && pv[0].this_is_env) {
        for (let penv of pv)
           parsed2dump( vz, penv, base_url );
     }
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
  env.feature("dbg_skip");

  env.feature("simple-lang");
  //env.parsed_alive = false;
  //env.finalize_parse = () => { current_parent = parents_stack.pop() };

  env.addString("files");

  env.trackParam("files",(files) => {
    //console.log("load: gonna load files",files)
    if (!files) return;
    files.split(/\s+/).map( loadfile )
  });

  env.signalParam("files");

  function loadfile(file) {
     if (!file) return;

     if (file.endsWith( ".js")) {
       var file2 = env.compute_path( file );
       //console.log("loading package",file,"=>",file2);
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
     //console.log("load: loading",file)
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
  let pipe_is_generating_links;
  // var delayed = require("delayed");
  env.feature("delayed");
  var delayed_chain_children = env.delayed(chain_children)
  env.on('appendChild',(c) => {
    //console.log("pipe see appendChild",c.getPath())
    // ВАЖНО эта штука вызывается когда мы создаем ссылки
    // и нас спасает только то что delayed не дает ходу, пока сам работает
    // если мы изменим это поведение delayed то тут будет вечный цикл
    // mb стоит допом вручную проверять

    if (pipe_is_generating_links) return;

    delayed_chain_children()
  });
  //delayed_chain_children(); // тырнем разик вручную
  
  // микрофича - передать команду apply первому ребенку
  env.addCmd("apply",(...args) => {
    let firct_child = env.ns.children[0];
    if (firct_child)
      firct_child.callCmd("apply",...args);
  });

  let created_links = [];

  function chain_children() {
      pipe_is_generating_links = true;

      //console.log("chain_children: pipe ",env.getPath())
      let cprev;
      let cfirst;
      created_links.forEach( (l) => l.remove() );
      created_links = [];
      // а почему бы мне не создать особый tree для ссылок да и все?
      
      for (let c of env.ns.getChildren()) {
         //console.log("chain_children: child ",c.getPath()) 
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
          created_links.push( env.linkParam("output",`${cprev.ns.name}->output`) );
      else
          created_links.push( env.linkParam("output",``) );
      // input первого ставим на инпут пайпы

      if (cfirst) {
          //if (!cfirst.hasLinksToParam("input") && !cfirst.hasParam("input"))
          // заменяем наличие параметра на наличие непустого значения параметра
          if (!cfirst.hasLinksToParam("input") && !cfirst.getParam("input"))
            created_links.push( cfirst.linkParam("input",`..->input`) );
      }

      pipe_is_generating_links = false;
   }
}

// регистрирует фичу name, code где code это код тела функции на яваскрипте
// фишка - если у reg feat в детях дано несколько тел, применяются все.
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
      
      compalang_part = (tenv) => {

        for (let cname of Object.keys( children )) {
          var edump = children[cname];
          edump.keepExistingChildren = true; // смехопанорама
          // но иначе применение фичи может затереть созданное другими фичами или внешним клиентом
          edump.keepExistingParams = true;
          tenv.restoreFromDump( edump );  

          // делаем идентификатор для корня фичи F-FEAT-ROOT-NAME
          // todo тут надо scope env делать и детям назначать, или вроде того
          // но пока обойдемся так
          tenv.$env_extra_names ||= {};
          tenv.$env_extra_names[ cname ] = true;
         }; 
            
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
   env.setParamOption("target","is_outgoing",true);

   env.addObjectRef("object","");

   env.addCmd( "apply",() => {
      //console.log("called setter apply. value=",env.params.value);

      if (env.params.target) {
        var arr = env.params.target.split("->");
        var tobj = env.findByPath( arr[0] );
        if (tobj) {
          tobj.setParam( arr[1], env.params.value, env.params.manual );
        } else console.log("setter: target obj not found",arr);
      }
      else
      if (env.params.object) {
        env.params.object.setParam( env.params.name || env.params.param, env.params.value, env.params.manual );
      }
      else
      if (env.params.name) {
        env.host.setParam( env.params.name, env.params.value, env.params.manual );
      }
      //else console.log("setter: has no target defined",env.getPath());
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

   //console.log( "feature_func: installing apply cmd",env.getPath());
   env.addCmd( "apply",(...args) => {
      if (env.removed) return;

      if (env.params.code) {
        // кстати идея - а что если там сигнатуру подают то ее использовать?
        // т.е. если cmd="(obj,coef) => { ..... }"
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


// вариант: вызывает содержимое после задержки
// сейчас: модификатор для функций, задерживает их выполнение (и собирает несколько запросов в 1 пачку)
export function delay_execution( env ) {
  env.feature("delayed");

  function setup() {
    //console.log("delay_execution: setting up on",env.host.apply)
    if (env.host?.apply?.delay_execution_installed)
      return;
    env.host.apply = env.delayed( env.host.apply );
    env.host.apply.delay_execution_installed=true;
  }
  if (env.host.apply)
      setup();
  env.host.on("gui-changed-apply",setup );
  //console.log("delay_execution: hooked into ",env.host.getPath())
  //env.host.onvalue("apply",setup);
}

// вызывает команду name у объекта target
export function call_cmd( env )
{
  env.addObjectRef("target");

   env.addCmd( "apply",(...args) => {
      debugger;

      if (!env.params.target) {
        console.error("call_cmd: target not specified", env.getPath());
        return;
      }
      if (!env.params.name) {
        console.error("call_cmd: name not specified", env.getPath());
        return;
      }

      env.params.target.callCmd( env.params.name, ...args );

   } )
}

// вызывает функцию или команду name у объекта target
export function call( env )
{
  env.addObjectRef("target");

   env.addCmd( "apply",(...args) => {

      if (!env.params.target) {
        console.error("call: target not specified", env.getPath());
        return;
      }
      if (!env.params.name) {
        console.error("call: name not specified", env.getPath());
        return;
      }

      let to = env.params.target;
      let nam = env.params.name;

      if (to.hasCmd( nam ))
        to.callCmd( nam, ...args );
      else if (typeof( to[nam] ) == "function")
        to[nam].call( undefined, ...args );
      else
        console.error("call: target has no input thing named",nam,target.getPath());
      // вообще идея что можно было бы еще вызвать событие

      // и еще что прием такой вещи можно было бы завернуть в сам объект
      // и тогда у него уже обработчик сам решает, что же это и что с ним делать
      // т.е. может быть это ввернуть на стороную вьюзавра
      // и вообще единой функцией с аргументом-именем. и тогда объект сам будет решать
      // как он готов реагировать. хотя может быть и ценно будет все-таки знать
      // что там ничего такого не принимают..

      // ну и еще можно свести.. call target=... command=... func=... event=....;
      // в общем тут нужен некий дизайн, понять что это и почему и зачем
      // кстати в qml - там есть а) явная регистрация событий, б) и эта регистрация формирует
      // "команду", которую можно даже вызывать.

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
    if (obj.getParamOption(name,"isoutput")) return;

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
// и еще у нас есть param_cmd.. @todo выбрать одно
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
        console.error("callCmdByPath: cmd arr length is not 2! target_path=",target_path );
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
export function repeater0( env, fopts, envopts ) {
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
      if (pending_perform) {
        if (env.params.input)
          env.signalParam("input");
        else
          env.signalParam("model");
      }
    }
    return Promise.resolve("success");
  }


  var created_envs = [];
  function close_envs() {
     for (let old_env of created_envs) {
       old_env.remove();
     }
     created_envs = [];
  }
  env.on("remove",close_envs)

  var pending_perform;
  env.onvalue("model",recreate );
  env.onvalue("input",recreate );

  env.addCmd("refresh",() => recreate());


  function recreate() {
     let model = env.params.model || env.params.input;
     
     close_envs();

     if (env.removed) return; // бывает...

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

     if (typeof model == 'number') { // число
       let num = parseInt( model ); // приведем к инту
       model = Array.from(Array(num).keys());
     }

     if (model && !model.forEach) // рарешим подавать любой объект на вход - это как массив 1 штука элементов
         model = [model];

     if (!(model && model.forEach)) {
       //console.error("repeater: passed model is not iterable.",model,env.getPath())
       return;
     }


     let target_parent = env.ns.parent;
     // особый случай - когда репитер сидит в пайпе
     if (target_parent.is_feature_applied("pipe"))
        target_parent = target_parent.ns.parent;

     //let parr = []; // todo
     model.forEach( (element,eindex) => {
       var edump = children[firstc];
       edump.keepExistingChildren = true; // но это надо и вложенным дитям бы сказать..

       var p = env.vz.createSyncFromDump( edump,null,target_parent );
       //parr.push( p );

       //Promise.all(para).then( )

       p.then( (child_env) => {
          // делаем идентификатор для корня фичи F-FEAT-ROOT-NAME
          // todo тут надо scope env делать и детям назначать, или вроде того
          // но пока обойдемся так
          child_env.$env_extra_names ||= {};
          child_env.$env_extra_names[ firstc ] = true;

          // todo epochs
          child_env.setParam("input",element);
          child_env.setParam("inputIndex",eindex);

          child_env.setParam("modelData",element);
          child_env.setParam("modelIndex",eindex);

          created_envs.push( child_env );

          // выдаем в output созданные объекты
          if (created_envs.length == model.length)
             env.setParam( "output", created_envs );
       });
      
       /*
       var child_env = env.vz.createSyncFromDump( edump,null,env.ns.parent );
          // todo epochs
          child_env.setParam("modelData",element);
          child_env.setParam("modelIndex",eindex);

          created_envs.push( child_env );
       */
     });
  } // recreate
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
      if (pending_perform) {
        if (env.params.input)
          env.signalParam("input");
        else
          env.signalParam("model");
      }
    }
    return Promise.resolve("success");
  }


  var pending_perform;
  env.onvalue("model",recreate );
  env.onvalue("input",recreate );

  env.addCmd("refresh",() => recreate());


  let current_state = [];
  let model;

  function recreate() {
     model = env.params.model || env.params.input;

     if (env.removed) return; // бывает...

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

     if (typeof model == 'number') { // число
       let num = parseInt( model ); // приведем к инту
       model = Array.from(Array(num).keys());
     }

     if (model && !model.forEach) // рарешим подавать любой объект на вход - это как массив 1 штука элементов
         model = [model];

     if (!(model && model.forEach)) {
       //console.error("repeater: passed model is not iterable.",model,env.getPath())
       return;
     }

     let target_parent = env.ns.parent;
     // особый случай - когда репитер сидит в пайпе
     if (target_parent.is_feature_applied("pipe"))
        target_parent = target_parent.ns.parent;


     //////////// вот здесь момент создания.
     // и вопрос - надо добавить или убавить. именно на этот вопрос надо отвечать.
    
     // у нас есть уже состояние - что то создано, на что то поданы заявки
     // и нам надо сообразно актуализироваться в связи с вновь поступившим заказом.
     // created_envs - список созданных окружений. некоторые могут быть еще не созданы а запущены на создание.
     if (model.length < current_state.length) {
       // надо удалять
       decrease_state_to(model.length);
       // и освежить тех кто остался
       actualize_state_to_model();
     }
     else {
       actualize_state_to_model();
       
       // надо добавить
       for (let i=current_state.length; i<model.length; i++) {

           var edump = children[firstc];
           edump.keepExistingChildren = true; // но это надо и вложенным дитям бы сказать..

           var p = env.vz.createSyncFromDump( edump,null,target_parent );
           current_state.push( {promise: p} );

           p.then( (child_env) => {
              if (p.need_cancel) {
                child_env.remove();
                return;
              }
              current_state[i].child_env = child_env;

              // делаем идентификатор для корня фичи F-FEAT-ROOT-NAME
              // todo тут надо scope env делать и детям назначать, или вроде того
              // но пока обойдемся так
              child_env.$env_extra_names ||= {};
              child_env.$env_extra_names[ firstc ] = true;

              // todo epochs
              // поскольку тут по индексу, а model глобальная - мы получаем свежее значение
              /// даже если промис сработал после многократного перезапуска

              let element = model[i];
              child_env.setParam("input",element);
              child_env.setParam("inputIndex",i);

              child_env.setParam("modelData",element);
              child_env.setParam("modelIndex",i);

              /*  
              created_envs.push( child_env );
              // выдаем в output созданные объекты
              if (created_envs.length == model.length)
                 env.setParam( "output", created_envs );
              */   
           });        
       }
     }

     let envs_promises  = current_state.map( s => s.promise );
     Promise.all( envs_promises ).then( (envs) => {
        env.setParam( "output", envs );
     })
     
  } // recreate

  function decrease_state_to(num) {
      for (let i=current_state.length-1; i>=num; i--) {
           let rec = current_state.pop();
           let child_env = rec.child_env;
           if (child_env) {
             child_env.remove();
           }
           else rec.promise.need_cancel=true;
       }
  }

  function actualize_state_to_model() {
    // актуализируем у уже созданных
       for (let i=0; i<current_state.length; i++) {
          let child_env = current_state[i].child_env;
          if (!child_env) continue;

              let element = model[i];
              child_env.setParam("input",element);
              child_env.setParam("modelData",element);
       }
  }

  env.on('remove',() => decrease_state_to(0));
}

////////////////////////////
export function compute( env ) {
  env.setParam("output",undefined);
  env.setParamOption("output","internal",true);

  var imsetting_params_maybe;
  function evl() {
    if (env.removed)
        return;

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

  env.on('param_changed', (name) => {
    if (name == "output") return;
    if (env.getParamOption(name,"isoutput")) return;

    // тут засада великая... если compute внутри себя откладывает вычисления по таймеру
    // и пишет куда ни попадя - мы вызываем пересчет получается этим
    // все-таки нужны получается флаги типа output... а то все смешно - compute по отложенному таймеру
    // записал результаты и - пошел считаться заново..

    if (!imsetting_params_maybe) {
       //console.log('compute: params ',name,' changed, scheduling re-compute. val=',env.getParam(name),"\npath=",env.getPath() );
       eval_delayed()
     }
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
    else
      console.log("compute_output: code not specified",env.getPath())
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

/* пример:
     connection event_name="moving" {
       func code=`console.log(123)`;
     }
*/
export function connection( env, options )
{
   env.feature("func"); // см выше

   env.addObjRef("object");

   var tracking = () => {};
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

   // такое вот.. как в dom-event

   if (!env.params.object) {
      if (env.hosted) // мы хостируимси - тогда object это хост
        env.setParam("object",env.host);
      else {
        env.setParam("object","..");
      }
   }
   
}

export function mapping( env, options )
{
  env.onvalues(["index","input"],(values,input) => {
    var v = values[input];
    //var v = input[index];
    env.setParam("output",v);
  });
  env.addString("input");
}

export function console_log_params( env, options )
{
  env.host.on("param_changed",(n,v) => {
    console.log( "console_log_params:",env.params.text || "", env.host.getPath(), "->",n,":",v )
  });
}

export function console_log( env, options )
{
  function print() {
    console.log( env.params.text, env.params.input );
  }
  env.onvalue("text",print);
  env.onvalue("input",(input) => {
    print();
    env.setParam("output",input); // доп-фича - консоле-лог пропускает дальше данные
  });
  
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

// очень похоже на connection
// name - имя события которое мониторить
// далее работает как функция
export function onevent( env  )
{
  env.feature("func");
  var u1 = () => {};
  env.onvalue( "name", (name) => {
    u1();
    u1 = env.host.on( env.params.name ,(...args) => {
      env.callCmd("apply",...args);
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
     if (!edump) return;

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

// действует как deploy_many но по команде apply
// вход - input, массив описаний
export function creator( env )
{

  env.addCmd("apply",() => {
     let input = env.params.input; // можно будет на чилдрен переделать но пока так
     if (!input) {
       console.error("creator: got command but input is blank;");
       return;
     }
     let target = env.params.target; // можно будет на чилдрен переделать но пока так
     if (!target) {
       console.error("creator: got command but target is blank;");
       return;
     }
     deploy_normal_env_all(input, target);
  })

  function deploy_normal_env_all(input,target) {
      for (let edump of input) {
        edump.keepExistingChildren = true; // но это надо и вложенным дитям бы сказать..
        //edump.manual = env.params.manual;
        //посчитал неправильным здесь это обрабатывать

        var p = env.vz.createSyncFromDump( edump,null,target );

        p.then( (obj) => env.emit("created",obj) );
     }
 }

}

// создает все объекты из поданного массива описаний
// подключая их к родителю узла deploy_many
// тут кстати напрашивается сделать case - фильтрацию массива... ну и if через это попробовать сделать например...
// вариантов много получается...
// update - вроде как get достаточно в этом случае?
// выдает сигналы before_deploy( old_envs ) и after_deploy( new_envs )
export function deploy_many( env, opts )
{
  
  env.onvalue("input",(input) => {
     deploy_normal_env_all(input);
  });

  env.addCmd("redeploy",() => {
    //console.log("redeploy called",env.getPath())
    deploy_normal_env_all( env.params.input );
  });

 // режим "repeater-mode" - развернуть всех в родителя (хотя может и можно не в родителя)
 var created_envs = [];
 function close_envs() {
     for (let old_env of created_envs) {
       old_env.remove();
     }
     created_envs = [];
 }
     
 function deploy_normal_env_all(input) {
     env.emit("before_deploy", created_envs);
     close_envs();
     let parr=[];
     if (input && !Array.isArray(input)) input=[input]; // так
     if (!input) {
       env.setParam("output",[]);
       return;
     }

     for (let edump of input) {
        edump.keepExistingChildren = true; // но это надо и вложенным дитям бы сказать..
        var p = env.vz.createSyncFromDump( edump,null,env.ns.parent, edump.$name );
        p.then( (child_env) => {
           created_envs.push( child_env );
        });
        parr.push(p);
     }
     Promise.all(parr).then( (values) => {
       env.emit("after_deploy",values);
       // и еще такая шутка а там видно будет
       env.setParam("output",values);
     });
 }
 env.on("remove",close_envs)
}

// создает все объекты из поданного массива описаний
// подключая их к указанному узлу

export function deploy_many_to( env, opts )
{
  
  env.onvalues(["input","target"],(input,target) => {
     deploy_normal_env_all(input,target);
  });

 // режим "repeater-mode" - развернуть всех в родителя (хотя может и можно не в родителя)
 var created_envs = [];
 function close_envs() {
     for (let old_env of created_envs) {
       old_env.remove();
     }
     created_envs = [];
 }
     
 function deploy_normal_env_all(input,target) {
     env.emit("before_deploy", created_envs);
     close_envs();
     let parr=[];
     if (input && !Array.isArray(input)) input=[input]; // так
     if (!input) {
       env.setParam("output",[]);
       return;
     }

     for (let edump of input) {
        edump.keepExistingChildren = true; // но это надо и вложенным дитям бы сказать..
        var p = env.vz.createSyncFromDump( edump,null,target );
        p.then( (child_env) => {

           created_envs.push( child_env );
        });
        parr.push(p);
     }
     Promise.all(parr).then( (values) => {
       env.emit("after_deploy",values);
       // и еще такая шутка а там видно будет
       env.setParam("output",values);
     });
 }
 env.on("remove",close_envs)
}

//////////////////////////////////////// deploy_features
/*
  Внедряет фичи в режиме под-окружений в указанный список объектов.
  Если список объектов меняется, ситуация синхронизируется.

  input - список окружений куда внедрить
  feautures - список фич
*/

export function deploy_features( env )
{
  
  env.onvalues(["input","features"],(input,features) => {
     input ||= [];
     if (!Array.isArray(input)) input=[input]; // допускаем что не список а 1 штука
     dodeploy( input, features );

     env.setParam("output",input); // доп-фича - пропускать дальше данные
  });

  function dodeploy( objects_arr, features_list ) {
     // ну тут поомтимизировать наверное можно, но пока тупо все давайте очищать
     close_envs();
     //debugger;

     if (!features_list) return;

     if (!Array.isArray(features_list)) {
      console.error("deploy_features: features_list is not array!");

      return;
     }

     let to_deploy_to = objects_arr;

     let ii=0;
     for (let tenv of to_deploy_to) {
      for (let rec of features_list) {
        //console.log("deploy_features is deploying",rec,"to",tenv.getPath())
        let new_feature_env = env.vz.importAsParametrizedFeature( rec, tenv );
        new_feature_env.setParam( "objectIndex",ii);
        created_envs.push( new_feature_env );

        // делаем идентификатор для корня фичи F-FEAT-ROOT-NAME
        // todo тут надо scope env делать и детям назначать, или вроде того
        // но пока обойдемся так
        new_feature_env.$env_extra_names ||= {};
        new_feature_env.$env_extra_names[ new_feature_env.$feature_name ] = true;
      };
      ii++;
     };
  }

 var created_envs = [];
 function close_envs() {
   for (let old_env of created_envs) {
     old_env.remove();
   }
   created_envs = [];
 }

 env.on("remove",close_envs)

}

//////////////// get

export function get( env ) {
  let param_tracking = () => {};

  function source_param_changed (input,param) {
    let v = input?.getParam ? input.getParam( param ) : undefined;
    env.setParam("output",v );

    param_tracking();
    param_tracking = input.trackParam( param,() => {
      source_param_changed( input, param );
    } );
  }
  env.on("remove",param_tracking);

  env.onvalues(["input","param"],source_param_changed);

  ///////////////////

  env.onvalues(["input","name"],(input,param) => {
    let v = input ? input[ param ] : undefined;
    env.setParam("output",v );
  });
  env.onvalues(["input","child"],(input,param) => {
    let v = input ? input.ns.childrenTable[ param ] : undefined;
    env.setParam("output",v );
  });
  env.onvalues(["input","index"],(input,param) => {
    let v = input ? input[ param ] : undefined;
    env.setParam("output",v );
  });
  env.onvalues(["input","path"],(input,param) => {
    let arr = path.split(".");
    v = input;
    while (arr.length > 0) {
       if (!v) break;
       v = v[ arr[0] ];
       arr.shift();
    }
    env.setParam("output",v );
  });
  // идея - уметь брать сразу несколько чего-то.. и выдавать не знаю, массив..
  // ну например брать names или там еще что..
}

// такая тема - регистрирует параметры через геттеры и сеттеры окружения
export function copy_params_to_obj( env ) {
  let x = env.host;

  let orig = x.setParamWithoutEvents;

  x.setParamWithoutEvents = (name,value) => {
    orig( name,value);
    regparam_if_needed(name);
  }

  let registered_params = {};
  function regparam_if_needed( name) {
    if (registered_params[name]) return;
    registered_params[name]=true;
    regparam(name);
  }

  function regparam( name ) {
    Object.defineProperty(x, name, {
          get: function() { return x.getParam(name); },
          set: function(newValue) { x.setPAram(name,newValue); },
          enumerable: false,
    });
  }

  // теперь закачаем те что есть
  for (let q of x.getParamsNames())
    regparam_if_needed(q);

  // todo addGui по идее тоже
}

// представляет df как объект с параметрами
export function df_to_env( env ) {

  env.onvalue("input",(df) => {
    cleanup();
    if (!df.isDataFrame) {
       return;
    }
    
    env.colnames = df.colnames;

    for (let c of df.colnames)
    {
      env.setParam(c, df[c] );
    }
  })

  function cleanup() {
    env.colnames=null;
    for (let c of env.getParamsNames())
      env.removeParam(c);
  }

}

var uniq_ids = {};
export function uniq_id_generator(env) {

  let key;
  while (true) {
    key = "compalang_uniq_id_" + (Math.random() + 1).toString(36).substring(2);
    if (!uniq_ids[key]) break;
  };
  env.setParam("output",key);
}

export function get_children_arr(env) {
  let unsub=()=>{};
  env.onvalue("input",(senv) => {
    unsub();

    if (!(senv?.on)) {
      console.error("get_children_arr: strange input",senv, env.getPath());
      return;
    }

    unsub = senv.on("childrenChanged",() => {
      env.setParam("output", senv.ns.children );
    });
    env.setParam("output", senv.ns.children );
  })
  env.on("remove",() => unsub());
}