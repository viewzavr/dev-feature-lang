import * as E from "../viewzavr-core/nodesystem/events/init.js";

/*
  вопрос. а почему нельзя сделать read @obj | имя-метода @args ?
  мб это удобно будет. и семантика понятна

  update 26.12.2022: set_cell_value, get_cell методы переведены на отслеживание присваиваний (assigned) параметров.
*/

export function setup(vz, m) {
  vz.register_feature_set(
    {set_cell_value: set_cell_value,
     get_cell_value: get_cell_value,
     get_cell_value_latest: get_cell_value_latest,
     get_param_cell: feature_get_param_cell,
     get_event_cell: feature_get_event_cell,
     get_cmd_cell: feature_get_cmd_cell,
     get_method_cell: feature_get_method_cell,
     get_cell: feature_get_cell,
     create_cell: feature_create_cell,
     c_on : c_on,
     cc_on: cc_on,
     on_message: cc_on,

     // новый язык не ячейки а каналы таки/ но это еще вопрос
     create_channel: feature_create_cell,
     convert_channel: convert_channel, // cc-process
     redirect_to_channel: redirect_to_channel,
     get_channel: feature_get_cell,  // мб сделать это через парамеры да и все. mode="param"
     get_event_channel: feature_get_event_cell,
     get_value: get_cell_value,
     get_new_value: get_cell_new_value,
     put_value: set_cell_value,
     put_value_to: set_cell_value_to,

     // еще более новый язык, 12.22 F-CO23
     event: feature_get_event_cell,
     param: feature_get_param_cell,
     method: feature_get_method_cell,
     cmd: feature_get_cmd_cell,
     channel: feature_get_cell,
     join_channels: join_cells,
     race_channels: join_cells_positional // по аналогии с Promise.race
   });


  vz.chain( "create_obj", function (obj,options) {
      obj.get_cmd_cell = (name) => get_cmd_cell( obj, name );
      obj.get_event_cell = (name) => get_event_cell( obj, name );
      obj.get_param_cell = (name) => get_param_cell( obj, name );
      obj.get_method_cell = (name) => get_method_cell( obj, name );
      obj.get_cell = (name,ismanual) => get_cell( obj, name,ismanual );
      obj.create_cell = create_cell;
      obj.create_buffer_cell = create_buffer_cell;
      obj.create_channel = create_cell;
      obj.create_buffer_channel = create_buffer_cell;
      //obj.get_or_create_new_cell

      obj.get_existing_param_cell = (name) => {
         if (obj.hasParam( name ))
           return get_param_cell( obj, name );
       };
      obj.get_param_cells = (names) => get_param_cells( obj, name );
      return this.orig( obj, options );
  });
}

function add_onvalue_etc( cell )
{
// некая хитрая вещь у нас тут. 
  // проверяет что значение не пустое, и вызывается и сразу, и при последующих changed
  // может быть вынести ее отдельно стоит, 
  // типа "изменилась одна из"
  // например для совмещения комбинаций ячеек. но пока пусть побудет.

  cell.onvalue = (fn) => {
    if (cell.get() != null) fn( cell.get() );
    return cell.on("changed",(v) => {
       if (v != null) fn(v);
    });
  }

  // кстати идея для промиса. это 1 пара ячеек, 2 при записи они - затирают set у себя, 3 у них что-то типа onvalue но пропускает undefined значения
  // то есть оно опирается на факт записи. а не на содержимое значения. кстати это хорошо наверное.

  // попроще версия onvalue - вызывается без фильтра и всегда
  // в целом же это вопросы к модели - а что нам надо
  let value_assigned = false;
  cell.on('assigned',(v) => {
    value_assigned = true;
    cell.is_value_assigned = () => true;
  })
  cell.monitor = (fn) => {
    if (value_assigned)
        fn( cell.get() );
    return cell.on("changed",(v) => {
       fn(v);
    });
  }
  cell.is_value_assigned = () => value_assigned;

  cell.monitor_new = (fn) => {
    return cell.on("changed",(v) => {
       fn(v);
    });
  }
  /*
  cell.is_value_assigned = () => false;
  cell.on('assigned',(v) => {
    cell.is_value_assigned = () => true;
  })  
  */
}

