import * as E from "../viewzavr-core/nodesystem/events/init.js";

export function setup(vz, m) {
  vz.register_feature_set(
    {set_cell_value: set_cell_value,
     get_cell_value: get_cell_value,
     get_param_cell: feature_get_param_cell,
     get_event_cell: feature_get_event_cell,
     get_cell: feature_get_cell,
     create_cell: feature_create_cell,
     c_on : c_on
   });


  vz.chain( "create_obj", function (obj,options) {
      obj.get_event_cell = (name) => get_event_cell( obj, name );
      obj.get_param_cell = (name) => get_param_cell( obj, name );
      obj.get_cell = (name,ismanual) => get_cell( obj, name,ismanual );
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
  };
  cell.get = () => { return cell.value };

  cell.push = cell.set; // ну теперь совсем события получились. push/monitor. ну и "канал" заодно.

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

  Object.defineProperty( target, name, { set: cell.set, get: cell.get } );

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

    target.trackParam( name, (v) => {
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

    c.on("assigned",(v) => {
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
         c.push( v );
       } finally { 
         setting = false;
       }   
       setting = false;
    });

  };

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
         target.setParam( name, v, c.ismanual );
       } finally {
         setting = false;
       }
    })

    // казалось бы где отписка? но этот мониторинг создается разово для каждого имени
    // и ячейка раздается всем желающим. итого у нас тут нет роста подписок более чем 1 раз.
    target.trackParam( name, (v) => {
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
export function set_cell_value( env ) {
  env.onvalues( ["input",0], (arr, val) => {
    if (!Array.isArray(arr)) arr=[arr];
    arr.forEach( (cell) => {
      if (!cell) return;
      //console.log("set cell value",cell,val)
      cell.set( val );
    })
    //env.setParam("output",arr); // чтобы можно было цепочки строить | 
    env.setParam("output",val); // чтобы можно было цепочки строить | 
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
        let u = cell.monitor(fnd); 
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
  env.onvalues( ["input",0], (arr, param_name) => {
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
  }); 
}

// берет ячейку у массива объектов
export function feature_get_cell( env ) {
  if (!env.hasParam("manual"))
       env.setParam("manual",false);

  env.onvalues( ["input",0,"manual"], (arr, param_name,manual) => {
    let single_elem_mode = !Array.isArray(arr);
    if (single_elem_mode) arr=[arr];
    let res = [];
    arr.forEach( (obj) => {
      if (!obj || !obj.get_cell)
        res.push( null );
      else
        res.push( obj.get_cell( param_name, manual ) );
    });
    
    env.setParam( "output", single_elem_mode ? res[0] : res );
    // single_elem_mode - это плохо или это норм? так-то сигнатура выхода меняется...
  }); 
}

// просто поржать
export function feature_create_cell( env ) {
  let cell = create_cell();

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
  output=@ee->output {
    get-cell-value input=@q->input | ee: m_eval @q->0 @q->1? @q->2? @q->3? @q->4? allow_undefined=true allow_undefined_input=false react_only_on_input=true;
  };
  `, {parent: env.ns.parent,base_url:"?"});

  let $scopeFor = env.$scopes.createScope("parseSimpleLang"); // F-SCOPE
  $scopeFor.$add( "q",env);
  let res = env.restoreFromDump( Object.values(con_dump.children)[0],false,$scopeFor );
  
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

// по списку ячеек создает новую ячейку, которая содержит в себе массив значений
// input - массив ячеек
// если входная это ячейка а не массив то выдавать 1 значение а не массив значений
// но это спорно
export function join_cells( env ) {
  let result = create_cell();
  env.setParam( "output", result );

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
        let u = cell.monitor(fnd); 
        unsub.push( u );
        has_assigned_values ||= cell.is_value_assigned();
        return cell.get();
      })

      result.set( single_mode ? res[0] : res )
    };

    fn();

  });

  env.on("remove", call_unsub)
};

// Мишин мэпинг из ячейки в набор ячеек
// делает ячейку запись в которую пишет во все указанные в input ячейки
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