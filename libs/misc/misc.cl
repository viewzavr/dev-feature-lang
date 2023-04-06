// map { |x| @x + 2 }
// map в теле надо указать 1 объект у которого будет output
feature "map" {
  r: repeater 
      use_outer_scope = true
      output_param="output_objects"  // указываем репитеру писать результат тудысь
      output=(read @r.output_objects | map-geta "output")
}

// input,0 - путь к параметру вида objnamepath->param
feature "read-param" {
  q: object
    input=@.->0
    splitted = (m_eval "(str) => str.split('->')" @q->input)
    objpath=(@q->splitted | geta 0)
    paramname=(@q->splitted | geta 1)
    output=(find-one-object input=@q->objpath | geta @q->paramname default=@q->default?)

  ;
};

feature 'else' "
  env.feature('catch-children')

  let p = env.ns.parent
  let cc = p.ns.getChildren();
  let ind = -1
  for (let i=0; i<cc.length; i++ ) {
    let c = cc[i];
    if (c == env)
    {
        ind = i
        break
    }
  }
  if (ind >= 1) {
    let fif = cc[ ind-1 ];
    // будем пока всегда - у нас разваливается постепенное восстановление.. (if еще может фича не применена изза ожидания оргумента)
    env.onvalue('children_list', (cl) => fif.setParam('else',cl))
    if (fif.is_feature_applied('if'))
    {
      //fif.setParam( 'else')
      //env.onvalue('children_list', (cl) => fif.setParam('else',cl))
    }
    else {
      // console.warn('else: previous statement is not if')
      // env.vz.console_log_diag( env );
    }    
  }
  else
  {
    if (ind < 0) {
      console.warn('else: could not find self in parent statements')
      env.vz.console_log_diag( env );                
    }
    else {
      console.warn('else: statement is first in parent',ind)
      env.vz.console_log_diag( env );                
      console.log('children:')
      cc.forEach( c => console.log(c))
    }
  }
"

feature "if" 
code2="
  let cnt=0;
  env.on('appendChild',(c) => {
    if (cnt == 0)
    {
      // важный момент
      // -2 это выход наружу if, на внешний скоп.. пипец..

      c.$use_scope_for_created_things = env.$scopes[ env.$scopes.length -2 ];
    }
    cnt++;
    if (cnt > 1 
        && c.ns.name !== 't' && c.ns.name.indexOf('arg_link_to')<0 // тупняк конечно - чтобы разрешить условия вида if @alfa
        )
      console.warn('if: extra children found!',c.getPath());
  });
"
{
   // catch-children 'then' keep_existing=true
   // эксперимент - пуст if возвращает output первого созданного окружения (опять..)
   // или как вариант всегда создадим на их основе computing env. но может и не получится - замысел if-а в т.ч.
   // это создавать окружения для родителя

   // получается someobj: object alfa=(if ... { expr } else { expr } ) будут плодить объекты в object.. ну ваще.. 

  i: object output=@t.output.0.output? {{    
      catch-children 'then' if_not_empty=true

      m_eval "(env, c) => {
        // -2 это выход наружу if, на внешний скоп.. пипец..
        c.$use_scope_for_created_things = env.$scopes[ env.$scopes.length -2 ];
      }" @i @t

      t: insert_siblings_to_parent // вставить соседей i (т.е. детей родителям i)
       list=(eval @i @i->0? @i->then? @i->else? @i allow_undefined=true
             code="(if_env, cond,t,e,env) => {
               //console.log('if tick, cond=',cond,'then=',t,'else=',e)
               /* щас не так актуально. а получается бывает t еще не вычислено
               if (cond && !t) {
                    console.error('if: no then section!');
                    env.vz.console_log_diag( env );
                    console.log( if_env.params )
               }
               */
               // если вычисления еще не было то лесом выходим ничего не делаем..
               if (!if_env.hasParam(0))
               { 
                //console.log('if exiting, no param 0')
                return null;
               }

               return cond ? t : e
             };");
    }};
};

/*
feature "timeout_insert_siblings" code=`
  env.onvalue( 0, (tm) => {
    env.feature("timeout");
    env.timeout( () => {
      env.setParam("active",true);
    }, tm );
`
{
  insert_siblings active=false;
};
*/