// создает "параметр" (коммуникационную ячейку)
export function create_cell() {

  let cell = { is_cell: true };

  cell.set = (value) => {
    let different = (cell.value != value);
    // особый случай с NaN
    if (different)
        if (Number.isNaN(cell.value) && Number.isNaN(value))
          different = false;

    cell.value = value;

    cell.emit('assigned',value); // это делает ячейку - каналом. тупо пишем и можем узнавать об этом.
    // в том числе потом - через метод monitor. и тогда у нас аналог промисы почти.
    if (different)
      cell.emit('changed',value);

    return value
  };
  cell.get = () => { return cell.value };

  cell.push = cell.set; // ну теперь совсем события получились. push/monitor. ну и "канал" заодно.
  cell.put = cell.set;

  E.addEventsTo( cell ); // так-то это вопросы...
  // но в целом это некий алгоритм для ТПУ. а именно это нам и надо когда мы говорим - ячейка.

  // надо ли нам такое щастье?
  /*
  cell.remove = () => {
    cell.emit('remove');
  }*/

  add_onvalue_etc( cell );

  return cell;
};

// канал с буфером. 
export function create_buffer_cell( limit=100 ) {

  let cell = { is_cell: true, buffer: [] };

  cell.set = (value) => {
    if (cell.buffer.length < limit)
        cell.buffer.push( value );
    cell.emit('assigned',value ); // это делает ячейку - каналом. тупо пишем и можем узнавать об этом.
  };
  cell.get = () => { return cell.buffer[0] };
  /*
  cell.consume = () => { return cell.buffer.shift() }
  cell.items_in_buffer = () => cell.buffer.length;
  */
  cell.consume = () => { if (cell.buffer.length > 0) return [cell.buffer.shift()]; return null; }

  cell.push = cell.set; // ну теперь совсем события получились. push/monitor. ну и "канал" заодно.
  cell.put = cell.set;

  E.addEventsTo( cell );
  add_onvalue_etc( cell );

  return cell;
};

// штука со словарем. всегда мечтал
// т.е. cell.set(value,name) и затем cell.get возвращает разные value назначенные разным именам...
// не знаю зачем но мине нравится
export function create_multi_cell( joining_func ) {

  joining_func ||= Object.values;

  let cell = { v: {}, is_cell: true  };

  cell.set = (name,value) => { // тут вопрос конечно. прикольно сделать value, name - тогда она будет вести себя как ячейка cell..
    if (!value) {
      delete cell.v[name];
    }
    else
      cell.v[name] = value;

    let vv = cell.get();
    cell.emit('assigned',vv); // это делает ячейку - каналом. тупо пишем и можем узнавать об этом.
    cell.emit('changed',vv);
  };
  
  cell.get = () => { return joining_func( cell.v ) };
  //cell.get_names = () => { return Object.keys( cell.v ) };
  //cell.get_values = () => { return Object.values( cell.v ) };
  //cell.get_cells = () => { return cell.v };

  E.addEventsTo( cell ); // так-то это вопросы...
  // но в целом это некий алгоритм для ТПУ. а именно это нам и надо когда мы говорим - ячейка.

  add_onvalue_etc( cell );

  return cell;
};

// штука со словарем. всегда мечтал
// т.е. cell.set(value,name) и затем cell.get возвращает разные value назначенные разным именам...
// не знаю зачем но мине нравится
export function create_table_cell() {

  let cell = { v: {}, is_cell: true  };

  cell.set = (name,value) => {
    let different = (cell.v[name] != value);

    if (!value) {
      delete cell.v[name];
    }
    else
      cell.v[name] = value;

    cell.emit('assigned',name,value); // это делает ячейку - каналом. тупо пишем и можем узнавать об этом.
    if (different)
        cell.emit('changed',name,value);
  };
  
  cell.get = (name) => { return cell.v[name] };

  cell.has = (name) => cell.v[name];
  cell.names = () => Object.keys( cell.v );
  cell.values = () => Object.keys( cell.v );
  cell.table = () => cell.v;
  cell.add = cell.set;

  E.addEventsTo( cell ); // так-то это вопросы...
  // но в целом это некий алгоритм для ТПУ. а именно это нам и надо когда мы говорим - ячейка.

  add_onvalue_etc( cell );

  return cell;
};


/////////////////////////////////// привязка ячеек к объектам

export function create_comm_table()
{
  return create_table_cell();
}

export function prepare_comm_table( target )
{
  if (target.$ct) return;
  target.$ct = create_comm_table();
  // не знаю зачем я так сделал..
}

export function get_comm_table( target )
{
  prepare_comm_table( target );
  return target.$ct;
}

