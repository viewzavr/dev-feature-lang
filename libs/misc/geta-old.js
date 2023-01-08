// новая идея - что если неск компонент то это запрос на выборку массива
// т.е. obj | geta "title" "getPath" выдает пару [a,b]
// но если запрос на 1 то выдается просто значение.. да уж, неконсистентность.. ну и ладно..
// ну скажем тогда geta_many чтоб не путаться (наше правило... что сигнатуре бы не надо меняться..)

// новая идея в том что geta должна работать таки с 1 компонентой
// а map_geta тоже имеет право быть но тоже работать с 1 компонентой
// у нас уже есть стыковка через | таки - этого должно хватить.
// ну а то что пересчет массивов - пережить можно а потом оптимизировать (на каналы перевести)

// но пока далее старая многоаргументная реализация
/////////////////////////////////

/// geta - доступ к компонентам compolang-объектов и любых js структур
// доступ идет сразу ко многим компонентам, т.е. 
// geta input=@alfa beta gamma - выполнит операцию alfa.beta.gamma
// по сути является посылкой им сообщений поочередной

// так то можно было @alfa | get "beta" | get "gamma"
// и для get это бы сработало но вот для map_geta это типа постоянный пересчет массивов целиком
// но там можно было бы сделать какой-то спец-протокол для общения именно get-ов между собой
// и наверное это было бы правильнее.

// ну сделаем на достуге getb значит.. щас пока норм вроде..

// но при этом доп аргументы как методы при вызове метода или emit-а я считаю удачным..
// т.е. @alfa | get "methodname" arg1 arg2;
// но опять же.. а то ли это что надо.. может быть тут стоило бы сделать call_cmd да и все..
// ну т.е. call input=@someobj "methodname" arg1 arg2 ....

export function setup(vz, m) {
  vz.register_feature_set(m);
}

// новые имена 23-06-2022

/*
export function get( env ) {
  env.feature("geta");
}
export function map_get( env ) {
  env.feature("map_geta");
}
export function filter_get( env ) {
  env.feature("filter_geta");
}
*/

//////////////// geta
// берет все подряд, a | get b c d

export function geta( env ) {
  env.single_geta_mode=true;
  env.feature( "map_geta"); // типа там с 1 штучкой тоже работать умеют
  // но есть проблема - надо упаковывать в 1 штучку всегда, а не то что при условии "если это не массив"
}

// режим фильтра, т.е. если гета выдает истину, то элемент берется, а если нет, то пропускается
export function filter_geta( env ) {
  env.filter_mode=true;
  env.feature( "map_geta"); // типа там с 1 штучкой тоже работать умеют
  // но есть проблема - надо упаковывать в 1 штучку всегда, а не то что при условии "если это не массив"
}