// по прошествии таймаута, указанного в аргументе, выставляет true в output
// а еще есть pause_input
feature "timeout" code=`
  let unsub=() => {}
  env.on('remove',() => unsub() )
  env.onvalue( 0, (tm) => {
    env.feature("delayed");
    unsub=env.timeout( () => {
      env.setParam("output",true);
    }, tm );
  })`;

feature "timeout-ms" `
  let unsub = () => {}
  env.feature("delayed");
  env.onvalue( 0, run) 
  env.on('restart',() => {
   if (env.params[0])
      run( env.params[0] )
  })
 
 
 function run(tm) {
    unsub()
    env.setParam('output',false)
    unsub = env.timeout_ms( () => {
      env.setParam("output",true);
    }, tm );
 }
 
 env.on('remove',() => unsub() )
`;

// выдает чиселку в аутпут, начиная с 0 и увеличивая на каждом тике
// аргумент 0 - задержка (мс)
feature "timer-ms" `
  let unsub = () => {}
  env.setParam('output',0)
  env.feature("delayed");
  env.onvalue( 0, run )
  env.on('restart',() => {
   env.setParam('output',0)
   if (env.params[0])
      run( env.params[0] )
  })

 function run(tm) {
    unsub()
    unsub = env.timeout_ms( () => {
      env.setParam("output", env.params.output + 1);
      run( tm ) // todo repeat
    }, tm );
 }
 
 env.on('remove',() => { unsub() } )
`;

// todo optimize сейчас появился прямой апи в браузерах
feature "get_query_param" `
    function getParameterByName(name) {
      name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
      var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
        results = regex.exec(location.search);
      //return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
      return results === null ? null : decodeURIComponent(results[1].replace(/\+/g, " "));
    }

    env.onvalue("name",(name) => {
      var v = getParameterByName(name);
      env.setParam("output",v);
    });
`

register_feature name="fill_parent" {
  object style="position: absolute; width:100%; height: 100%; left: 0px; top: 0px;";
};

register_feature name="below_others" {
  object dom_style_zIndex=-1;
};


// идея что оно получает input и команду apply?
// или просто input? и как поменялся - выдаем файл?

// downloads specified file to a users browser
// inputs: 
//  * input - text content,  
//  * filename - filename
// when input changed, a new file is downloaded

/*
  button {
    func {
      sv1: generate_svg input=@..->input;
      download_file_to_user filename="kartina.svg" input=@sv1->output;
    };
  };
*/

register_feature name="download_file_to_user" {
  js code=`
      // https://stackoverflow.com/a/30832210
    // Function to download data to a file
    function download(data, filename, type) {
        var file = new Blob([data], {type: type});
            var a = document.createElement("a"),
                    url = URL.createObjectURL(file);
            a.href = url;
            a.download = filename;
            document.body.appendChild(a);
            a.click();
            setTimeout(function() {
                document.body.removeChild(a);
                window.URL.revokeObjectURL(url);
            }, 0);
    }

    // это у нас синхро-сигнал
    env.onvalue("input",(input) => {
      if (!input || input.length == 0) {
        console.error("download_file_to_user: input is empty")
        return;
      }
      console.log("download_file_to_user: downloading");

      download( input, env.params.filename || "file")
    });
  `;
};


// мониторит указанные параметры params во входном массиве объектов input
// output равен входному массиву
// меняет свой output при обнаружении изменений
// вход: input - массив объектов
//       params - массив имен параметров. 

// таким образом происходит продвижение по пайп-цепочке при изменении указанных параметров 
// в каком-нибудь из input-объектов

// пример: find-objects ... | monitor-params params=["alfa","beta"] | console_log;

register_feature name="monitor_params" {
  js code=`
    let unsub_arr = [];
    let unsub_func = ()=> { unsub_arr.forEach( (f)=>f() ); unsub_arr=[]; }

    env.feature("delayed");
    let sig_d = env.delayed( sig );

    env.onvalues(["input","params"],(arr,params) => {
      unsub_func();
      //if (!arr) return;
      //if (!Array.isArray(arr)) arr = [arr];

      for (let cenv of arr) {
        let cunsub = cenv.onvalues( params, sig_d );
        unsub_arr.push( cunsub );
      };
      sig_d();
    });

    env.on("remove",unsub_func);

    function sig() {
      //let arr = env.params.input;
      //if (Array.isArray( env.params.input ))
      env.setParam("output", env.params.input.slice() );
    }
  `;
};