// вводит ячейку в таблицу целевого объекта
export function bind_comm( target, name, cell )
{
  let ct = get_comm_table( target );
  ct.add( name, cell );

  // так, это оказалось вредно -- в момент когда мы в ячейках пытаемся выразить команды..
  // да и вообще странно... не здесь это вроде как решать... выглядит как робкая попытка
  // ввести тему obj.param= ...
  // Object.defineProperty( target, name, { set: cell.set, get: cell.get } );

  return cell;
};

export function get_comm( target, name ) 
{
  let ct = get_comm_table( target );
  return ct.get( name );
};

export function get_comm_list( target ) {
  let ct = get_comm_table( target );
  return cg.values();
}

export function get_comm_names( target ) {
  let ct = get_comm_table( target );
  return cg.names();
}

export function get_comms_hash( target ) {
  let ct = get_comm_table( target );
  return cg.table(); 
}

//// кстати идея - а давайте без разницы что вводить, что параметры, что каналы, что промисы, вообще усе
//// если это хорошо будет

//// удобняшки

// todo придется возможно разделить понятия "ячейка" и далее от нее - параметр, очередь и т.п.
// и таблица - это будет про любую, а вот create - это уже конкретно про параметры, однако
export function get_or_create_cell( target,name, default_value ) 
{
  let k = get_comm( target, name );
  if (!k) {
    k = create_cell();
    if (default_value) k.set( default_value );
    bind_comm( target, name,k )
  }
  return k;
}

//////////////////////////// 

// todo manual надо будет отработать видимо на уровне опций ячейки, что ли..
export function get_param_cell( target, name ) {
  let c = get_or_create_cell( target, name, target.getParam(name) );

  if (!c.attached_to_params) {
    c.attached_to_params = true;

    let setting;
    c.on("assigned",(v) => { // мониторим assigned чтобы там свои changed отработали
       if (setting) return;
       try {
         setting = true;
         target.setParam( name, v );
       } finally { 
         setting = false;
       }
    })

    target.trackParamAssigned( name, (v) => {
       if (setting) return;
       setting = true;
       try {
         //c.set( v, target.getParamManualFlag(name) );
         // вроде не надо
         c.set( v );
       } finally { 
         setting = false;
       }   
       setting = false;
    });

  };

  return c;
};

export function get_param_cells( target, names ) 
{
   let acc = [];
   for (let n of names)
     acc.push( get_param_cell( target, n ))
   return acc;
};

// мб надо создать отдельный вид ячейки.. но пока вроде и такой прокатит
export function get_event_cell( target, name ) {
  //let c = get_or_create_cell( target, "event:" + name, target.getParam(name) );
  // пущай в одном пр-ве имен попробуют жить
  let c = get_or_create_cell( target, name, target.getParam(name) );

  if (!c.attached_to_compalang) {
    c.attached_to_compalang = [target,name];

    let setting;

    c.on("assigned",(...v) => {
       // console.log('event cell emittting',name,...v)
       if (setting) return;
       try {
         setting = true;
         target.emit( name, ...v );
       } finally { 
         setting = false;
       }
    })


    target.on( name, (...v) => {
       if (setting) return;
       setting = true;
       try {
         v.is_event_args = true; // попытка не пытка
         c.push( v );
       } finally { 
         setting = false;
       }   
       setting = false;
    });

  };

  return c;
};

// выяснено что нам надо хранить буфер чего нам напихали, пока целевой объект
// не обзаведется командой.
export function get_cmd_cell( target, name ) {
  
  //let c = get_or_create_cell( target, name );
  let c = create_buffer_cell( 100 );
  c.reply_channel = create_cell();

  function consume_all() {
     let k = c.consume();
     while (k) {
       let args = k[0];
       let res = target.callCmd( name, args );
       c.reply_channel.set( res );
       k = c.consume();
     };
  };

/*
  function consume_all() {
     while (c.items_in_buffer() > 0) {
        let args = c.consume();
        let res = target.callCmd( name, v );
        c.reply_channel.set( res );
     };
  };
*/  

  // это вызов
  c.on("assigned",(v) => {
      if (target.hasCmd( name ))
          consume_all();
  });

  target.onvalue( name,() => {
    if (target.hasCmd( name ))
      consume_all();
  } );

  return c;
};