export function map_geta( env )
{

  env.on("param_changed",(pn) => {
    if (pn !== "output")
       process( env.params.input )
  });

  let unsub_struc_arr = [];
  let unsub_all = () => { unsub_struc_arr.map( rec => rec.unsub() ) }

  function process( input_arr ) {
    
    unsub_all();

    if (env.params.debug) 
       debugger;

    if (input_arr == null) { // вроде как норм вариант проверять и на ундефинет

      // новое поведение. если ничего мы ранее не назначали. то и выхода из нас не должно быть.
      if (!env.paramAssigned("output"))
        return;

      //console.log("geta setting output null...",env.getPath())
      if (env.single_geta_mode) {
        //if (env.params.output) // но только если там что-то было.. а если ничего не было то пока ничего и не пишем.. ибо мы еще не отработали
        // ну нет наверное. наверное надо таки вернуть default
            env.setParam( "output", env.params.default ); 
      }
      else
      {
        // ну тут может стоит проверку на то что и так выдаем [] поставить
        env.setParam( "output", [] );
      }
      
      return;
    }

    //if (input_arr && !Array.isArray(input_arr))
    if (env.single_geta_mode) // пожелание из geta
      input_arr = [input_arr];
    // может быть стоит все-таки в случае если это словарь - идти по его значениям ключей
    // сейчас же мы получается если это словарь - обратимся к ему самому и пойдем только в 1 ключ..
    // т.е. не совсем это map для словаря получается..
    // но опяь же на словаре можно сказать get_param_values и получить массив. пока так. 

    if (!Array.isArray(input_arr)) {
      console.error("map_geta: input is not array!",input_arr);
      env.setParam( "output",env.single_geta_mode ? env.params.default : [] );
      // qqq
      env.vz.console_log_diag( env );
      return;
    }

    if (input_arr.length == 0) {
      env.setParam( "output",env.single_geta_mode ? env.params.default : [] );
      return;
    }

    if (env.params.args_count != 1) {
      console.warn("geta: params count is not 1", env.getPath(), env);
    }

    // случай когда параметр-селектор get-ы еще не вычислен
    if (!env.hasParam(0)) {
      env.setParam( "output",env.single_geta_mode ? env.params.default : [] );
      return; 
    }

    output=[];
    output.length = input_arr.length;

    if (env.params.debug) 
       debugger;

    for (let i=0; i<input_arr.length; i++) {
      // готовим поэлементную отписку
      // отписка у нас тут будет башенкой
      // а именно - каждый уровень соответствует аргументу
      let unsub_arr = [];
      let unsub = () => { unsub_from(0); }
      let unsub_from = (level) => { 
        let toremove = unsub_arr.splice( level );
        toremove.map( f => f() );
      };
      let unsub_struc = { unsub_arr, unsub, unsub_from };
      unsub_struc_arr.push( unsub_struc );

      process1( input_arr[i], unsub_struc, i );
    }
  }

  // идея в том что все будут писать в свои ячейки и иногда мы будем output
  // писать в результат
  let output;
  env.feature("delayed");
  let schedule_update_output = env.delayed( () => {
    //console.log("output of map-geta", output, env.getPath())
    // спец счетчик чтобы проходило фильтр во вьюзавре на тему изменения объектов
    // нахер это - накололся
    //output.$vz_param_state_counter = (output.$vz_param_state_counter || (env.$vz_unique_id*1024)) +1;
    //env.setParam("output",output);
    //env.setParamWithoutEvents("output",output);
    //env.signalParam("output");
    // типа так оно не отразит что поменялось

    if (env.filter_mode)
      env.setParam("output",output.filter( n => n) );
    else    
      env.setParam("output",[...output]);
  });
  
  let warn_func_stop = () => {};

  // обрабатывает 1 объект
  function process1( input, unsub_struc, index ) {
    env.params.args_count ||= 0;
    //console.log(env.params[0])
    
    
    get_one( input, env.params, 0,(res) => {



      if (res == null && env.hasParam('default'))
      {
          //console.log("keke1")
          res = env.params.default;
      }
      else
      if (res == null && !env.filter_mode) {
        //console.log("keke2", env.params)
        /* теперь мне стало непонятно. ну и что что нулл, разве это плохо?
        if (env.single_geta_mode)
          console.warn( "geta: result is null, arg=[", env.params[0],"] input=[",env.params.input,"]", env.getPath());
        else
          console.warn( "map_geta: query result is null, arg=[", env.params[0],
               "] input=[",env.params.input,"] index=", index, env.getPath());
        env.vz.console_log_diag( env );
        */
      }

      if (env.single_geta_mode) {
        //console.log("thus setting output",res)
        env.setParam( "output",res );
        return;
      }

      // режим фильтра.. сообразно там у нас предикат...
      if (env.filter_mode)
        output[index] = res ? input : null;
      else
        output[index] = res;

      schedule_update_output();
    },unsub_struc );
  }

  function go_next_level( input, params, current_arg_pos, cb, unsub_struc, current_level_unsub ) {
    if (!current_level_unsub)
    {
      console.error("go_next_level: prev_level_unsub not specified");
      return;
    }
    unsub_struc.unsub_arr.push( current_level_unsub );
    get_one( input, params, current_arg_pos+1, cb, unsub_struc );
  }

  // возвращает запрос к объекту input
  function get_one( input, params, current_arg_pos,cb, unsub_struc ) {
    warn_func_stop(); warn_func_stop = () => {};
  
    unsub_struc.unsub_from( current_arg_pos ); // снесем все подписки начиная с текущего уровня
    // важно что все ветви алгоритма начиная с текущего момента должны дать функцию отписки
    // для этого сделана go_next_level

    if (input == null) {
      return cb(null);
    }
    if (current_arg_pos >= params.args_count)
      return cb(input);

    let name = params[ current_arg_pos ];
    
    if (input.trackParam) {
      // это у нас объект и сообразно там все может быть

      //////////////////// метода? (как то бы события еще сюды зацепить.. мб команду emit? ))))
      // но была мысль как-то совместить cmd и emit-ы
      // у метода д.быть приоритет N1 т.к. он еще cmd и на hasParam откликается
      /* убираем - пусть ветка функции с этим разбирается... нечо..
      if (input.hasCmd( name )) {
        console.warn("geta: call to cmd");
        env.vz.console_log_diag( env );

        let restargs = [];
        for (let i=current_arg_pos+1; i<params.args_count; i++)
          restargs.push( params[i] );
        
        let res = input.callCmd( name,...restargs );
        cb( res );
        return;
      };
      */

      ////////////////// пораметр?
      if (input.hasParam(name)) {
        // поменяется параметр - рестартуем хвост
        // todo это не эффективно в плане что у меня сейчас 1 штучка используется...
        // точнее что если мы и есть хвост - то чего рестартовать то
        let u;
        if (env.params.stream_mode)
        {
          //console.log("geta: using stream mode for",name)
          //env.vz.console_log_diag( env )
          // F-PARAMS-STREAM
          u = input.on( name + "_assigned", () => get_one( input, params, current_arg_pos, cb, unsub_struc))
        }
        else
        {
          u = input.trackParam( name, () => get_one( input, params, current_arg_pos, cb, unsub_struc));
        }  
        // едем дальше
        
        return go_next_level( input.getParam(name), params, current_arg_pos,cb,unsub_struc, u );
      }

      //////////////////// дите?
      let cc = input.ns.getChildByName( name )
      if (cc) {
        let u = cc.on("parent_change",() => get_one( input, params, current_arg_pos, cb));
        //cc.on("name_change",() => get_one( input, env_with_args, current_arg_pos, cb));

        return go_next_level( cc, params, current_arg_pos,cb,unsub_struc,u );
      }

      // ну все, специальные вещи кончились - уходим на обычный подход
      
    };

    // финт
    if (typeof(name) === "function") {
      // передали функцию в аргументе - вычисляем ее от 1 одного аргумента (входа) и едем дальше
      // применять операцию к ее результату.. тут может быть стоит запихать сюда аргументы
      let res = name( input );
      go_next_level( res, params, current_arg_pos,cb,unsub_struc, () => {} );
      return;
    };

    // это у нас не объект вьюзара, обращаемся просто как к js структуре
    // так-то можно было бы универсальное событие track_change по имени и там неважно - параметр или что..
    let nv = input[ name ];
    //console.log("get_one name=",name,"nv=",nv,"input=",input)
    
    if (typeof(nv) === "function" && !(env.params.eval || env.params.fok))
    {
       //console.warn("geta: you got function, new beh",name,input,nv);
       // env.vz.console_log_diag( env );
    }

    
    /* ну или да ну его лесом, вызов функций.. если надо будет сделать как бы триггеры, аля eval..
       то может стоит прямо и говорить m-eval и там стандартный мехазим передачи аргументов.
       а если вот надо будет как бы автоматику включать.. ну тут подумать надо..
    */
    // выяснилось что много где я это использую.. так что пусть пока с флагом побудет
    if (typeof(nv) === "function") // решил сделать вызов функций. те.. это уже не get у меня а send по сути то
    {
       if (env.params.eval) {
         // передали в аргументе имя функции объекта? вызываем ее со всеми оставшимися аргументами
         let restargs = [];
         for (let i=current_arg_pos+1; i<params.args_count; i++)
            restargs.push( params[i] );
         // может стоит собрать аргумнеты в и-режиме т.е. вызывать и-функции 
         let res = nv.apply( input, restargs );
         cb( res );
         return;
       };
       nv = nv.bind( input ); // оказалось так надо делать чтобы всякие flat работали

    }

    // особый случай - запрашиваем параметр а его еще не прописали...
    // но так-то тут может быть история что там не только параметр а и команда и дите..
    // надо бы событие особое типа item-имя-changed и его высылать на все эти случаи..
    if (nv == null && input.hasParam) {
        // копируем алгоритм выше
        // поменяется параметр - рестартуем хвост
        let u
        if (env.params.stream_mode)
        {
          // F-PARAMS-STREAM
          u = input.on( name + "_assigned", () => get_one( input, params, current_arg_pos, cb, unsub_struc))
        }
        else
          u = input.trackParam( name, () => { get_one( input, params, current_arg_pos, cb, unsub_struc)} );
        // едем дальше
        // а дальше - стало быть отменяем свое значение.
        if (env.single_geta_mode)
        {
          if (env.hasParam("default"))
          {
             env.setParam("output", env.params.default );
          }
          else
          {
             env.removeParam("output");
             env.signalParam("output");
             // получается мы молча ничего не прочитали и не поругались
             warn_func_stop = env.timeout( () => {
               console.warn( "geta: no requested data in source object, arg=[", env.params[0],"] input=[",env.params.input,"]", env.getPath());
               env.vz.console_log_diag( env );
             }, 300 );
          }
          return;
        }
        else  
          return go_next_level( input.getParam(name), params, current_arg_pos,cb,unsub_struc, u );      
        // раньше было так для всех.. посмотрим..
    }
    
    go_next_level( nv, params, current_arg_pos,cb,unsub_struc, () => {} );
  }
}