// аналог monitor_params но мониторит все параметры.

register_feature name="monitor_all_params" {
  js code=`
    let unsub_arr = [];
    let unsub_func = ()=> { unsub_arr.forEach( (f)=>f() ); unsub_arr=[]; }

    env.feature("delayed");
    let sig_d = env.delayed( sig );

    env.onvalue("input",(arr) => {
      unsub_func();
      for (let cenv of arr) {
        let cunsub = cenv.on("param_changed", sig_d)
        unsub_arr.push( cunsub );
      };
      sig_d();
    })

    env.on("remove",unsub_func);

    function sig() {
      env.setParam("output", env.params.input.slice() );
    }
  `;
};


feature "pause_input" {: env |
  env.feature("delayed");
  let pass = env.delayed( () => {
    env.setParam("output", env.params.input);
  }, env.params[0] || (1000/30) ); // мобуть задержка на пару тактов.. или секунд?

  env.onvalue("input",pass);
:}

feature "restart_input" code=`
  //env.bind_cells( "input","output" );
  env.onvalue("input",(v) => {
    env.setParam("output",v);
  });

  env.onvalue(0,(tick) => {
    let v = env.params.input;
    if (Array.isArray(v)) v = [...v];
    env.setParam("output",v);
  });

  env.setParam("output", env.params.input )
`;

feature "joinlines" code=`
  env.on("param_changed",(name) => {
    if (name == "output") return;
    compute();
  });
  
  function compute() {

    let count = env.params.args_count;
    let arr = [];
    for (let i=0; i<count; i++)
      arr.push( env.params[ i ] );
    let res = arr.join( env.params.with || "\\n" ); // по умолчанию пустой строкой
    env.setParam("output",res );
  };
  
  compute();
`;


// F-SCOPE-PARAMS
// теперь у нас data юзается еще и чтобы именованные параметры пихать в scope
// решил назвать var. еще было вариант cell но там сложно - get-cell-value, alfa->cell и это cell они ж все разные
// посему пока var
// но вместе с var сложно такое мыслить: var a = import_js(...); лучше уж let a = ...;
feature "let" {: env | 
  // NHACK - на первом проходе в register_feature для js скоп еще не создан
  let $scopeFor = env.$scopes [env.$scopes.length-1]; 

  function forget_param (name,value) {
      if ($scopeFor[ name ]) 
       if ($scopeFor[ name ].created_by_data_env === env)
         $scopeFor.$forget( name );
  }

  function process_param (name,value) {
    if (Number.isInteger(parseFloat(name)) || name == "args_count")
      return;

    //let $scopeFor = env.$scopes [env.$scopes.length-2]; 

    if ($scopeFor[ name ]) {
       // тут варианты
       // может это мы ранее сами добавляли
       // а может другое имя
       // а если другое - то может мы можем перезатереь и это даж хорошо
       if ($scopeFor[ name ].created_by_data_env === env)
       // все хорошо это мы - ничего не делаем
       {

       }
       else // поругаемся но мб в будущем что-то другое
       console.error("scopes: data param duplicated name!",name,'me=',env,'cell ',name,'existing=',$scopeFor[ name ])
       //if (dump.locinfo)
       //    console.log( dump.locinfo );
    }
    else
    {
      let cell = env.get_cell(name);
      cell.created_by_data_env = env;
      $scopeFor.$add( name, cell );
      //console.log("data: added name to scope",name,$scopeFor)
    }

    //console.log('pc',name, env.$scopes [env.$scopes.length-2] );
  };
  //console.log("LET init",env.params)

  // будем реагировать на будущие изменения
  env.on('param_changed',process_param );

  // и на то что есть сейчас
  for (let k of env.getParamsNames()) {
    process_param( k, env.getParam(k));
  };
  let linked_params = env.getLinkedParamsNames();
  for (let k of linked_params) {
    if (!env.hasParam( k )) // потому что уже обработали..
       process_param( k, env.getParam(k)); 
       // todo дык его еще не назначили, чего там null то писать.. или ошибки в скопе будут?
       // или норм там все.. короче наша задача не делать вид что значение присвоено, если оно еще не присвоено
       // это связано с todo 60-й строки mike.js QQQ
  };

  env.on("remove",() => {
    for (let k of env.getParamsNames()) {
      forget_param( k );
    };
  });

:}
{
  data: object output=@data->0?;
};