// выяснено что нам надо хранить буфер чего нам напихали, пока целевой объект
// не обзаведется командой.
export function get_method_cell( target, name ) {
  //console.log( "get_method_cell called",target.getPath(),name)
  //let c = get_or_create_cell( target, name );
  let c = create_buffer_cell( 100 );
  c.reply_channel = create_cell();

  function try_consume_all() {
     let k = c.consume();
     let fn = target.params[ name ] || target[name]; // разрешим обращаться и к объектам..
     if (typeof( fn ) !== 'function') return;
     // console.log('method cell try_consume_all, fn=',fn,'name=',name)
     while (k) {
       let args = k[0];
       // console.log('method cell try_consume_all, fn=',fn,'name=',name, 'apply args=',args)
       // пока так
       let res = fn.call( target, args );
       c.reply_channel.set( res );
       k = c.consume();
     };
  };

  // это вызов - пишут в йачейку
  c.on("assigned",(v) => {
      try_consume_all();
  });

  // поменялся код метода
  target.onvalue( name,() => {
    try_consume_all();
  } );


  return c;
};

// универсальное - и для событий и для параметров
export function get_cell( target, name, ismanual ) {
  let c = get_or_create_cell( target, name, target.getParam(name) );
  c.ismanual = ismanual; 
  // todo разделить эти 2 вида йачеек в таблице.. мб по именам

  if (!c.attached_to_params) {
    c.attached_to_params = true;

    let setting;
    c.on("assigned",(v) => { // мониторим assigned чтобы там свои changed отработали
       if (setting) return;
       try {
         setting = true;
         //console.log("cell of",target.getPath(),"param '",name,"' setting value",v,"with manual flag", c.ismanual)
         target.setParam( name, v, c.ismanual );
       } finally {
         setting = false;
       }
    })

    // казалось бы где отписка? но этот мониторинг создается разово для каждого имени
    // и ячейка раздается всем желающим. итого у нас тут нет роста подписок более чем 1 раз.
    target.trackParamAssigned( name, (v) => {
       if (setting) return;
       setting = true;
       try {
         c.set( v );
       } finally { 
         setting = false;
       }   
       setting = false;
    });

    // тут похоже надо уровнень абстракции ячейки ввести.. ну пока так..
    // хотя впрочем это то интерфейс от emit к ячейкам..
    target.on( name, (...v) => {
       if (setting) return;
       setting = true;
       try {
         v.is_event_args = true; // попытка не пытка
         c.push( v );
       } finally { 
         setting = false;
       }   
       setting = false;
    });

  };

  return c;
};

////////////////
//////////////// интеграция с комполангой
////////////////

////////////////// пучки

// запись в массив ячеек
// input - массив целевой, 0 - значение

// действие - при присвоении значения в аргумент 0 пересылает его в указанный канал
export function set_cell_value( env ) {
  /*
  env.onvalue("output",(v) => {
    console.log("qqqq",v)
  })
  */

  env.monitor_assigned( ["input",0], (arr, val) => {
    if (env.params.disabled) return;
    if (!arr) return;

    let single_elem_mode = false;
    if (!Array.isArray(arr)) { arr=[arr]; single_elem_mode = true };
    let responding_channels = [];

    env.setParam("working",true);
    try {
    arr.forEach( (cell) => {
      if (!cell) return;
      // console.log("set cell value",cell,val)
      //if (val == 55) debugger;
      if (!cell.set) {
        console.error("set_cell_value: cell.set is not defined. typeof(cell)=",typeof(cell),"cell=",cell, env.getPath())
        env.setParam("output",true)
        return;
      }
      // console.log('cell is setting val',val)
      cell.set( val );
      responding_channels.push( cell.reply_channel )
    })
    } finally {
      env.setParam("working",false);
    }

    // короче признаю эту тему с reply-channel несостоятельной..
    // потому что она возвращает undefined если такого канала нет..
    // если нужны ответы - давайте делать put-request...
    // #design
    let o = single_elem_mode ? responding_channels[0] : responding_channels;
    //console.log("vvv",o)
    env.setParam("output", o );

    // это было для завершения прцоессов...
    // env.setParam("output", true );

    // todo optimize че их каждый раз пересчитывать то - собрать один раз и се..
    //env.setParam("output",arr); // чтобы можно было цепочки строить | 
    //env.setParam("output",val); // чтобы можно было цепочки строить | 
    // чухня все это. надо ответные каналы давать.
  });
};

