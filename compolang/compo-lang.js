// фича parseSimpleLang и базовые фичи языка load, loadPackage, pipe, register_feature

import * as F from "./find-objects-by-features.js";
import * as M from "./mike.js";
import * as A from "./assert.js";
import * as C from "./csp-tricks.js";
import * as C2 from "./comm3.js";

export function setup(vz, m) {
  vz.register_feature_set(m);
  //vz.register_feature_set(F);
  F.setup( vz, F);
  M.setup( vz, M);
  A.setup( vz, A);
  C.setup( vz, C);
  C2.setup( vz, C2);

  add_compalang_to_vz(vz);
}

import * as P from "./lang-parser.js";

// создает функцию которая по строчке компаланг-кода генерирует компаланг-процессы
// и внедряет их в текущее окружение. как ни странно.
export function simple_lang(env) 
{
  env.parseSimpleLang = function( code, opts={} ) {
    try {
      var parsed = P.parse( code, 
                            { vz: env.vz, 
                              parent: (opts.parent || env), 
                              base_url: opts.base_url,
                              grammarSource: {lines: code.split('\n'), file: opts.diag_file }
                            }
                            );
      
      //console.log(code);
      //console.log("parsed",parsed);      
      var dump = parsed2dump( env.vz, parsed, opts.base_url || "" );
      //console.log("dump",dump)
      dump.keepExistingChildren = true;

      return dump;
      //let $scopeFor = env.$scopes.createScope("parseSimpleLang"); // F-SCOPE
      //return env.restoreFromDump( dump,false,$scopeFor );
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

// по строчке компаланг-процесса выдает дамп
// вход - input строка
// выход - дамп, пригодный для подачи в insert_children и т.п
export function compalang(env) 
{
  env.onvalue("input",(code) => {
    //console.log("compalang input",code)
    let opts = { base_url: env.$base_url }; // пока так
    
    try {
      var parsed = P.parse( code, 
          { vz: env.vz, 
            parent: (opts.parent || env), 
            base_url:opts.base_url,
            grammarSource: {lines: code.split('\n'), file: opts.diag_file } 
          } 
          );
      
      var dump = parsed2dump( env.vz, parsed, opts.base_url || "" );
      //dump.keepExistingChildren = true; 
      dump = Object.values(dump.children);
      // мне пока-что надо пропарсенное как массив объектов получить,
      // а текущий парсер всегда выдает item 1 штука наверху, поэтому так

      env.setParam( "output", dump );
      //console.log("parser ok")
      env.emit("computed",dump)
      env.emit("finished",dump)

    }
    catch (e) 
    {
      console.log("parser err")
      env.emit("error",e)
      env.emit("finished",e)
      console.error(e);
      
      if (typeof e.format === "function")
          console.log( e.format( [{text:code}] ));

      if (opts.diag_file) console.log("parse error in file ",opts.diag_file)  

    }

  })
}

// вход 0 - строка на компаланге.
// непозиционные параметры - пойдут в scope
// ideas: мб еще input вернуть как вход
export function compalang2(env) 
{
  env.on("param_changed",(name) => {
    if (name == "output") return;
    perform_d();
  });

  env.feature("delayed");
  let perform_d = env.delayed( perform );

  function perform() {
  let code= env.params[0];
  if (!code) {
    if (env.params.output)
        env.setParam("output",null);
    return;
  }

  //console.log("compalang input",code)
  let opts = { base_url: env.$base_url }; // пока так
    
    try {
      var parsed = P.parse( code, 
          { vz: env.vz, 
            parent: (opts.parent || env), 
            base_url:opts.base_url,
            grammarSource: {lines: code.split('\n'), file: opts.diag_file } 
          } 
          );
      
      var dump = parsed2dump( env.vz, parsed, opts.base_url || "" );
      //dump.keepExistingChildren = true; 
      dump = Object.values(dump.children);
      // мне пока-что надо пропарсенное как массив объектов получить,
      // а текущий парсер всегда выдает item 1 штука наверху, поэтому так

      // добавим параметров
      let scope = env.$scopes.createAbandonedScope("compalang2 feature");
      scope.$lexicalParentScope = env.$scopes.top();
      let scope_variables = env.params;
      
      for (let n of Object.keys( scope_variables )) {
        if (Number.isInteger(n)) continue;
        if (n.match(/^\d+$/)) continue; // todo optimize
        if (n == "output" || n == "args_count") continue;

        scope.$add( n, scope_variables[n] );
      }
      for (let e of dump)
        e.$scopeFor = scope;

      env.setParam( "output", dump );
      //console.log("parser ok")
      env.emit("computed",dump)
      env.emit("finished",dump)

    }
    catch (e) 
    {
      console.log("parser err")
      env.emit("error",e)
      env.emit("finished",e)
      console.error(e);
      
      if (typeof e.format === "function")
          console.log( e.format( [{text:code}] ));

      if (opts.diag_file) console.log("parse error in file ",opts.diag_file)  

    }

  }
}

function add_compalang_to_vz(vz) {

  vz.compalang = function( code, scope_variables={}, opts={} ) {
    try {
      //console.log(code)
      var parsed = P.parse( code, 
          { vz: vz, 
            base_url: opts.base_url,
            grammarSource: {lines: code.split('\n'), file: opts.diag_file } 
          }
          );
      
      var dump = parsed2dump( vz, parsed, opts.base_url || "" );
      dump = Object.values(dump.children);

      // теперь надо scope приделать
      let temp = vz.createObj();
      let scope = temp.$scopes.createAbandonedScope("vz.compalang");
      for (let n of Object.keys( scope_variables)) {
        scope.$add( n, scope_variables[n] );
      }
      for (let e of dump)
        e.$scopeFor = scope;
      temp.remove();

      return dump;
    }
    catch (e) 
    {
      console.log("parser err")
      console.error(e);
      
      if (typeof e.format === "function")
          console.log( e.format( [{text:code}] ));

      if (opts.diag_file) console.log("parse error in file ",opts.diag_file)

      return [];  
    }
  };  

};



// преобразовать результат парсинга во вьюзавр-дамп
// результат пишется обратно в аргумент parsed
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
  for (let c of Object.keys( parsed.children )) {
    let cc = parsed.children[c];
    parsed2dump( vz, cc, base_url );
  }
  for (let cc of (parsed.features_list || [])) {
    parsed2dump( vz, cc, base_url );
  }
  for (let pv of (Object.values(parsed.params) || [])) {
     // преобразуем очередной параметр если он окружение
     if (Array.isArray(pv) && pv.length > 0 && pv[0].this_is_env) {

        //console.log("pv",pv.env_args)
        //if (pv.env_args)          debugger;

        for (let penv of pv)
           parsed2dump( vz, penv, base_url );
     }
  }

  // F-POSITIONAL-ENVS
  if (parsed.positional_params_count == 1
      && parsed.named_params_count == null
      && Object.keys( parsed.features ).length == 0
      )
  {
     parsed.features[ "is_positional_env" ] = true;
     // выяснилось что удобно таки сделать ссылку на output
     // потому что в computer например - надо в наборе детей собирать output последнего
     // а там фичи еще не назначены и короче даже не выяснить кто он там..
     // хотя можно было бы так-то и ловить событие... что фича назначилась
     // ну да ладно, пока так, там посмотрим. @maybe @optimize убрать ссылки эти
     parsed.links[ "p_link_for_output"] = { from: ".->0", to: ".->output", soft_mode: true };
     // soft-mode тут спорно конечно, но..
  }

  
  /////////////////
  // F-ENV-ARGS
  if (parsed.children.env_args) {
    debugger;
  //  parsed.$children_function = 
  //  parsed.children = [];
  }
  

  parsed.forcecreate = true;
  parsed.features[ "base_url_tracing" ] = {params: {base_url}};

  /////////////////
  // F_PARAM_EVENTS
  // активируем фичу ток если есть on_-параметры в статике
  // + оказалось что on_some=(....) это features_list[i].links.output_link_0.to.startsWith(".->on_") уже и там 
  
  for (let n of (Object.keys(parsed.params) || [])) {
      if (n.startsWith("on_")) {
        parsed.features[ "connect_params_to_events" ] = true;
        break;
      };
  };

  if (!parsed.features[ "connect_params_to_events" ])
  for (let i=0; i<parsed?.features_list?.length; i++) {
    let f = parsed.features_list[i];
    for (let k of Object.values( f.links ))
    if (k.to.startsWith(".->on_"))
    {
      parsed.features[ "connect_params_to_events" ] = true;
      break;
    };
    
  }
  
  parsed.features[ "connect_params_to_events" ] = true;
  /////////////////
  

  //feature("base_url_tracing",{base_url});
  return parsed;
}

// испортирование js-модуля
// пример: threejs=import_js("....путь....")

// todo мб это как-то совместить с load можно..
// сейчас лоад может загружать js файл но дальше 
// 1 он пытается его вызвать setup
// 2 и если там export-ы то они никуда не присваиваются..
// todo прикрутить сюда таблицы из пакетов чтоб загружать не просто прямым путям

export function import_js(env) {
  env.onvalue(0,(path) => {
    import(path).then( res => {
      env.setParam("output",res);
    })
  });
};

export function is_positional_env( env ) {};

var compolang_modules = {};
var loaded_things = {};
// временный хак - пока с неймспейсами пакетов не наладилось
// будем хранить загруженное и даже по нему отсекаться
// и таким образом register-feature один раз у нас сработает.

// короче решено все делать через load и пусть она разбирается что там.
// а то уже взрыв мозга, что загружать, package или combolang.
export function load(env,opts) 
{
  //fff
  //env.feature("dbg_skip");

  env.feature("simple-lang");
  //env.parsed_alive = false;
  //env.finalize_parse = () => { current_parent = parents_stack.pop() };

  env.addString("files");

/*
  env.onvalues_any( ["files",0], (files, files0) => {
    //env.setParam("pending",proms);
  });
*/
  env.onvalue( "files", process_file_params );
  env.onvalue( 0, process_file_params );

  function process_file_params() {
    //files ||= files0;
    let files = env.params.files || env.params[0];
    if (!files) return;
    let proms = Promise.all( files.split(/\s+/).map( loadfile ) );
    /// пока такой вот хак выходит
    env.restoreChildrenFromDump = () => proms;
  }

/*
  env.restoreChildrenFromDump = (dump, ismanual) => {
    debugger;
    return Promise.resolve("success");
  }
*/

  function loadfile(file) {
    try {
      //console.log('env base path',env.$base_url,file)
      let p = loadfile0( file );
      if (p && p.catch)
        p.catch( (err) => {
          console.warn("compolang load: error:",err.message);
          env.vz.console_log_diag( env );    
        })
      return p;
    } catch (err) {
      console.warn("compolang load: error",err.message);
      //console.log("compolang load: file",file,"error",err.message);
      env.vz.console_log_diag( env );
      return null;
    }
  }

  function loadfile0(file) {
     if (!file) return;
     //console.log("compalang loadfile",file)

     if (loaded_things[ file ]) {
        //console.log("returning existing promis for file",file)
        return loaded_things[ file ];
     };

     if (file.endsWith( ".js")) {
       var file2 = env.compute_path( file );
       //console.log('env base path',env.$base_url)
       //console.log("loading package",file,"=>",file2);
       loaded_things[ file ] = vzPlayer.loadPackage( file2 )
       return loaded_things[ file ];
     }
     if (vzPlayer.getPackageByCode(file)) {
       loaded_things[ file ] = vzPlayer.loadPackage( file )
       return loaded_things[ file ];
     }     

     if (compolang_modules[file])
      file = compolang_modules[file];
     else
      file = env.compute_path( file );

     // надо второй раз проверить... там выше про модули больше проверка получается была..
     if (loaded_things[ file ]) {
        //console.log("returning existing promis for file",file)
        return loaded_things[ file ];
     };
   

     let new_base_url = env.vz.getDir( file );

     // будем возвращать промису когда там все загрузится
     let prom = new Promise( (resolve,reject) => {
      
       fetch( file ).then( (res) => res.text() ).then( (txt) => {
         
         // так оказывается что параллельно и тут другие такие же загрузчики
         if (loaded_things[file] !== prom) {
           
           loaded_things[file].then( (sibling_result) => {
              resolve();
              // тут наверное какой-то результат, но посмотрим..
              //env.setParam("output",sibling_result);
              return;
           });
         };

         // нужна sub-env для отслеживания base-url
         var subenv = env.create_obj( {} );
         subenv.feature("simple-lang");
         subenv.addLabel("source_file", file );
         //subenv.setParam("source_file", file );

         //console.log("interpreting file", file )
         let dp1 = subenv.parseSimpleLang( txt, {vz: env.vz, parent: env.ns.parent,base_url: new_base_url, diag_file: file } );
         let load_env_scope = env.$scopes.top();

         let $scopeFor = env.$scopes.createScope("load"); // F-SCOPE

         // это есть ужасный хак, когда модули из одного load будут видеть родительский scope
         // по идее тут надо остановиться..
         $scopeFor.$lexicalParentScope = load_env_scope;

         let p1 = subenv.restoreFromDump( dp1,false,$scopeFor )

         // было
         //subenv.parseSimpleLang( txt, {vz: env.vz, parent: env.ns.parent,base_url: new_base_url} );

         Promise.resolve(p1).then( () => {
           resolve(p1); // загрузили, пропарсили все там
           env.setParam("output",p1);
         });
       });

     });

     loaded_things[ file ] = prom;

     return prom;
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

// это кстати напоминает "режим" в kepler
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
  env.on('forgetChild',(c) => {
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
         if (c.is_feature_applied("if")) continue;
         if (!cfirst) cfirst = c;
         // пропускаем ссылки.. вообще странное решение конечно.. сделать ссылки объектами
         // и потом об них спотыкаться
         if (cprev) {
           let k = c.linkParam("input",`../${cprev.ns.name}->output`,true); // вообще странно все это
           //created_links.push( k );
           // оно там само внутрях удаляет..
         }
         cprev = c;
      }
      // output последнего ставим как output всей цепочки
      if (cprev)
          created_links.push( env.linkParam("output",`${cprev.ns.name}->output`,true) );
      else
          created_links.push( env.linkParam("output",`~->input`,true) ); // по умолчанию выход из пайпы пусть будет и входом?
          //created_links.push( env.linkParam("output",`.->input`) ); // по умолчанию выход из пайпы пусть будет и входом?
          
      // input первому ставим на инпут пайпы

      /* 30.08.22 зачем это? */
      if (cfirst) {
          //if (!cfirst.hasLinksToParam("input") && !cfirst.hasParam("input"))
          // заменяем наличие параметра на наличие непустого значения параметра
          if (!cfirst.hasLinksToParam("input") && !cfirst.getParam("input"))
          {
            if (env.hasLinksToParam("input")) // если у пайпы есть input..
                created_links.push( cfirst.linkParam("input",`..->input`,true) );
          }
      }
      

      pipe_is_generating_links = false;
   }
}

// потребность: удобный метод построения вычисления
// computer { c1; c2; c3; }
// такого что результат computer->output это есть c3->output
// на это идет завязка из pegjs
// F-PARAM-EXPRESSION-COMPUTE
export function computer(env) 
{


  let unsub=()=>{};
  function unsub_and_forget() { unsub();unsub = ()=>{}; }
  function set_unsub( v ) { unsub = v };

  function create_monitoring() {
    unsub_and_forget();
    if (env.ns.children.length == 0) return;

    let i = env.ns.children.length - 1;
    let c;
    
    while (i >= 0) {
      c = env.ns.children[ i ];
      if (c.is_link) {
        c = null;
        i--; 
        continue;
      }
      break;
    }
    if (!c) return;

    // а вот выясняется что фичи то еще и не назначены..
    let output_name = "output";
    //let output_name = c.is_feature_applied("is-positional-env") ? 0 : "output";
    //console.log(c.getPath(),JSON.stringify(c.$features_applied),output_name,c)
    //let output_name = "output";

    set_unsub( c.trackParam(output_name,(v) => {
      env.setParam("output",v);
    }) );
    //if (c.hasParam(output_name)) // этот иф дает такое поведение что если результата вычисления нет то его и у выражения нет

    if (c.params[output_name]) // получается undefined-значения мы тут не радаем
        env.setParam("output", c.params[output_name] );
    // но вообще странно... по идее если там есть undefined результат ну и выдайте его..  
    // ладно это на туду оставим

    //console.log("used ",c)
    
    /*
    c.on("feature-applied-link",() => {
      console.log('link detected',c)
    })
    */
    
  };
  env.on("remove",unsub_and_forget);

  env.feature("delayed");
  let create_monitoring_d = env.delayed(create_monitoring);
  create_monitoring_d();
  env.on('appendChild', create_monitoring_d ); 
  env.on('forgetChild', create_monitoring_d );

  // вот тут мб делейед подошло бы а то она тыркаться будет каждый раз
  // но ладно пока @todo @optimize
}


// добавляет фичу в цепочку активации фич
// пример: append_feature "rect" "rounded red"
// и значит когда создается объект rect к нему цепляются фичи rounded и red
export function append_feature( env, envopts ) {
  // дорогая вещь
  console.error("append_feature is deprecated")
  debugger;

  env.onvalues( [0,1],(a,b) => {
    //console.log("append_feature",a,b)
    if (a && b) {
      env.vz.register_feature_append( a,b );
    }
  });
}

// штучка как register_feature но покороче
// пример: feature "rect" { .... }
export function feature( env, envopts ) {
  return register_feature( env, envopts );
}

// а на будущее мб и так сделать: rect: feature { .... }
// и тогда с ними всяко работать может быть можно будет.. кстати.. 
// по именам найти @rect - хоп а это объект фичи.. 
// т.е. мы его т.о. вытаскиваем из пр-ва имен фич в пр-во имен объектов. интересно........
// в т.ч. для импорта интересно. ну и для модификаций всяких если что.
// @idea

// регистрирует фичу name, code где code это код тела функции на яваскрипте
// фишка - если у reg feat в детях дано несколько тел, применяются все.
// но в каком смысле все - похоже нахрапом разом в один объект....
export function register_feature( env, envopts ) {
  // ну вроде как не надо - внизу юзаем params[0]
  //env.createLinkTo( {param:"name",from:"~->0",soft:true });
  //env.createLinkTo( {param:"code",from:"~->1",soft:true });

  var children = {};

  //let orig_rs = restoreChildrenFromDump;  
  env.restoreChildrenFromDump = (dump, ismanual, $scopeFor) => {
    children = dump.children;
    compile();
    
    //env.monitor_values(["code",0],compile );
    // теперь разик скомпилировались - будем мониторить еще и code переназначения
    env.trackParam( "code", compile );
    env.trackParam( 0, compile );

    return Promise.resolve("success");
  };
  
  var apply_feature = () => {};

/*
  let nam = env.getParam("name") || env.getParam(0) || env.ns.name;
  console.log(nam)
  debugger;
 */ 

  env.addLabel("name");
  
/*
  env.onvalue("name",() => {
    env.vz.register_feature( env.params.name, (e,...args) => {
      apply_feature(e,...args)
    } );
  });
*/  

  var js_part = () => {};
  var compalang_part = () => {};

  var registered = false;

  function compile() {
    js_part = () => {};
    compalang_part = () => {};

    // маленький хак
    env.params.name ||= env.params[0] || env.ns.name;
    env.params.code ||= env.params[1];

    if (!env.params.name) {
      console.error("RESIGTER-FEATURE: feature have no name.")
      return;
    }


    if (env.params.code) {
      // я бы предложил делать код явно.. т.е. требовать что там функция должна быть

      if (env.params.code.bind) {
        //console.log('feat')
        js_part = env.params.code;
      }
      else
      {
        // @idea - может нафиг такую генерацию кода? пусть сразу функцию присылают
        // ну или хотя бы текст в форме лямбды. но функция лучше - можно на любом коде писать
        // хоть на комполанге хоть на лиспе хоть на xml ксатти
        // feature "foo" (from-xml "<points/>");

        var code = "(env,feature_env,...args) => { " + env.params.code + "}";
        /* ерунда это все - мы код прямо сейчас eval-им.
        var code = `(env,args) => { 
          try {
            ${env.params.code}
          } catch(err) {
            console.error("REGISTER-FEATURE: error while evaluating js!",err,"feature_name=${env.params.name}");
          }
        }`;
        */
        try {
          //console.log(code)
          js_part = eval( code );
        } catch(err) {
          console.error("REGISTER-FEATURE: error while compiling js!",err,"\n********* code=",code);
        }
      };
    }
    
    if (Object.keys( children ).length > 0) {
      
      compalang_part = (tenv) => {
        //console.log("children=",children)

        let promarr = [];
        let first = true;
        // F-SCOPE
        // собственный скоп фичи - пойдет всюду на детей и аттачед фичи
        // и не пойдет во вложенные компаланг-фичи (ибо они там создадут собственный новый скоп)
        let $scopeFor = tenv.$scopes.createScope( "feature "+env.params.name + " for env id "+tenv.$vz_unique_id);
        $scopeFor.$lexicalParentScope = env.$scopes.top();
/*
        if (children.env_args) {
          env.vz.copyEnvArgsToScope( tenv.params, children.env_args, scope )
          for (let i=0; i<)
          tenv.params.args_count = 0;
        }
*/

        for (let cname of Object.keys( children )) {
          var edump = children[cname];
          edump.keepExistingChildren = true; // смехопанорама
          // но иначе применение фичи может затереть созданное другими фичами или внешним клиентом

          // а вот это не надо. у нас порядок определен - сначала работают внутренние фичи разворачиваются, потом внешние
          // и мы сейчас как раз внешняя - к хренам стираем там все вложенными фичами выставленное в случае конфликта
          // update это все-таки надо. потому что унас фичи щас разворачиваются почему-то сверху вниз.
          // т.е. сначала полностью одна, а потом уже переход к развороту ее тела.. это странно кстати..
          // update - причина такого дизайна, кверх ногами, когда мы сначала выставляем свои парметры
          // и ссылки а потом идем внизины во вложенные фичи - это чтобы лишний раз не создавать
          // и затем не удалять создаваемые ими ссылки и вычислительные окружения
           edump.keepExistingParams = true;

          // делаем идентификатор для корня фичи F-FEAT-ROOT-NAME
          // todo тут надо scope env делать и детям назначать, или вроде того
          // но пока обойдемся так
          tenv.$env_extra_names ||= {};
          //console.log("adding extra-name",cname)
          if (first)
             tenv.$env_extra_names[ cname ] = true;

          if (first) {
            // производим добавление ток для первого элемента
            // остальные вроде как сами там добавятся в createSyncFromDump
            /*
            if (cname == "tb") {
              console.log("adding tb for env",tenv.$vz_unique_id,$scopeFor);
              $scopeFor.patched_by_tbb = "tb";
               //debugger;
            }
            */

            if (!edump.name_is_autogenerated)
                $scopeFor.$add( cname, tenv  ); // F-SCOPE
          }
          // в эту новую скопу.. добавляем и фичу, и сиблинги.. ок

          let res;
          if (first) { // это код для целевого окружения где примененена фича
            first = false;
            //if (tenv.getPath().indexOf("_addon3d")>0)
            //  debugger;
            res = tenv.restoreFromDump( edump, false, $scopeFor );  

          }
          else {
            // а последующие вещи - это доп дети сиблинги для целевого окружения
            // таков алгоритм работы feature в компаланге..
            // (типа как будто мы генерируем новое, не привязанное к созданному окружению)
            // идея - собирать их в проперте что ли в какой-то (но опять же много фич много пропертей..)
            // идея - может быть это лишнее, и его стоит куда-то переместить, более явно обозначить
            // потому что глядишь на фичу и не понимаешь что вот это - не будет частью фичи
            // а лишь порождается ею.
            // к тому же у нас есть insert_siblings_to_parent

            //console.warn("compolang feature: skipping 2nd and rest elem",edump);
            
            edump.lexicalParent = tenv;
            if (tenv.hosted) {
              // баг - rec нету
              res = env.vz.importAsParametrizedFeature( rec, tenv.host, $scopeFor );
            }
            else {
              res = tenv.vz.createSyncFromDump( edump,null,tenv.ns.parent,null,null,$scopeFor );
            }
            
          }
          promarr.push( Promise.resolve(res) ); 
         }; 
            
        //tenv.vz.createChildrenByDump( dump, obj, manualParamsMode );
        //return Promise.all( promarr );
        return Promise.allSettled( promarr );
      }
    }

    apply_feature = (e,...args) => {
      // теперь фича выдает аутпут. его могут вызывать как функцию всякие товарищи dom
      if (!e) return;

      if (e.removed) {
        //debugger;
        return Promise.all("removed");
      }
      
      let r1 = js_part( e,env, ...args);
      let r2 = compalang_part( e,...args);

      //console.log("emitting apply of feature", env.params.name)
      env.emit('applied',e);

      return Promise.all( [Promise.resolve(r1), Promise.resolve(r2)] );
    }

    if (!registered) {
      registered = true;
      let feature_f = (e,...args) => {
        return apply_feature(e,...args)
      };
      feature_f.$locinfo = env.$locinfo;
      env.vz.register_feature( env.params.name,feature_f );
    };

    env.setParam('output',apply_feature);
  }

  //env.onvalues_any(["code",0],compile );
  // todo optimize сейчас это ведет к двойной компиляции - при парсинге чилдренов и при мониторинге вот этого вот

  // чо ето?
  env.on("parsed",() => {
    debugger;
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

export function resolve_url( env ) {
  env.onvalue(0,(v) => {
    // вот вечный вопрос.. что делать с единицами и с массивами..
    // в js у нас удобно - есть map. но в процессах такого нет и не будет 
    // в случае обработки обычных данных - их слишком много, и иметь процесс на каждый элемент
    // это дорого..
    if (Array.isArray(v)) {
      let r = v.map( p => env.compute_path(p) )
      env.setParam("output",r);
      return;  
    }
    let r = env.compute_path(v);
    env.setParam("output",r);
  })
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

/*
export function path_to_param_value( env )
{
   env.addParamRef("input");
}   

feature "link" {
  l: {
    v1: path_to_param_value input=@l->from;
    set_param path=@l->to value=@v1->output;
  }
}
*/

//////////////////////////////////////////
// устанавливает параметр при вызове команды apply
// * value - значение которое устанавливать
// кому выставлять:
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

   ////////////////////////////// кусочек глупого кеширования
   let tobj;
   let tname;
   env.onvalue("target",(t) => {
      var arr = t.split("->");
      tname = arr[1];
      tobj = env.findByPath( arr[0], env );
   })
   //////////////////////////////

   env.addCmd( "apply",() => {
      //console.log("called setter apply. value=",env.params.value, env.params.object, env.params.param);

      if (env.params.target) {
        //var arr = env.params.target.split("->");
        //var tobj = env.findByPath( arr[0] );
        if (tobj && tname) {
          tobj.setParam( tname, env.params.value, env.params.manual );
        } else 
          console.log("setter: target obj not found",env);
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

   env.apply.this_is_imperative_participant = true;
   env.setParam("output", env.apply);
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
      let resarr = [];

      if (env.params.code) {
        // кстати идея - а что если там сигнатуру подают то ее использовать?
        // т.е. если cmd="(obj,coef) => { ..... }"
        // todo optimize на каждом вызове компиляция...
        var func;
        if (typeof( env.params.code) == 'function')
            func = env.params.code;
        else  
            func = new Function( "env","arg1, arg2, arg3, arg4, arg5", env.params.code );

        let r = func.call( null, env, ...args );
        resarr.push(r);
        //eval( obj.params.code );
      }
      if (env.params.cmd) {
        env.callCmdByPath(env.params.cmd,...args)
      }
      for (let c of env.ns.getChildren()) {
        let q = c.callCmd("apply",...args);
        resarr.push(q);
      }
      return resarr;
   } )
}

// аналог func но допускает "каррирование"
// и не умеет вызывать cmd и "детей"
// кстати так-то детей могла бы... ну как могла бы.. - их надо было бы создавать..
// тут непонятный момент... что к чему... РРРРРРРРРР )))))
// в том плане что хотелось бы button "text" { lambda { toggle_feature @tgt "alfa" }}

// пример: lambda code=.....
export function feature_lambda( env )
{
   env.feature("call_cmd_by_path");

  // пусть у лямбды аутпут будет js-функция для вызова
  env.setParam("output", (...args) => {
    return env.callCmd("apply",...args);
  }) 

  let func;
  function update_func() {
    let code = env.params.code;
    if (typeof(code) == 'string') code = eval(code);
    func = code;
  }
  env.onvalues_any(["code"],update_func);

  let configured = false;
  env.onvalues_any(["code"],() => {
    if (configured) return;
    configured = true;
    

    //console.log( "feature_func: installing apply cmd",env.getPath());
       env.addCmd( "apply",(...extra_args) => {
          if (env.removed) {
             console.log("lambda remove ban - it is removed", env.getPath())
             return;
          }

          // получается нам apply может прилететь пока мы даже еще onvalues не обработали.. нормально..
          if (!func) update_func();
          if (!func) {
            console.error("lambda: code is not defined but apply is called", env.getPath());
            return;
          }
          //console.log("lambda apply",env.getPath())

          let args = [];
          for (let i=0; i<env.params.args_count;i++) 
            args.push( env.params[i] );

          for (let i=0; i<extra_args.length;i++) 
            args.push( extra_args[i] );

          //args = args.concat( extra_args );

          return func.apply( env,args )
       } );    
  });

   
}

// вариант: вызывает содержимое после задержки
// сейчас: модификатор для функций, задерживает их выполнение (и собирает несколько запросов в 1 пачку)
export function delay_execution( env ) {
  env.feature("delayed");

  let orig_apply;
  function setup() {
    if (!orig_apply) orig_apply = env.host.apply;

    env.host.apply = env.delayed( orig_apply, env.params.timeout || 0 );
  }
  if (env.host.apply)
      setup();
  env.host.on("gui-changed-apply",setup );

  env.onvalue("timeout",setup);
  //console.log("delay_execution: hooked into ",env.host.getPath())
  //env.host.onvalue("apply",setup);
}

// вызывает команду name у объекта target
export function call_cmd( env )
{
  env.addObjectRef("target");

  env.addCmd( "apply",(...args) => {

      if (!env.params.target) {
        console.error("call_cmd: target not specified", env.getPath());
        return;
      }
      if (!env.params.name) {
        console.error("call_cmd: name not specified", env.getPath());
        return;
      }

      env.params.target.callCmd( env.params.name, ...args );

   } );

  env.setParam("output", env.apply);
}

// вызывает функцию или команду name у объекта target
// кстати а почему бы не сделать совместно - и вызов команды, и emit одновременно...

// доп идея - давайте прокаррируем нафиг вызов
export function call( env )
{
  env.addObjectRef("target");

  if (!env.paramAssigned("target"))
    env.createLinkTo( {param:"target",from:"~->0",soft:true });
  if (!env.paramAssigned("name"))
    env.createLinkTo( {param:"name",from:"~->1",soft:true });

   env.addCmd( "apply",(...extra_args) => {

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

      let args = [];
      // ну пока так вот коряво сделаем - от 2го аргумента
      for (let i=2; i<env.params.args_count;i++) 
        args.push( env.params[i] );

      for (let i=0; i<extra_args.length;i++) 
        args.push( extra_args[i] );

      //console.log("calling ",to,nam,"args",args);

      if (to.hasCmd( nam )) // идея предусмотреть вариант когда объект это не
        to.callCmd( nam, ...args );
      else if (typeof( to[nam] ) == "function")
        to[nam].call( undefined, ...args );
      else
        to.emit( env.params.name, ...args );
        //console.error("call: target has no input thing named",nam,target.getPath());

     env.emit('done');

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

      // т.е. мы можем зарегать событие.. и если таковое есть - то это будет превращаться в команду
      // и быть доступным через call.

   } )
}

// вызывает событие name у объекта target
export function emit_event( env )
{
  env.addObjectRef("object");

   env.addCmd( "apply",(...args) => {

      if (!env.params.object) {
        console.error("emit_event: target not specified", env.getPath());
        return;
      }
      if (!env.params.name) {
        console.error("emit_event: name not specified", env.getPath());
        return;
      }

      env.params.object.emit( env.params.name, ...args );

      env.emit("done");
   } )
}

//export function emit


// автоматический вызов команды apply при изменении любых параметров
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
  // но и по старту тоже надо
  eval_delayed();
}


// вычисляет js код
// каждый раз когда происходит изменение переменной code
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
  //env.createLinkTo( {param:"name",from:"~->0",soft:true });
  env.onvalues_any(["name",0],(name,name0) => {
    name ||= name0;

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
      var sobj = env.findByPath( objname, env );
      if (!sobj) {
        console.error("callCmdByPath: cmd target obj not found",objname );
        env.vz.console_log_diag( env );
        
        var sobj2 = env.findByPath( objname, env );
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
// идея - а что если не children а list ему? это ж интересно так-то.

export function repeater( env, fopts, envopts ) {
  var children;

  var use_scope_for_passing_input=false; // F_REPEATER_SCOPE
  var scope_attrs;

  let current_state = [];
  let model;

  /* оказалось что env.restoreFromDump уже вызывают, 
     если repeater первый в register-feature стоит.. - то он не успел получается это переопределить
     поэтому я перешел на переопределение restoreChildrenFromDump...

  env.restoreFromDump = (dump,manualParamsMode) => {

  }*/

  env.restoreChildrenFromDump = (dump, ismanual) => {
    // короче выяснилось, что если у нас создана фича которая основана на repeater,
    // то у этого repeater свое тело поступает в restoreChildrenFromDump
    // а затем внешнее тело, которое сообразно затирает собственное тело репитера.
    if (!children) {
      children = dump.children;
      
      scope_attrs = dump.children_env_args?.attrs;
      use_scope_for_passing_input = scope_attrs ? true : false;

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
  env.onvalue("target_parent",recreate );

  env.addCmd("refresh",() => recreate());



  function recreate() {

     //console.log("repeater recreate", env.getPath() )
     if (env.removed)
        debugger;
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
     if (target_parent && target_parent.is_feature_applied("pipe"))
     {
        target_parent = target_parent.ns.parent;
        // если там ()-выражение, то в него нельзя добавлять.. ну по идее.. и посему будем добавлять в себя
        if (target_parent.is_feature_applied("computer"))
          target_parent=env;
     }

     if (env.params.target_parent) 
        target_parent = env.params.target_parent;


     //////////// вот здесь момент создания.
     // и вопрос - надо добавить или убавить. именно на этот вопрос надо отвечать.

     if (env.params.always_recreate)
        decrease_state_to( 0 );
    
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

           // пара новый $scope для жизни внутри и lexicalParent для доступа к окружению репитера.           
           edump.lexicalParent = env;
           //let $scopeFor = env.$scopes[ env.$scopes.length-1 ];
           let $scopeFor = env.$scopes.createAbandonedScope("generated by repeater id"+env.$vz_unique_id);
           $scopeFor.$lexicalParentScope = env.$scopes.top();

           // qqq
           if (use_scope_for_passing_input)
              fill_scope_with_args( $scopeFor, scope_attrs, [model[i], i] );

           let p = env.vz.createSyncFromDump( edump,null,target_parent,null,null,$scopeFor );
           current_state.push( {promise: p} );

           let local_i = i;
           p.i = i;
           p.then( (child_env) => {
              
              if (p.need_cancel) {
                child_env.remove();
                return;
              }
              current_state[local_i].child_env = child_env;

              // делаем идентификатор для корня фичи F-FEAT-ROOT-NAME
              // todo тут надо scope env делать и детям назначать, или вроде того
              // но пока обойдемся так
              child_env.$env_extra_names ||= {};
              child_env.$env_extra_names[ firstc ] = true;

              // todo epochs
              // поскольку тут по индексу, а model глобальная - мы получаем свежее значение
              /// даже если промис сработал после многократного перезапуска

              if (!use_scope_for_passing_input) {
                let element = model[local_i];
                child_env.setParam("input",element);
                //child_env.setParam("inputData",element);
                child_env.setParam("input_index",local_i);
                // короче плохо input - там может быть штука со своим input...
                // поэтом лучше другое имя, хотя бы inputData

                child_env.setParam("modelData",element);
              }

              env.emit("item-created", child_env);
           });        
       }
     }

     let envs_promises  = current_state.map( s => s.promise );
     Promise.all( envs_promises ).then( (envs) => {

        ///env.setParam( "output", envs );
        /* памятник попытке внедрить очередную сложность. правильное решение - вынести это
           во вне тем более у нас уже еесть repeater .. | map_get "repeater_output" например.
        let acc = [];
        for (let e of envs) {
           if (e.params.repeater_output) {
             if (Array.isArray(e.params.repeater_output))
               acc = acc.concat( e.params.repeater_output );
             else acc.push( e.params.repeater_output );

             let u = e.trackParam("repeater_output",publish_repeater_output);
           }
           else
             acc.push( e );
        }
        */
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
           else {
            rec.promise.need_cancel=true;
           }
       }
  }

  function actualize_state_to_model() {
    // актуализируем у уже созданных
       for (let i=0; i<current_state.length; i++) {
          let child_env = current_state[i].child_env;
          if (!child_env) continue;

          if (use_scope_for_passing_input)
          {
              //console.log("rep: actualizing ",i,"to ",model[i])
              fill_scope_with_args( child_env.$scopes[0], scope_attrs, [model[i], i] );
          }
          else
          {
              let element = model[i];
              child_env.setParam("input",element);
              child_env.setParam("modelData",element);
              //child_env.setParam("input_index",i); не меняетца
          }
       }
  }

  function fill_scope_with_args(newscope,attrs,values) {
    for (let i=0; i<attrs.length;i++)
    {
        let argname = attrs[i];
        // console.log('fill_scope_with_args: argname=',argname,'i=',i)
        // let cell = env.get_cell(i);
        newscope.$add( argname, values[i], true );
    };
  };  

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

// отличается от compute тем что то что код return-ит и записывается в output
// отличается от compute_output тем что работает с позиционными аргументами
// F_POSITIONAL_PARAMS
export function feature_eval( env ) {
  env.setParam("output",undefined);
  env.setParamOption("output","internal",true);

  //console.error("compolang eval init",env.getPath())

  function evl() {

    if (!func) update_code();
    if (!func) {
      console.error("compolang eval: code not specified",env.getPath())
      return;
    }

    let args = [];

    // попытка
    // тоже крышесносец. то он есть, то его нет. это писец и заставляет в кодах делать проверку.
    // и еще - там меняется порядок параметров
    // хотя бы может делать тогда this.input, что ли...
    // if (env.hasParam("input")) args.push( env.params.input );

    for (let i=0; i<env.params.args_count;i++) 
    {
      let v = env.params[i];
      if (!env.params.allow_undefined && typeof(v) == "undefined") { // ну пока так.. хотя странно все это..
        /// 
        return;
      }
      args.push( v );
    }

    //console.log("compolang eval working",env.getPath(),args)

    let res = func.apply( env, args );

    env.setParam("output",res);
  }

  env.feature("delayed");
  var eval_delayed = env.delayed( evl )

  env.on('param_changed', (name) => {
     if (name != "output")
        eval_delayed();
  });

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
     eval_delayed();
     // итоого у нас уже вызов некий произойдет
  })

  env.addCmd("recompute",eval_delayed);

  var eval_delayed2 = env.delayed( evl,2 )
  eval_delayed2();
}





// искалка объектов. вход строка pattern выход output набор найденных окружений.
// см criteria-finder.js
export function find_objects_old( env  ) {
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

  env.addLabel("found_objects_count");
}

export function find_objects( env  ) {

  env.feature("find_objects_bf");

  env.addString("pattern");
  env.addObjectRef("pattern_root","/");

  env.monitor_values( ["pattern","pattern_root"],(p,r) => {
    let features = "";
    if (p && p.startsWith("** ")) {
      features = p.slice( 3 );
    }
    else
    {
      // мб будем считать что тут у нас таки значит сразу метки?
      // нет уж если метки то используте features.
      if (p)
        console.error("find_objects: unsupported pattern!",p)
      env.setParam("output",[]);
      return;
    }
    env.setParam( "features",features);
    env.setParam( "root",r);
  })
  
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
      if (en == "gui-changed-undefined" )
        debugger;
      console.log("GPN connection tracking name=",en,obj.getPath(), obj.getParamsNames() )
      tracking = obj.on( en, (...args) => {
         console.log("GPN tracking DETECTED! name=",en,obj.getPath()) 
         env.apply(...args); // вызов метода окружения func
      })
   });

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
  env.host.on("param_changed",f);
  function f(n,v,msg){
    if (env.params.list) {
      if (env.params.list.indexOf(n) < 0) return;
    }
    console.log( "console_log_params:", (msg || ""), (env.params.text || env.params[0] || ""), env.host.getPath(), "->",n,":",v )
    env.vz.console_log_diag( env,true );
  }
  for (let k of env.host.getParamsNames()) {
    f(k,env.host.getParam(k),"[INIT]");
  }

}

export function console_log_life( env, options )
{
  let counter=0;
  env.host.on("param_changed",(n,v) => {
    console.log( "console_log_life: ",env.params.text || env.params[0] || "", 
       "param changed", "->",n,":",v,
       env.host.getPath(), env.host
        );
    env.vz.console_log_diag( env );
    env.setParam("output",counter++)
  });
  {
    let g = env.host.addGui;
    env.host.addGui = (...args) => {
      console.log( "console_log_life: ",env.params.text || env.params[0] || "", 
        "addGui",...args,
        env.host.getPath(), env.host
          )
      env.vz.console_log_diag( env );
      env.setParam("output",counter++)
      return g.apply( env.host, args);
    }

    env.on("remove",() => {
      env.host.addGui = g;
    })
  }

  {
    let g = env.host.callCmd;
    env.host.callCmd = (...args) => {
      console.log( "console_log_life: ",env.params.text || env.params[0] || "", 
        "cmd called",...args,
        env.host.getPath(), env.host
          )
      env.vz.console_log_diag( env );
      env.setParam("output",counter++)
      return g.apply( env.host, args);
    }
    env.on("remove",() => {
        env.host.callCmd = g;
    })
  }

  {
    let g = env.host.emit;
    env.host.emit = (...args) => {
      let qq=args[0].substring(0,6);
      //if (args[0] != 'param_changed' && qq != "param_") {
      if (qq != "param_") {  
        console.log( "console_log_life: ",env.params.text || env.params[0] || "", 
          "event",...args,
          env.host.getPath(), env.host
             )

        env.vz.console_log_diag( env );
        env.setParam("output",counter++)
      };
      return g.apply( env.host, args);
    }
    env.on("remove",() => {
        env.host.emit = g;
    })
  }  

  env.on("remove",() => {
    console.log("console_log_life: env removed!", env.params.text || env.params[0] || "", env.host.getPath());
    env.vz.console_log_diag( env );
    env.setParam("output",counter++)
  });
}

// решил пусть будет один режим работы - по позиционным параметрам
// а другие всякие вещи... ну отдельными методами.
export function console_log( env, options )
{
  function print() {
    let acc=[];
    let h={};
    for (let i=0; i<env.params.args_count; i++) {
      acc.push( env.params[i] );
      h[i]=true;
      h[i.toString()] = true;
    }
    // также напечатаем все остальное
    for (let n of Object.keys(env.params)) {
      if (h[n]) continue;
      if (n == "args_count" || n == "output") continue;
      // не выводим output потому что там input ему равен
      acc.push( n ); acc.push( "="); acc.push( env.params[n])
    }

    console.log( ...acc );
  }

  env.feature("delayed");
  let printd = env.delayed(print);
  env.on("param_changed",printd);

  print();

  env.onvalue("input",(input) => {
    env.setParam("output",input); // доп-фича - консоле-лог пропускает дальше данные
  });  
}

/*
export function console_log( env, options )
{
  env.createLinkTo( {param:"text",from:"~->0",soft:true });

  function print() {

    console.log( env.params.text || "", env.params.input || "" );
  }
  env.onvalue("text",print);
  env.onvalue("input",(input) => {
    print();
    env.setParam("output",input); // доп-фича - консоле-лог пропускает дальше данные
  });

  env.addString("text");

  // первый вид поведения - само по себе, когда текст появится.
  // второй вид поведения - по input-у.

  // третий вид поведения - по apply
  env.addCmd("apply",(...args) => {
    console.log( env.params.text || "", env.params.input || "", ...args);
  })
}
*/

export function console_log_input( env, options )
{
  env.createLinkTo( {param:"text",from:"~->0",soft:true });

  function print() {
    console.log( "console_log_input",env.params.text || "", env.params.input );
    env.vz.console_log_diag( env );
  }

  env.onvalue("input",(input) => {
    print();
    env.setParam("output",input); // доп-фича - консоле-лог пропускает дальше данные
  });
  
  env.addString("text");
}

export function console_log_apply( env, options )
{
  //env.createLinkTo( {param:"text",from:"~->0",soft:true });

  env.addCmd("apply",(...args) => {
    console.log( env.params.text || env.params[0] || "", ...args);
  })
}

export function feature_debug_input( env )
{
  env.createLinkTo( {param:"text",from:"~->0",soft:true });

  function print() {
    console.log( env.params.text || "", env.params.input || "" );
  }
  
  env.trackParam("input",(input) => {
    print();
    // фича номер два это остановка потому что input поменялся - удобно ловить
    // хотя это можно было и в консоли делать
    debugger;
    env.setParam("output",input); // доп-фича - консоле-лог пропускает дальше данные
  });
  
  env.addString("text");
}


export function feature_debugger( env )
{
  env.createLinkTo( {param:"text",from:"~->0",soft:true });

  function print() {
    console.log( env.params.text || "", env.params.input || "" );
  }
  
  env.onvalue("input",(input) => {
    print();
    // фича номер два это остановка потому что input поменялся - удобно ловить
    // хотя это можно было и в консоли делать
    debugger;
    env.setParam("output",input); // доп-фича - консоле-лог пропускает дальше данные
  });

  env.addCmd("apply",() => {
    print();
    debugger;    
  });
  
  env.addString("text");

  // фича номер раз это остановка просто потому что debugger есть
  print();
  debugger;
}

/*
export function feature_debugger( env )
{
  if (env.params.msg)
    console.log( env.params.msg );

  debugger;
}
*/

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

/* todo. и поработать что там за режим внутри модификатора. по идее все должно быть просто.
   интуитивно: some-modifier: feature { on ....; on ..... - и это как бы тело модификатора, применяется к цели получается }
*/   
// feature_on
export function on( env  )
{
  let host = env.host;

  env.feature("func");
  var u1 = () => {};
  //env.createLinkTo( {param:"name",from:"~->0",soft:true });

  //console.log("on: env on init", env.getPath() );

  //env.onvalues_any( ["name",0], connect );
  // типа надо без пропуска тактов..
  env.onvalue("name",(n) => connect(n));
  env.onvalue(0,(n) => connect(n));

  function connect(name,name0) {
    name ||= name0;

    u1();
    //console.log("on: subscribing to event" , name, env.getPath() )
    u1 = host.on( name ,(...args) => {
      //console.log("on: passing event" , name )
      //let fargs = [host].concat( args );
      // получается крышеснос
      env.callCmd("apply",...args);
      // идея - можно было бы всегда в args добавлять объект..
    })

    //console.log("on: connected",name,env.getPath())
    env.emit("connected");
  }
  env.on("remove",u1);
}


/// one-of
/// вход: index - номер
///       list,children - дети
/// one-of создает одного из детей согласно index
export function one_of( env, options )
{
  var created_envs = [];

  var activated=false;
  env.onvalues_any(["index","list"],(index) => {
    perform( index );
    activated=true;
  });
  //if (!activated) perform( 0 );

  //env.addString("condition_result");

  // далее натырено с репитера
  var children;
  env.restoreChildrenFromDump = (dump, ismanual) => {
    children = dump.children;
    if (typeof(pending_perform) !== "undefined") perform( pending_perform );
    return Promise.resolve("success");
  }

  var pending_perform;
  let created_num;
  var current_promise;

  function cleanup() {
    for (let old_env of created_envs) {
       env.emit("destroy_obj", old_env, created_num )
       old_env.remove();
     }
     created_envs=[];
     // где-то в процессе создания идет
     if (current_promise) current_promise.need_cancel=true;
  }
  env.on("remove",cleanup);

  function perform( num ) {
     cleanup();     

     let list = env.params.list || Object.values( children );

     if (!list) {
       pending_perform=num;
       return;
     }
     pending_perform=undefined;

     let edump;

     if (env.params.list)
     {
       edump = env.params.list[ num ];
     }
     else if (children)
     {
       var selected_c = Object.keys( children )[ num ];
       if (!selected_c) {
        return;
       }

       edump = children[selected_c];     
     }

     if (!edump) {
      pending_perform = num;
      return;
    }

     env.emit("pre_create_obj", edump, num );
     
     edump.keepExistingChildren = true; // но это надо и вложенным дитям бы сказать..

     let $scopeFor = env.$scopes.createAbandonedScope("generated by oneof " + env.$vz_unique_id);
     $scopeFor.$lexicalParentScope = env.$scopes.top();

     var p = env.vz.createSyncFromDump( edump,null,env.ns.parent,null,null,$scopeFor );
     current_promise = p;

     p.then( (child_env) => {
          if (p == current_promise)
              current_promise = null;

          if (p.need_cancel) {
            child_env.remove();
            return;
          }

          created_envs.push( child_env );
          env.emit("create_obj", child_env, num )
          created_num = num;
          env.setParam("output",child_env); // выдадим наружу созданное
          //console.log('ONEOF: created ',num,child_env)
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
  debugger;
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
       console.error("creator: got command but input is blank;", env);
       return;
     }
     let target = env.params.target; // можно будет на чилдрен переделать но пока так
     if (!target) {
       console.error("creator: got command but target is blank;", env);
       return;
     }

     if (!Array.isArray(input)) input=[input];
     
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

// действует как deploy_many но по команде apply
// и в отличие от creator - удаляет созданное в предыдущей apply
// вход - list, массив описаний
// а еще сделано для интереса что может получать аргументы чего делать - в команде
export function recreator( env, opts )
{
  env.onvalue("list",(input) => {
     //deploy_normal_env_all(input);
  });

  env.addCmd("apply",( arg_list=null ) => {
    //console.log("redeploy called",env.getPath())

    deploy_normal_env_all( arg_list || env.params.list );
  });

 // режим "repeater-mode" - развернуть всех в родителя (хотя может и можно не в родителя)
 var created_envs = [];
 function close_envs() {
     for (let old_env of created_envs) {
       old_env.remove();
     }
     created_envs = [];
 }
     
 let iteration = 0;    
 function deploy_normal_env_all(input) {

     iteration++;
     let my_iteration = iteration;

     //console.log("recreator: deploying",env.getPath(),"my_iteration=",my_iteration)

     env.emit("before_deploy", created_envs);
     close_envs();
     let parr=[];
     if (input && !Array.isArray(input)) input=[input]; // так
     if (!input) {
       env.setParam("output",[]);
       return;
     }

     //console.log("deploy_many: deploying", env.getPath())
     for (let edump of input) {
        let $scopeFor = env.$scopes.createAbandonedScope("generated by recreator"+env.$vz_unique_id);
        $scopeFor.$lexicalParentScope = env.$scopes.top();

        edump.keepExistingChildren = true; // но это надо и вложенным дитям бы сказать..
        var p = env.vz.createSyncFromDump( edump,null,env.ns.parent, edump.$name, null, $scopeFor );
        p.then( (child_env) => {
           if (my_iteration != iteration) {
             //console.log("recreator removing out of iter: ", child_env.getPath())
             child_env.remove(); // неуспела
             return;
           }
           created_envs.push( child_env );
        });
        parr.push(p);
     }
     Promise.all(parr).then( (values) => {
       if (my_iteration != iteration) 
         return;
       //console.log("deploy_many: emitting after_deploy",env.getPath())
       env.emit("after_deploy",values);
       // и еще такая шутка а там видно будет
       env.setParam("output",values);
     });
 }
 env.on("remove",close_envs)
}

// создает все объекты из поданного массива описаний input
// подключая их к родителю узла deploy_many
// тут кстати напрашивается сделать case - фильтрацию массива... ну и if через это попробовать сделать например...
// вариантов много получается...
// update - вроде как get достаточно в этом случае?
// выдает сигналы before_deploy( old_envs ) и after_deploy( new_envs )

export function deploy_many( env, opts )
{

  //console.log("deploy_many invoked", env.getPath())
  
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

     //console.log("deploy_many: deploying", env.getPath())
     for (let edump of input) {
        edump.keepExistingChildren = true; // но это надо и вложенным дитям бы сказать..
        var p = env.vz.createSyncFromDump( edump,null,env.ns.parent, edump.$name );
        p.then( (child_env) => {
           created_envs.push( child_env );
        });
        parr.push(p);
     }
     Promise.all(parr).then( (values) => {
       //console.log("deploy_many: emitting after_deploy",env.getPath())
       env.emit("after_deploy",values);
       // и еще такая шутка а там видно будет
       env.setParam("output",values);
     });
 }
 env.on("remove",close_envs)
}

// создает все объекты из поданного массива описаний
// подключая их к указанному узлу

// input - описание того что создаем
// target - куда вставляем
export function deploy_many_to( env, opts )
{

  // если поменялся только target - надо перенести созданные окружения в новый target
  // не пересоздавая их

  env.onvalue("input",(input) => {
     // дубликата не будет, если сначала зададут target а потом input
     // потому что в этом случае произойдет отсечение по пустому input
     // и только уже по приходу существующего input все произойдет
     deploy_normal_env_all( env.params.input, env.params.target );
  });

  env.onvalue("target",(target) => {
     // ничего не создавали еще? создадим
     if (created_envs.length == 0)
        return deploy_normal_env_all( env.params.input, env.params.target );
     // уже все создали? сменим родителя
     created_envs.forEach( (e) => target.ns.appendChild( e ) );
  });
  
  /* первая версия
  env.onvalues(["input","target"],(input,target) => {
     deploy_normal_env_all(input,target);
  });
  */

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

     if (!target) {
       env.setParam("output",[]);
       return;
     }

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

           if (env.params.extra_features) { // экспериментs
             for (let ef of env.params.extra_features)
               env.vz.importAsParametrizedFeature( ef, child_env );
           }

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

// эксперимент

export function insert( env )
{
  let unsub = env.onvalue("input",(i) => {
    unsub();

    if (i.hosted) {
       //env.setParam("input",i );
       env.feature("insert_features");
     }
     /*else if (env.ns.parent.feature_of_env) { // надо для "генерации"
        env.setParam("input",env.ns.parent.feature_of_env);
        env.feature("insert_features");
     }*/
     else {
        //env.setParam("input", i );
        env.feature("insert_children");
     }

  })
 /*
 if (env.feature_of_env) {
    env.setParam("input",env.feature_of_env);
    env.feature("insert_features");
 }
 else if (env.ns.parent.feature_of_env) { // надо для "генерации"
    env.setParam("input",env.ns.parent.feature_of_env);
    env.feature("insert_features");
 }
 else {
    env.setParam("input", env.ns.parent );
    env.feature("insert_children");
 }
 */
}

// работает как insert но на родителя / аттачед окружение.
// т.е. делает как бы для дедушки/бабушки.
// это получается потипу генератора
export function insert_siblings_to_parent( env )
{
 let exam_obj = env.ns.parent || env.host;

 if (exam_obj.hosted) {
    env.setParam("input",exam_obj.host);
    env.feature("insert_features");
 }
 else {
    env.setParam("input", exam_obj.ns.parent );
    env.feature("insert_children");
 }
}

export function insert_siblings( env )
{
 let exam_obj = env;

 if (exam_obj.hosted) {
    env.setParam("input",exam_obj.host);
    env.feature("insert_features");
 }
 else {
    env.setParam("input", exam_obj.ns.parent );
    env.feature("insert_children");
 }
}


//////////////// insert_features - добавляет процессы заданных фич в целевой процесс 
// новое видение deploy_features
// отличается тем что список фич это могут быть дети

// вход: input,0 - массив объектов для модификации
//       list,children - массив объекто фич, которые следует прицепить

export function modify( env )
{
  env.feature("insert_features");
}

// output: массив созданных фич
export function insert_features( env )
{
  var children;

  //console.log("modifier: init",env.getPath())
  //if (!env.hasParam(""))
  env.setParam("use_children",true);

  env.createLinkTo( {param:"input",from:"~->0",soft:true });

  let pending_perform;
  env.restoreChildrenFromDump = (dump, ismanual) => {
    // но вообще вопросов все больше получается..
    if (Object.keys( dump.children ) != 0) {
      children = dump.children;
      if (typeof(pending_perform) !== "undefined") {
         // но вообще это заодно еще и точка синхронизации
         // поэтому - вот определенеия из детей приехали и мы начинаем их выполнять
         // и скажем что все готово только когда их сделаем
         return perform( pending_perform );
      }
    }

    return Promise.resolve("success");
  }

  //let input_used;
  function perform() {

    let input = env.params.input || [];
    
    //console.log("modifier: perform",env.getPath(), input)
    /*
    if (input_used && input_used != input)
      console.log("modifier: input changed",env.getPath()," from",input_used,"to",input)
    input_used = input;
    */

    if (!Array.isArray(input)) input=[input]; // допускаем что не список а 1 штука
    let features = env.params.list;
    if (!features && env.params.use_children)
       features = Object.values(children || {});

    if (features.length == 0) {
      pending_perform = true;
      return;
    }
    pending_perform = false;

    let res = dodeploy( input, features );

    // todo надо итерации отслеживать
    res.then( () => {
       env.setParam("output",created_envs);
    });  

    return res;
  }

  function dodeploy( objects_arr, features_list ) {
     // ну тут поомтимизировать наверное можно, но пока тупо все давайте очищать
     close_envs();
     //debugger;
     //console.log("insert_features: ",env.getPath(),"objects_arr=",objects_arr,"features_list=",features_list)

     if (!features_list) return Promise.resolve("no_features");

     if (!Array.isArray(features_list)) {
      console.error("insert_features: features_list is not array!",features_list);

      return Promise.resolve("features are not array");;
     }

     let to_deploy_to = objects_arr;

     let promarr = [];

     let ii=0;
     //console.log("modifier: unrolling",env.getPath(), to_deploy_to, features_list)

     for (let tenv of to_deploy_to) {
      let $scopeFor = env.$scopes.createAbandonedScope( "generated by insert_features "+tenv.$vz_unique_id );
      $scopeFor.$lexicalParentScope = env.$scopes.top();

      for (let rec of features_list) {
        //console.log("insert_features is deploying",rec,"to",tenv.getPath())

        // сообщим и тем что они фичи енвы..
        // но это не сработает кстати на детей детей.. ех
        //rec.feature_of_env = env.host;

        rec.lexicalParent = env;
        let np = env.vz.importAsParametrizedFeature( rec, tenv, $scopeFor );
        promarr.push( np );
        let my_ii = ii;
        let my_tenv = tenv;
        np.then( new_feature_env => {
          new_feature_env.setParam( "objectIndex",my_ii);
          new_feature_env.setParam( "host",my_tenv); // ну или .input я не знаю
          //new_feature_env.setParam( "input",my_tenv);

          //child_env.setParam("host") 
          created_envs.push( new_feature_env );

          // делаем идентификатор для корня фичи F-FEAT-ROOT-NAME
          // todo тут надо scope env делать и детям назначать, или вроде того
          // но пока обойдемся так
          new_feature_env.$env_extra_names ||= {};
          new_feature_env.$env_extra_names[ new_feature_env.$feature_name ] = true;
        })


      };
      ii++;
     };

     return Promise.allSettled( promarr );
  }

 var created_envs = [];
 function close_envs() {
   for (let old_env of created_envs) {
     old_env.remove();
   }
   created_envs = [];
 }

 env.on("remove",close_envs)

 if (env.hosted) {
    if (env.hasParam("input")) // || env.hasLinksToParam("input"))
    { 
       //console.log("hosted modifier has input",env.getPath())
    }
    else
    {
      //console.log("hosted modifier has NO input",env.getPath(), "setting host", env.host.getPath()) 
      // интересно а если input это ссылка? которая еще не отработала..
      // и которая еще даже не установилась.. (т.к. link-объекты создаются позже..)

      // так-то вообще тупняк.. ждать?.. так ссылка может долго устанавливаться..
      //debugger;
      env.setParam("input",env.host);
    }
 }

 env.onvalues_any(["input","list"],perform);

}

//////////////// insert_children
// новое видение deploy_many_to
// отличается тем что список фич это могут быть дети

// вход: input,0 - массив объектов для модификации
//       list,children - массив описаний объектов, которые следует прицепить
// output: массив созданных объектов

// единственное но - эту вещь сложно оптимизировать, тут 2д матрица потому что.
// может ее лучше реализовать как repeater { |obj| @list | repeater { |f| create-object f parent=@obj } }
// ну единственное будет дороговато.. но попробовать можно, да.
export function insert_children( env )
{
  var children = {};
  var created_envs = [];

  env.feature("delayed");
  let dodeploy_d = env.delayed(dodeploy,4); // опытным путем перебираем, 2 вроде норм.. можно 4 или 5 еще
  //let dodeploy_d = dodeploy;

  env.setParam("use_children",true);
  env.setParam("active",true);

  env.feature( "param_alias");
  env.addParamAlias( "input", 0 );
  //env.createLinkTo( {param:"input",from:"~->0",soft:true });

  env.restoreChildrenFromDump = (dump, ismanual) => {
    children = dump.children;
    if (typeof(pending_perform) !== "undefined") perform( pending_perform );
    return Promise.resolve("success");
  }
  
  //env.onvalues_any(["input","list","active"],perform);
  // ну все-равно там на проходе создания ничего толком нет (параметры еще не выставлены)
  // а и опять же надо дать шанс active пересчитаться если он формула
  env.monitor_values(["input","list","active"],perform);

  

  function perform() {
    //console.log("inserT_children: perform called", env.params, env.getPath())
    let input = env.params.input || [];
    if (!Array.isArray(input)) input=[input]; // допускаем что не список а 1 штука
    let features = env.params.list;
    let using_children = false;
    
    if (!features && env.params.use_children) {
       features = Object.values(children || {});
       using_children = true;
    }

    if (features && !Array.isArray(features)) features = [features];

    dodeploy_d( input, features, using_children );
  }

  function dodeploy( objects_arr, features_list, using_children ) {
     
     // ну тут поомтимизировать наверное можно, но пока тупо все давайте очищать
     // todo optimize! но сначала померять часто ли эта фигня и скоко времени занимаетs

     close_envs();
     //debugger;

     if (!env.params.active) return;

     if (!features_list) return;

     if (!Array.isArray(features_list)) {
      console.error("insert_children: features_list is not array!",features_list);

      return;
     }

     let to_deploy_to = objects_arr;

     let parr = []

     let ii=0;

     function create_scope_for_item(tenv) {
      let $scopeFor = tenv.$scopes.createAbandonedScope("created by insert_children "+env.$vz_unique_id);
       if (using_children)
           $scopeFor.$lexicalParentScope = env.$scopes.top();
       if (env.$use_scope_for_created_things)
           $scopeFor.$lexicalParentScope = env.$use_scope_for_created_things;

       return $scopeFor;
     };

     for (let tenv of to_deploy_to) {
      let $scopeFor = create_scope_for_item(tenv);
      let prev_dump_personal_scope;

      // todo чистить надо или само?

      for (let edump of features_list) {
          if (!edump) {
            console.warn("insert_children: empty feature in list",features_list, env.getPath())
            continue; // бывает пустое присылают..
          }

          // важная добавка - некоторые дампы содержат свой scope взятый у родителя
          // а создаваемое таки должно жить в своем scope а не в родительском но помнить о нем

          // дополнительно, в insert-childen list идет двух видов - как значение аттрибута { ... }
          // и тогда там у всех должен быть один общий скоп
          // или как синтезированный массив, и тогда у каждой должен быть индивидуальный скоп..

          if (edump.$scopeFor) {
             if (prev_dump_personal_scope && prev_dump_personal_scope!== edump.$scopeFor)
             {
                // признак того что этот дамп синтезированный, и сообразно надо ему индивидуальный scope иметь
                $scopeFor = create_scope_for_item(tenv); 
             }

             $scopeFor.$lexicalParentScope = edump.$scopeFor;  
             $scopeFor.skip_dump_scopes = true; // это апи createSyncFromDump..
             prev_dump_personal_scope = edump.$scopeFor;
          };

          if (env.params.manual) {
            edump.manual = true;
            edump.params.manual_features = Object.keys( edump.features ).filter( (f) => f != "base_url_tracing");
          }

          edump.keepExistingChildren = true; // но это надо и вложенным дитям бы сказать..
          var p = env.vz.createSyncFromDump( edump,null,tenv, edump.$name, env.params.manual, $scopeFor );
          p.then( (child_env) => {

             if (env.removed) { // возможно insert-children уже удален
               child_env.remove();
               return;
             }

             created_envs.push( child_env );

             if (env.params.manual) child_env.manuallyInserted = true;
          });
          parr.push(p);
       }
      ii++;
     };

     Promise.all(parr).then( (values) => {
       env.emit("after_deploy",values);
       // выдаем все что создали
       env.setParam("output",values);
     });

  }; // perform


 
 function close_envs() {
   for (let old_env of created_envs) {
     //console.log('issuing remove for',old_env)
     old_env.remove();
   }
   created_envs = [];
 }

 env.on("remove",close_envs)

}

/////////////////////////// новые геттеры с новым дизайном

// получается лучше все-таки явно, get_param, get_child и т.п. чем по аргументам разруливать..
// идея сделать такой вариант get_param который бы работал как map но изменял результат при смене параметров
// делаем и эту идею. пока впишем сюда же
export function get_param( env )
{
  let param_tracking = () => {};

  env.feature("delayed");

  env.createLinkTo( {param:"name",from:"~->0",soft:true });

  /* все-таки надо так:
     let delayed = env.load("delayed");
     потому что это про особый функционал, а не про особенность..
     можно даже наверное сказать - ну пусть оно методы биндит если хочет внутрь возвращаемого значения
     я уверен скоро разберусь с этим.. это явно не фичи и не надо им методы вмешивать в..
     в других случаях наверное надо. но не в подобном этом
  */
  let source_param_changed_d = env.delayed(source_param_changed);

  function source_param_changed (input,param) {
    
    
    /*
    if (Array.isArray(input))
    {
      let acc = [];
      let accf = [];
      param_tracking();

      for (let i=0; i<input.length; i++) {
        let v = input[i]?.getParam ? input[i].getParam( param ) : undefined;
        acc.push( v );
        let f = input.trackParam( param,() => {
          source_param_changed_d( input, param );
        } );
        accf.push( f );
        param_tracking = () => {
          accf.forEach( (u) => u() );
        }
      }

      env.setParam("output",v );
    }
    else
    {
      */
      let v = input?.getParam ? input.getParam( param ) : undefined;
      v ||= env.params.default;
      env.setParam("output",v );

      param_tracking();
      param_tracking = input.trackParam( param,() => {
        source_param_changed( input, param );
      } );
    //}
  }
  env.on("remove",param_tracking);

  env.onvalues(["input","name"],source_param_changed);
};

// решил раздельно
// на вход получает массив объектов и имя параметра который из них вытащить
export function map_param( env )
{
  let param_tracking = () => {};

  env.feature("delayed");
  /* все-таки надо так:
     let delayed = env.load("delayed");
     потому что это про особый функционал, а не про особенность..
     можно даже наверное сказать - ну пусть оно методы биндит если хочет внутрь возвращаемого значения
     я уверен скоро разберусь с этим.. это явно не фичи и не надо им методы вмешивать в..
     в других случаях наверное надо. но не в подобном этом
  */
  let source_param_changed_d = env.delayed(source_param_changed);

  function source_param_changed (input,param) {
    if (Array.isArray(input))
    {
      let acc = [];
      let accf = [];
      param_tracking();

      
      for (let i=0; i<input.length; i++) {
        let v = input[i]?.getParam ? input[i].getParam( param ) : undefined;
        v ||= env.params.default;
        acc.push( v );

        if (!input[i]) continue;

        let f = input[i].trackParam( param,() => {
          source_param_changed_d( input, param );
        } );
        accf.push( f );
        param_tracking = () => {
          accf.forEach( (u) => u() );
        }
      }

      env.setParam("output",acc );
    }
    else
    {
      env.setParam("output",[] ); 
    }
  }
  env.on("remove",param_tracking);

  env.onvalues_any(["input","name",0],(input,name,name0) => source_param_changed( input, name||name0 ));
}


export function get_child( env )
{
  let param_tracking = () => {};

  function source_param_changed (input,name) {

    let v = input ? input.ns.childrenTable[ name ] : undefined;

    env.setParam("output",v );

    param_tracking();
    param_tracking = input.on("childrenChanged",source_param_changed );
    // todo тут надо delayed на случай если там много детей будут пачками добавляться
    // и еще надо ренейм у детей ловить, name_changed
  }
  env.on("remove",param_tracking);

  env.onvalues(["input","name"],source_param_changed); 
}

export function get_parent( env )
{
  let param_tracking = () => {};

  function source_param_changed (input) {

    let v = input ? input.ns.parent : undefined;
    env.setParam("output",v );
    param_tracking();
    param_tracking = input.on("parent_change",source_param_changed );
    // todo тут надо delayed на случай если там много детей будут пачками добавляться
    // и еще надо ренейм у детей ловить, name_changed
  }
  env.on("remove",param_tracking);

  env.onvalues(["input"],source_param_changed); 
}

//////////////// get
// плохой дизайн - реагировать в зависимости от аргумента...
// плох тем что у меня где-то есть get_param и я не могу его заменить на get здесь...

export function get( env ) {
  let param_tracking = () => {};
  console.warn("warning! obsolete get called", env.getPath());
  env.vz.console_log_diag( env );

  env.createLinkTo( {param:"name",from:"~->0",soft:true });

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

  env.onvalues(["input","childnum"],(input,param) => {
    let v = input ? input.ns.getChildren()[ param ] : undefined;
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
// т.е. все из obj.params копирует в качестве аксессоров в obj
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
      env.setParam("output", [...senv.ns.children] );
    });
    
    env.setParam("output", senv.ns.children );
  })
  env.on("remove",() => unsub());
}

// для совместимости по именам
export function is_feature_applied(env)
{
  env.feature("has_feature");
}

// проверяет есть ли фича у input
// input, name
export function has_feature(env) {
  let unsub=()=>{};

  env.onvalues(["input","name"],(senv,name) => {
    let res = senv.is_feature_applied(name);
    env.setParam("output",res);

    unsub = senv.on("feature-applied-"+name,() => {
      env.setParam("output",true);
    });
  });

  env.on("remove",unsub);
}

// добавляет фичу. пока только в host
// но зато можно много фич: {{ add_feature "alfa beta "}}
export function add_feature(env) {

  env.createLinkTo( {param:"name",from:"~->0",soft:true });

  env.onvalues(["name"],(name) => {
    debugger;
    env.host.feature( name );
  });

  env.on("remove",() => {
    env.host.unfeature( name );
  })

}

export function pass_input(env){
  env.onvalue("input",(i) => {
    env.setParam("output",i);
  })
};

// эдакий иф для пайпа.. но вообще найти бы общее между этим всем..
// ну и он значения передает, не окружения...
export function pass_input_if(env){
  env.onvalues_any(["input",0],(i,cond) => {
    if (cond)
       env.setParam("output",i);
    else
       env.setParam("output", env.params.default );
  })
};

// модификатор
export function force_dump(env) {
  env.on("attach",(obj) => {
      obj.params.force_dump=true;
  });
}

// это надо для хаков иногда.. см применение в коде найди
export function attach_scope(env) {
  env.onvalues( [0,1], (scopeobj, level) => {
    env.host.$scopes.addScopeRef( scopeobj.$scopes[ scopeobj.$scopes.length + level])
  });
}


// вход: input описание в стиле { |args| .... }, и позиционные аргументы
// выход: output - результат работы созданного окружения
// действие - разворачивает окружение согласно описанию, передает в него позиционные параметры
// идея - если вход не описание, то возвращать прям его. это автоматизация некая.
// идея - пробовать работать с children ...

// замысел этой штуки - разворачивать процессы описанные в { |a b c| ... }-параметрах с аргументами
export function computing_env_orig(env){

  // соединяет позиционные аргументы computing_env с ||-аргументами scope
  function fill_scope_with_args(newscope,attrs) {
    for (let i=0; i<attrs.length;i++)
    {
        let argname = attrs[i];
        console.log('fill_scope_with_args: argname=',argname,'i=',i)
        let cell = env.get_cell(i);
        newscope.$add( argname, cell );
    };
  };

  let cleanup = () => {};
  env.on("remove",() => cleanup());

  ///// учимся реагировать на чилдренов
  // хотя подход странный - перешибает input..
  let children;
  env.restoreChildrenFromDump = (dump, ismanual, $scopeFor) => {
    children = dump.children;
    // todo еще - мы не умеем у чилдренов хранить список аргументов, как это не печально.
    // и вооще они не массив, что тоже печально, а хеш
    env.setParam("input", Object.values(children));
    return Promise.resolve("success");
  };
  /////  

  env.onvalue("input",(env_list) => {
    cleanup();

    //if (!env_list?.env_args)
    if (!(Array.isArray(env_list) && env_list.length > 0 && env_list[0].features))
    {
      console.log("wrong argument to computing_env", env_list)
      return;
    }

    let newscope = env.$scopes.createAbandonedScope("computing_env");
    newscope.$lexicalParentScope = env_list[0].$scopeFor;
    if (env_list.env_args)
      fill_scope_with_args( newscope, env_list.env_args.attrs );

    // прошить им всем доступ в эту скопу.. странно все это, 
    // ибо зачем тогда scope-аргумент в createObjectsList .. но ладно.. взято из callEnvFunction

    newscope.skip_dump_scopes = true;
    /*
    if (env_list[0].$scopeFor)
      for (let e of env_list)
          e.$scopeFor = newscope;
    */

    let spawn_obj = env.vz.createObj( { parent: env, name: "spawn" });
    cleanup = () => { spawn_obj.remove(); cleanup = () => {}; }

    let p = env.vz.createObjectsList( env_list, spawn_obj, false, newscope );

    p.then( () => {
      if (spawn_obj.removed) {
        //objects.forEach( obj => obj.remove() )
        return;
      }

      spawn_obj.ns.getChildren()[0].onvalue("output",finish);
      function finish( res ) {
        env.setParam("output",res);
      }
    });    
  });
};

////////////// дубликат computing env работающий с чилдренами
export function computing_env(env){

  // соединяет позиционные аргументы computing_env с ||-аргументами scope
  function fill_scope_with_args(newscope,attrs) {

    let has_input = (env.hasParam("input") || env.hasLinksToParam("input"));

    for (let i=0; i<attrs.length;i++)
    {
        let argname = attrs[i];
        //console.log('fill_scope_with_args: argname=',argname,'i=',i)
        let cell;
        if (has_input)
        {
          if (i == 0)
            cell = env.get_cell("input");
          else
            cell = env.get_cell(i-1);
        }
        else
        {
          cell = env.get_cell(i);
        }
        let locali = i;
        /*
        cell.on('assigned',(q) => {
          console.log('computing env see agr cell change',locali, attrs[locali],q)
        });
        */
        newscope.$add( argname, cell );
    };
  };

  let cleanup = () => {};
  env.on("remove",() => cleanup());

  ///// учимся реагировать на чилдренов
  // хотя подход странный - перешибает input..
  let children_env_list;

  env.restoreChildrenFromDump = (dump, ismanual, $scopeFor) => {
    children_env_list = Object.values( dump.children );
    if (children_env_list.length == 0)
    {
      children_env_list = null;
      env.onvalue("code",fn ); // когда появится code или если есть сейчас - действуем
    }
    else {
      children_env_list.env_args = dump.children_env_args;
      //if (env.hasParam("input") || env.hasLinksToParam("input"))
      fn(); // поехали с орехами..
    }
        
    return Promise.resolve("success");
  };
  /////  
  

  function fn () {
    cleanup();

    let env_list = children_env_list || env.params.code;

    //if (!env_list?.env_args)
    if (!(Array.isArray(env_list) && env_list.length > 0 && env_list[0].features))
    {
      // console.log("wrong argument to computing_env", env_list, env.getPath(), env)
      return;
    }

    let newscope = env.$scopes.createAbandonedScope("computing_env");
    newscope.$lexicalParentScope = env_list[0].$scopeFor;
    newscope.skip_dump_scopes = true;

    if (env_list.env_args)
      fill_scope_with_args( newscope, env_list.env_args.attrs );

    // прошить им всем доступ в эту скопу.. странно все это, 
    // ибо зачем тогда scope-аргумент в createObjectsList .. но ладно.. взято из callEnvFunction

    
    /*
    if (env_list[0].$scopeFor)
      for (let e of env_list)
          e.$scopeFor = newscope;
    */

    let spawn_obj = env.vz.createObj( { parent: env, name: "spawn" });
    cleanup = () => { spawn_obj.remove(); cleanup = () => {}; }

    let p = env.vz.createObjectsList( env_list, spawn_obj, false, newscope );

    p.then( () => {
      if (spawn_obj.removed) {
        //objects.forEach( obj => obj.remove() )
        return;
      }

      spawn_obj.ns.getChildren()[0].onvalue("output",finish);
      function finish( res ) {
        env.setParam("output",res);
      }
    });    
  };
};

// временная вариация на тему
// вход: input - описание
//       позиционные аргументы - пойдут на вход scope согласно описанию
// выход: output - список созданных объектов
export function create_objects(env){

  // соединяет позиционные аргументы computing_env с ||-аргументами scope
  function fill_scope_with_args(newscope,attrs) {
    for (let i=0; i<attrs.length;i++)
    {
        let argname = attrs[i];
        let cell = env.get_cell(i);
        newscope.$add( argname, cell );
    };
  };

  let cleanup = () => {};
  env.on("remove",() => cleanup());

  env.onvalue("input",(env_list) => {
    cleanup();

    //if (!env_list?.env_args)
    if (!(Array.isArray(env_list) && env_list[0].features))
    {
      console.log("wrong argument to computing_env", env_list)
      return;
    }

    let newscope = env.$scopes.createAbandonedScope("computing_env");
    newscope.$lexicalParentScope = env_list[0].$scopeFor;
    if (env_list.env_args)
      fill_scope_with_args( newscope, env_list.env_args.attrs );

    // прошить им всем доступ в эту скопу.. странно все это, 
    // ибо зачем тогда scope-аргумент в createObjectsList .. но ладно.. взято из callEnvFunction

    newscope.skip_dump_scopes = true;
    /*
    if (env_list[0].$scopeFor)
      for (let e of env_list)
          e.$scopeFor = newscope;
    */

    let spawn_obj = env.vz.createObj( { parent: env, name: "spawn" });
    cleanup = () => { spawn_obj.remove(); cleanup = () => {}; }

    let p = env.vz.createObjectsList( env_list, spawn_obj, false, newscope );

    p.then( () => {
      if (spawn_obj.removed) {
        return;
      }
      

      env.setParam("output",spawn_obj.ns.getChildren());
      
    });    
  });
};

// F_PARAM_EVENTS
// прицепляет параметры on_ как обработчики событий
// idea - только зарегистрированные параметры, а остальным отлуп
export function connect_params_to_events(env) {
  env.on("param_changed",f);

  let bound_vars = {};
  function f(n,v,msg) {
    if (!n.startsWith("on_")) return;

    if (bound_vars[n]) bound_vars[n]();

    let event_name = n.substring(3);

    //console.log("connect_params_to_events: connecting to event",event_name,env.getPath())

    bound_vars[n] = env.on(event_name,(...args) => {
      let code = env.params[n];
      if (code.bind) {
          code.apply( env, args );
      } 
    });
  }

  for (let k of env.host.getParamsNames()) {
    f(k,env.host.getParam(k));
  }

  // очищать вроде не надо - объект же на свои параметры зацеплен

}