// add-to-scope name=имя value=значение
// идея - мб совместить с let. т.е. let __name=.. __value=...
feature "add-to-scope" {: env | 
  // NHACK - на первом проходе в register_feature для js скоп еще не создан
  let $scopeFor = env.$scopes [env.$scopes.length-1]; 

  function forget_param (name,value) {
      if ($scopeFor[ name ]) 
       if ($scopeFor[ name ].created_by_data_env === env)
         $scopeFor.$forget( name );
  }

  function process_param (name,value) {
    if (Number.isInteger(parseFloat(name)) || name == "args_count")
      return;

    //let $scopeFor = env.$scopes [env.$scopes.length-2]; 

    if ($scopeFor[ name ]) {
       // тут варианты
       // может это мы ранее сами добавляли
       // а может другое имя
       // а если другое - то может мы можем перезатереь и это даж хорошо
       if ($scopeFor[ name ].created_by_data_env === env)
       // все хорошо это мы - ничего не делаем
       {

       }
       else // поругаемся но мб в будущем что-то другое
       console.error("add-to-scope: data param duplicated name!",name,'me=',env,'cell ',name,'existing=',$scopeFor[ name ])
       //if (dump.locinfo)
       //    console.log( dump.locinfo );
    }
    else
    {
      let cell = env.get_cell(name);
      cell.created_by_data_env = env;
      $scopeFor.$add( name, cell );
      //console.log("data: added name to scope",name,$scopeFor)
    }

    //console.log('pc',name, env.$scopes [env.$scopes.length-2] );
  };
  //console.log("LET init",env.params)

  env.monitor_defined( ["name","value"], (a,b) => process_param( a,b ))

  env.on("remove",() => {
    forget_param( env.params.name );
  });

:}

// func "foo" {: a b | return a + b :}
// console-log (foo 1 2)
// func занято, поэтому jsfunc

// update это ж вообще не func получился. а некая запускалка вычислений...
// и результатом применения func здесь является - именно что результат вычислений. а не например функция.
// т.е. не получится сказать что-то типа func "foo" .... reaction (foo ...)
// и еще - к этим jsfunc нет доступа из других jsfunc. это потому что мы "поднимается с уровня js на компаланг"
// а не "строим уровень базового языка с помощью компаланг"... codea
// cobug

// кстати в js например или в Си, funcname это указатель на функцию, а вот funcname () это вызов. Хитро.
// но в руби funcname это вызов, а Scope.method(:methodname) это получение указателя на него. Хм.

feature "jsfunc" {
  f: object asap=false {
    //add-to-scope name=@f.0 value=@f.1
    //console-log "registering feature" @f.0
    feature @f.0 {
      x: object asap=@f.asap output=(y: m-eval @f.1 {{ append-positional-params @x }} asap=@x.asap)
      {{
      m-eval {: x=@x y=@y | 
        // добавим ссылку на input
        if (x.hasLinksToParam("input"))
          y.linkParam( "input","@x->input")
        :}
      }}  
      //m-eval @f.1 -- это будет работать только когда заработает append позиционных аргументов..
      // а она заработает тогда когда будет порядок а) назначение фичи, б) применение параметров
      //x: object output=(m-eval @f.1 @x.0? @x.1? @x.2? @x.3?)      
      //m-eval @f.1 //{{ positional-append }}
    }
    //assign-to-scope items=(list (object name=@f.0 value=@f.1))
  }
}
/* если перейти к нотации что {: .. :} это eval, то тогда:
feature "foo" {
  {: a b | return a + b :}
}
т.е. мб jsunc и лишняя.

*/