// наоборот, input это значение а 0 это целевой канал. ну как-то так получается..
export function set_cell_value_to( env ) {
  env.onvalues( [0,"input"], (arr, val) => {
    if (env.params.disabled) return;

    let single_elem_mode = false;
    if (!Array.isArray(arr)) { arr=[arr]; single_elem_mode = true };
    let responding_channels = [];

    env.setParam("working",true);
    try {
    arr.forEach( (cell) => {
      if (!cell) return;
      // console.log("set cell value",cell,val)
      //if (val == 55) debugger;
      if (!cell.set) {
        console.error("set_cell_value: cell.set is not defined. typeof(cell)=",typeof(cell),"cell=",cell, env.getPath())
        return;
      }
      // console.log('cell is setting val',val)
      cell.set( val );
      responding_channels.push( cell.reply_channel )
    })
    } finally {
      env.setParam("working",false);
    }

    //env.setParam("output",single_elem_mode ? responding_channels[0] : responding_channels ); 
    env.setParam("output",single_elem_mode ? arr[0] : arr ); 

    // todo optimize че их каждый раз пересчитывать то - собрать один раз и се..
    //env.setParam("output",arr); // чтобы можно было цепочки строить | 
    //env.setParam("output",val); // чтобы можно было цепочки строить | 
    // чухня все это. надо ответные каналы давать.
  });
};

// чтение массива ячеек
// input - массив ячеек
// если входная это ячейка а не массив то выдавать 1 значение а не массив значений
export function get_cell_value( env ) {
  let unsub = [];
  function call_unsub() { unsub.map( f => f() ); unsub=[]; }

  env.feature("delayed");

  env.onvalues( ["input"], (arr) => {
    let single_mode=false;
    if (!Array.isArray(arr)) {
        arr=[arr];
        single_mode=true;
    }

    let fnd = env.delayed( fn ); // не факт кстати что это надо будет - мб надо сразу для скорости

    function fn() {
      call_unsub();
      let has_assigned_values = false;
      let res = arr.map( (cell) => {
        if (!cell) return;
        if (!cell.is_cell) {
          console.log("get_cell_value: input is not a channel; type=",typeof(cell))
          env.vz.console_log_diag( env )
          //return undefined
        }
        // медленно и печально, с задержками, всех соединяем...
        //let u = cell.monitor(fnd);
        // бодро и быстро
        let u = cell.on('assigned',fn)
        unsub.push( u );
        has_assigned_values ||= cell.is_value_assigned();
        return cell.get();
      })

      if (has_assigned_values) // будем так
          env.setParam( "output", single_mode ? res[0] : res );
    };

    fn();

  });

  env.on("remove", call_unsub)
};

// как get_cell_value но работает ток для новых событий
export function get_cell_new_value( env ) {
  let unsub = [];
  function call_unsub() { unsub.map( f => f() ); unsub=[]; }

  env.feature("delayed");

  env.onvalues( ["input"], (arr) => {
    let single_mode=false;
    if (!Array.isArray(arr)) {
        arr=[arr];
        single_mode=true;
    }

    let fnd = env.delayed( fn ); // не факт кстати что это надо будет - мб надо сразу для скорости

    function fn( only_subscribe ) {
      call_unsub();
      let has_assigned_values = false;
      let res = arr.map( (cell) => {
        if (!cell) return;
        if (!cell.is_cell) {
          console.log("get-channel-value: input is not a channel",typeof(cell))
          env.vz.console_log_diag( env )
          //return undefined
        }
        // медленно и печально, с задержками, всех соединяем...
        //let u = cell.monitor(fnd);
        // бодро и быстро
        let u = cell.on('assigned',fn)
        unsub.push( u );
        if (only_subscribe) return

        has_assigned_values ||= cell.is_value_assigned();
        return cell.get();
      })

      if (has_assigned_values) // будем так
          env.setParam( "output", single_mode ? res[0] : res );
    };

    fn( true );

  });

  env.on("remove", call_unsub)
};

// выдает 1 значение из массива ячеек - по очередности кто последний
// input - массив ячеек
export function get_cell_value_latest( env ) {
  let unsub = [];
  function call_unsub() { unsub.map( f => f() ); unsub=[]; }

  env.feature("delayed");

  env.onvalues( ["input"], (arr) => {
    let single_mode=false;
    if (!Array.isArray(arr)) {
        arr=[arr];
        single_mode=true;
    }

    let fnd = env.delayed( fn ); // не факт кстати что это надо будет - мб надо сразу для скорости

    function fn() {
      call_unsub();
      
      arr.forEach( (cell) => {
        if (!cell) return;

        let u = cell.monitor((value) => {
          env.setParam( "output", value )
        });

        unsub.push( u );
      })
    };

    fn();

  });

  env.on("remove", call_unsub)
};

///////////// доступ к ячейкам

// получить ячейки "параметров"
// input - массив объектов
// 0 - имя параметра
export function feature_get_param_cell( env ) {
  env.onvalues( ["input",0], (arr, param_name) => {
    let single_elem_mode = !Array.isArray(arr);
    if (single_elem_mode) arr=[arr];
    let res = [];
    arr.forEach( (obj) => {
      if (!obj)
        res.push( null);
      else
        res.push( obj.get_param_cell( param_name ) );
    });
    
    env.setParam( "output", single_elem_mode ? res[0] : res );
    // single_elem_mode - это плохо или это норм? так-то сигнатура выхода меняется...
  }); 
}

// получить ячейки "событий"
// input - массив объектов
// 0 - имя параметра
export function feature_get_event_cell( env ) {

  //console.log("get-event-cell herllo")

  env.onvalues( ["input",0], go);
  env.onvalues( [0,1], go);

  function go (arr, param_name) {
    //console.log("get-event-cell",arr,param_name)
    let single_elem_mode = !Array.isArray(arr);
    if (single_elem_mode) arr=[arr];
    let res = [];
    arr.forEach( (obj) => {
      if (!obj)
        res.push( null);
      else
        res.push( obj.get_event_cell( param_name ) );
    });
    
    env.setParam( "output", single_elem_mode ? res[0] : res );
    // single_elem_mode - это плохо или это норм? так-то сигнатура выхода меняется...
  }; 
}

// получить ячейки "команд"
// input - массив объектов
// 0 - имя параметра
export function feature_get_cmd_cell( env ) {
  env.onvalues( ["input",0], (arr, param_name) => {
    let single_elem_mode = !Array.isArray(arr);
    if (single_elem_mode) arr=[arr];
    let res = [];
    arr.forEach( (obj) => {
      if (!obj)
        res.push( null);
      else
        res.push( obj.get_cmd_cell( param_name ) );
    });
    
    env.setParam( "output", single_elem_mode ? res[0] : res );
    // single_elem_mode - это плохо или это норм? так-то сигнатура выхода меняется...
  }); 
}

export function feature_get_method_cell( env ) {
  env.onvalues( ["input",0], (arr, param_name) => {
    let single_elem_mode = !Array.isArray(arr);
    if (single_elem_mode) arr=[arr];
    let res = [];
    arr.forEach( (obj) => {
      if (!obj)
        res.push( null);
      else
        res.push( obj.get_method_cell( param_name ) );
    });
    
    env.setParam( "output", single_elem_mode ? res[0] : res );
    // single_elem_mode - это плохо или это норм? так-то сигнатура выхода меняется...
  }); 
}


// берет ячейку у массива объектов
// если флаг manual то будет брать такую ячейку запись в которую будет выставлять manual-флаг
export function feature_get_cell( env ) {
  if (!env.hasParam("manual"))
       env.setParam("manual",false);

  env.onvalues( ["input",0,"manual"], go);
  env.onvalues( [0,1,"manual"], go);

  function go (arr, param_name,manual) {
    let single_elem_mode = !Array.isArray(arr);
    if (single_elem_mode) arr=[arr];
    let res = [];
    arr.forEach( (obj) => {
      if (!obj || !obj.get_cell)
        res.push( null );
      else
        res.push( obj.get_cell( param_name, manual ) );
    });

    //console.log("get-channel. sem=",single_elem_mode,env.getPath())
    
    env.setParam( "output", single_elem_mode ? res[0] : res );
    // single_elem_mode - это плохо или это норм? так-то сигнатура выхода меняется...
  }
}

// просто поржать
export function feature_create_cell( env ) {
  let cell = create_cell();

  env.trackParamAssigned( 0, (v) => cell.set( v )); // внедрим такое поведение оно частое

  env.setParam( "output", cell );
}

////////////////////////////// оказалось важное - подписка на обновления в ячейке.. мои ловят так себе...
// m_eval реагирует на доп. параметры, а не надо
// m_lambda хороша тут, но на output выдает функцыю.. а хорошо бы - значения или йачейку..