// cofunc "foo" { |a b| @a + @b }
// вопрос - это же процесс а не функция. так что не эквивалентно fun
// поэтому странно что я потом это в fun заворачиваю
feature "cofunc" {
  f: object {{ catch_children "code" external=true }}
  {
    feature @f.0 {
      x: object output=(computing-env code=@f.code {{ append-positional-params @x }})
    }
  }
}

// вроде так поправильнее будет называть
feature "comp" {
  f: object {{ catch_children "code" external=true }}
  {
    feature @f.0 {
      x: object output=(computing-env code=@f.code {{ append-positional-params @x }})
    }
  }
}

// времянка эксперимент. времянка т.к заменить на comp и собирать output надо? или что?
feature "dom-comp" {
  f: object {{ catch_children "code" external=true }}
  {

    feature @f.0 {
      x: dom_group {{ insert-children input=@x list=@f.code {{ append-positional-params @x }} }}

    }
  }
}

feature "fun" {: env |
  if (env.paramConnected(1))
    return env.feature("jsfunc")
  else  
    return env.feature("cofunc")
:}

/* вариант рабочий но тормозит.. лучше на js
feature "fun" {
  f: object {{ catch_children "code" external=true }}
  {
    if (@f.1?)
    {
      feature @f.0
      {
        x: object output=(m-eval @f.1 {{ append-positional-params @x }})
      }
    }
    else
    {
      feature @f.0 {
        x: object output=(computing-env code=@f.code {{ append-positional-params @x }})
      }
    }
  }
}
*/

feature "append-positional-params" {: env |
  let orig_pos_count = env.host.params.args_count || 0;

  let unsub = () => {}
  env.onvalue( 0, (srcobj)=> {

     let names = [];
     for (let i=0; i<srcobj.params.args_count; i++) names.push( i )
     env.host.params.args_count = orig_pos_count + srcobj.params.args_count

     unsub()
     unsub = srcobj.monitor_values( names,(...args) => {
       //console.log("append-positional-params: args=",...args,"orig_pos_count=",orig_pos_count)
       for (let j=0; j<args.length; j++)
        env.host.setParam( j+orig_pos_count, args[j] )
     } )
  })
:}

feature "data"
{
  data: object output=@data->0;
};

// дошло до того что все ссылки сейчас сразу все передают..
// и надо сообразно проверять 
feature "pass_if_changed" {: env |
   env.monitor_defined(["input"],(val) => env.setParam("output",val), true )
:}

// по массиву описания цвета [1,1,1] и прозрачности 0..1 выдает запись rgb для css
feature "css-color" {
  computing_env { |color opacity|
      + "rgb(" 
         (@color | arr_map code="e => (e*255).toString()" | arr_join with=" ")
         " / "
         (@opacity * 100)
         "%)"
  };
};

// конвертирует параметры в js-объект
// некорректно это называть json, но лучше имени не придумал..
// по сути это params-to-js. еще можно обратную функцию будет сделать, js-to-params
// которая целевым объектам выставляет параметры. ну или одному, а если надо больше
// то уже пусть модификаторы раздают
feature "json" "
  env.on('param_changed',go );

  function go(pname) {
    if (pname == 'output') return;

    // и на то что есть сейчас
    let res = {};
    for (let k of env.getParamsNames()) {
      if (k == 'output') continue;
      res[ k ] = env.getParam( k );
    };
    env.setParam('output',res);
  };

  go();
";

// get-params @someobj   => словарь параметров
feature "get-params" {: env |

  let unsub = () => {}
  env.onvalue(0, (src) => {
    unsub()
    unsub = src.on("param_changed",() => {
      let q = {...src.params}
      delete q['manual_restore_performed']
      env.setParam( "output", q )
    })
  })
  env.on("remove",() => unsub() )

:}

// assign-params input=@someobj_or_array @params
// присваивает объекту someobj параметры указанные
feature "assign-params" {: env |
  env.onvalues(["input",0], (tgt,params) => {
    if (!Array.isArray(tgt)) tgt = [tgt]
    for (let obj of tgt) {
      for (let pname of Object.keys(params)) {
        let val = params[pname]
        obj.setParam( pname, val )
      }
    }
  })

:}