let con_dump;
// todo сделать c_on для массивов. там видимо работа такая что если одно что-то изменилось то
// с этим одним аргументом и вызывать. хотя вопрос открытый конечно, как удобнее - или со всеми сразу?
// но тогда чем это от обычного eval-а то будет отличаться.
// ну и встает вопрос опять как передавать объект, от которого произошло событие.
// по порядку? а какой тогда порядок? параметры события, объект, доп-параметры? и как то запоминать?
export function c_on( env ) {
  env.feature("simple_lang");
  
  con_dump ||= env.compalang( `
  object output=@ee->output {
    get-cell-value input=@q->input | ee: m_eval @q->0 @q->1? @q->2? @q->3? @q->4? allow_undefined=true allow_undefined_input=false react_only_on_input=true;
  };
  `, {parent: env.ns.parent,base_url:"?"});

  let $scopeFor = env.$scopes.createScope("parseSimpleLang"); // F-SCOPE
  $scopeFor.$add( "q",env);
  let res = env.restoreFromDump( Object.values(con_dump.children)[0],false,$scopeFor );
  
};

// метод F-NEW-EHA
// @channel | cc-on { ... }
// cc-on @channel { ... }
/* новое:
   @channel | reaction { |x| .... }
   @channel | reaction (m-lambda "(x) => ..... ")
*/
export function cc_on( env ) {
  env.setParam( "make_func_output","f")
  env.feature("make_func");

  let unsub = () => {}
  env.onvalues_any(['input'],(channel) => {
    //channel ||= channel_arg;
    unsub();
    if (!channel?.is_cell) {
      console.warn("cc-on: input is not channel",channel)
      env.vz.console_log_diag( env )
      unsub = () => {}
      return
    }

    unsub = channel.on('assigned',(v) => {
      //console.log("cc-on passing",v)
      emit_val( v )
    })

    if (env.params.existing && channel.is_value_assigned())
      emit_val( channel.get() )

    // todo мб ключи - реагировать ли если уже были события
    // и одноразовое оно или многоразовое
  })
  env.on('remove',() => unsub())

  function emit_val(v) {
      let f = env.params[0] || env.params.f;
      //let f = env.params.f;

      if (v?.is_event_args) {
        //console.log('cc-on passing extended event args',v)
        //env.vz.console_log_diag( env )
        f.apply( env, v )
      }
      else
        f.call( env, v )    
  }

};

/*
  let $scopeFor = env.$scopes.createScope("parseSimpleLang"); // F-SCOPE
  $scopeFor.$add( "q",env);
  let d = Object.values(dump.children)[0];
  d.keepExistingParams=true;
  d.$scopeFor = $scopeFor;
  debugger;
  env.vz.createSyncFromDump( d,env );
*/


/*
export function c_on( env ) {
  let unsub = [];
  function call_unsub() { unsub.map( f => f() ); unsub=[]; }

  env.feature("delayed");
  env.feature("m_lambda");

  env.onvalues( ["input"], (arr) => {
    let single_elem_mode = !Array.isArray(arr);
    if (single_elem_mode) arr=[arr];

    let fnd = env.delayed( fn ); // не факт кстати что это надо будет - мб надо сразу для скорости

    function fn() {
      call_unsub();
      let has_assigned_values = false;
      let res = arr.map( (cell) => {
        if (!cell) return;
        let u = cell.monitor(fnd); 
        unsub.push( u );
        has_assigned_values ||= cell.is_value_assigned();
        return cell.get();
      })

      if (has_assigned_values) { // будем так
          env.callCmd("apply",single_elem_mode ? res[0] : res);
      };
    };

    fn();

  });

  env.on("remove", call_unsub)
};
*/

/////////////////// операции над ячейками - экспериментально

// Мишин мэпинг из набора ячеек в новую ячейку значение которой - набор значений
// идея - еще any_cells (any_channel) - потипу Promise.any - это есть merge

// по списку ячеек создает новую ячейку, которая содержит в себе массив значений
// input - массив ячеек
// если входная это ячейка а не массив то выдавать 1 значение а не массив значений
// но это спорно
// let arrcell = (list @c1 @c2 @c3 | join_cells)
export function join_cells( env ) {
  let result = create_cell();
  env.setParam( "output", result );

  let unsub = [];
  function call_unsub() { unsub.map( f => f() ); unsub=[]; }

  env.feature("delayed");

  env.onvalues( ["input"], setup );

  if (env.params.args_count > 0) {
    env.on("param_changed",(pn) => {
      if (pn == "output") return;
      let arr = [];
      for (let i=0; i<env.params.args_count; i++)
        arr.push( env.params[i] );
      setup( arr )
    })
  }

  function setup (arr) {
    let single_mode=false;
    if (!Array.isArray(arr)) {
        arr=[arr];
        single_mode=true;
    }   

    //let fnd = env.delayed( fn ); // не факт кстати что это надо будет - мб надо сразу для скорости

    function fn() {
      call_unsub();
      let has_assigned_values = false;
      let res = arr.map( (cell) => {
        if (!cell) return;
        let u = cell.on("assigned",fn); 
        unsub.push( u );
        has_assigned_values ||= cell.is_value_assigned();
        return cell.get();
      })

      result.set( single_mode ? res[0] : res )
    };

    fn();

  };

  env.on("remove", call_unsub)
};

// аналог join_cells но результатом будет канал значение которого массив из null, 
// где i-е значение ненулевое только в позиции которая прислала результат
// доп. идея - можно задействовать уже delayed-вещи, чтобы соединять их всяко
// todo т.е. можно объединять значения на delayed-принципе или доп-ом, как в lf, управлять режимом объединения 
// этим в момент посылки сообщения
export function join_cells_positional( env ) {
  let result = create_cell();
  env.setParam( "output", result );

  let unsub = [];
  function call_unsub() { unsub.map( f => f() ); unsub=[]; }

  env.feature("delayed");

  env.onvalues( ["input"], setup );

  if (env.params.args_count > 0) {
    env.on("param_changed",(pn) => {
      if (pn == "output") return;
      let arr = [];
      for (let i=0; i<env.params.args_count; i++)
        arr.push( env.params[i] );
      setup( arr )
    })
  }

  function setup (arr) {
    if (!Array.isArray(arr)) {
        arr=[arr];
    }

    function fn() {
      call_unsub();
      let res = arr.map( (cell,index) => {
        if (!cell) return;
        let u = cell.on("assigned",(val) => {
          forward_value( val, index )
        }); 
        unsub.push( u );
        return cell.get();
      })

      
    };

    function forward_value( val, index ) {
      let res = (new Array( arr.length )).fill(null)
      res[index] = val;      
      res.index = index; // отметку поставим..
      result.set( res )
    }

    fn();

  };

  env.on("remove", call_unsub)
};

// Мишин мэпинг из ячейки в набор ячеек
// делает ячейку, запись в которую приводит к записи во все указанные в input ячейки
// let k = (list @c1 @c2 @c3 | create-writing-cell)
export function create_writing_cell( env ) {
  let result = create_cell();
  env.setParam( "output", result );

  result.on('assigned',fn);

  function fn(v) {
    let arr = env.params.input;
    if (!arr) return;
    if (!Array.isArray(arr)) arr=[arr];
    arr.forEach( (cell) => {
      cell.set( v );
    });
  }
};

// присоединяет канал к другим каналам на запись
// input - входной канал
// 0 - один или набор целевых каналов
// выход - дубликат входного канала
// todo мб во многие еще надо, т.е. уметь писат в массивы.. а уже есть см create_writing_cell
// формально это дублирование линка. но какое же оно маленькое и красивое. наверное так и должно быть.
export function redirect_to_channel( env ) {

  let unsub = () => {}
  env.onvalue( 'input',(inc) => {
    unsub()
    //env.auto_unsub( 'id',inc.on('assigned',fn)) todo idea
    unsub = inc.on('assigned',fn)
    env.setParam( "output", inc );
  })
  env.on("remove",() => unsub())

  function fn(v) {
    let arr = env.params[0];
    if (!arr) return;
    if (!Array.isArray(arr)) arr=[arr];
    arr.forEach( (cell) => {
      cell.set( v );
    });
  }
};

// создает новый канал, который конвертирует значения исходного
// todo фильтр еще надо
export function convert_channel( env ) {
  let cc = create_cell()
  env.setParam( "output", cc );

  let unsub = () => {}
  env.onvalue( 'input',(inc) => {
    if (!inc?.is_cell) {
      console.warn("convert_channel: input value is not a channel",inc)
      return
    }
    unsub()
    unsub = inc.on('assigned',fn)
  })
  env.on("remove",unsub)

  //env.process_unsub( "p1", inc.on('assigned',fn) )
  //env.p_unsub( "p1" )( inc.on('assigned',fn) )

  function fn(v) {
    let code = env.params[0];
    let res = code.call( env, v );
    // todo проверить может там и кода нет, а может там make-func
    cc.set( res )
  }
};