// dataframe entity

///////////////////////////////////////////
// constructors and getters
///////////////////////////////////////////
export function create() {
  var df =  { "colnames": [], length: 0, isDataFrame: true, string_columns: {} }
  df.clone = clone.bind(df,df);
  df.is_df = true;
  // времянка такая
  df.create_from_df_filter = (f) => create_from_df_filter( df, f );
  df.create_from_df_filter_fast = (f) => create_from_df_filter_fast( df, f );

  // короче решено таки эти методы таскать вместе с df
  // и тогда можно делать разные реализации...

  // модификаторы
  df.add_column = add_column.bind( undefined, df );
  df.remove_column = remove_column.bind( undefined, df );
  df.get_column_names = get_column_names.bind( undefined, df );
  df.get_column = get_column.bind( undefined, df );
  df.get_length = get_length.bind( undefined, df );
  df.get_rows = get_rows.bind( undefined, df );

  // аксессоры

  return df;
}

export function add_column( df, name, values, position=10000 ) {
  if (df.colnames.indexOf(name) < 0)
  {
    if (position < 0)
      df.colnames.unshift( name );
    else if (position >= df.colnames.length)
      df.colnames.push( name );
    else
      df.colnames.splice( position, 0, name );
  }
  values ||= [];
  df[name] = values;
  if (values.length > df.length) df.length = values.length;
  return df;
}

export function remove_column( df, name ) {
  delete df[name];
  let ind = df.colnames.indexOf(name) 
  if (ind >=0 )
    df.colnames.splice( ind,1 );
  update_length( df );
}

export function get_column_names( df ) {
  return df.colnames;
}

export function get_column( df, name ) {
  return df[name];
}

export function is_df( df ) {
  if (df && df.isDataFrame) return true;
  return false;
}

export function set_length( df, len ) {
  df.length = len;
}

export function get_length( df ) {
  return df.length;
}

export function set_column_type_string( df, name ) {
  df.string_columns[ name ] = true
}

export function is_string_column( df, name ) {
  return df.string_columns[ name ] ? true : false
}

///////////////////////////////////////////
// algos
///////////////////////////////////////////

export function create_from_hash( hash ) {
  var r = create();
  import_hash( r, hash );
  return r;
}

export function import_hash( r, hash ) {
  Object.keys(hash).forEach( function(name) {
      add_column( r, name, hash[name] );
  });
}

export function update_length( df ) {
  var cn = get_column_names( df )[0];
  var col = get_column( df, cn );
  if (col) set_length( df, col.length );
  return df;
}

export function create_from_df( src ) {
  var r = create();

  get_column_names(src).forEach( function(name) {
      add_column( r, name, get_column(src,name).slice() );
  });

  return r;
}

export function clone( src ) {
  return create_from_df( src );
}

export function create_from_df_no_slice( src ) {
  var r = create();

  get_column_names(src).forEach( function(name) {
      add_column( r, name, get_column(src,name) );
  });

  return r;
}

// filter_func получает на вход аргумент - ассоциативный массив имяколонки->значение.
export function create_from_df_filter( src, filter_func ) {
  var r = create();
  var good_indices = [];
  var len = get_length( src );

  var conames = get_column_names(src);
  var line = {};

  for (var i=0; i<len; i++) {
    // подготовим строку
    conames.forEach( (name) => line[name] = get_column(src,name)[i] );
    // вызовем функцию
    var res = filter_func( line );
    if (res) good_indices.push( i );
  }

  // скопируем найденные значения
  get_column_names(src).forEach( function(name) {
    var col = get_column(src,name);
    var newcol = new Array( good_indices.length ); // todo поработать с колонками float32..
    for (var j=0; j<good_indices.length; j++)
      newcol[j] = col[ good_indices[j] ];
    add_column( r, name, newcol );
  });

  return r;
}

// здесь ф-я на вход получает просто df... 
// ну по уму она должна выдать новый df... но можно индексами...
// но если я хочу это в интерфейс вытаскивать то наверное пусть таки построчно работает
// а там видно будет. однострочную ф-ю проще написать..
export function create_from_df_filter_fast( src, filter_func ) {
  var r = create();
  var good_indices = [];
  var len = get_length( src );

  var conames = get_column_names(src);
  var acc = {};

  for (var i=0; i<len; i++) {
    // подготовим строку
    // conames.forEach( (name) => line[name] = get_column(src,name)[i] );
    // вызовем функцию
    var res = filter_func( src, i ); // acc можно будет передавать..
    if (res) good_indices.push( i );
  }

  // скопируем найденные значения
  get_column_names(src).forEach( function(name) {
    var col = get_column(src,name);
    var newcol = new Array( good_indices.length ); // todo поработать с колонками float32..
    for (var j=0; j<good_indices.length; j++)
      newcol[j] = col[ good_indices[j] ];
    add_column( r, name, newcol );
  });

  return r;
}

// оставляет только каждую step-тую строку
export function skip_every( src,step ) {
  var r = create();

  get_column_names(src).forEach( function(name) {
    var newarr = [];
    var origarr = get_column(src,name);
    if (step > 0) // мало ли какой step прислалил, зависать мы не должны
      for (var i=0; i<get_length(src);i += step) newarr.push( origarr[i] );
    add_column( r, name, newarr );
  });

  return r;
}

// выполняет slice на всех колонках
export function slice( src, index0, index1 ) {
  var r = create();

  get_column_names(src).forEach( function(name) {
      add_column( r, name, get_column(src,name).slice(index0,index1) );
  });

  return r;
}

// конвертирует df в массив
// вытаскивая из него указанную строчку
export function get_rows( src, index, length_idea=1,columns=null ) {
  let acc = [];
  if (!columns) {
    columns = get_column_names(src);
    columns.forEach( function(name) {
        let coldata = src[name];
        acc.push( coldata[index] );
    });  
  }
  else
  {
    columns.forEach( function(name) {
        let coldata = src[name];
        if (coldata)
          acc.push( coldata[index] );
        else
          acc.push( undefined );
    });
  };

  return acc;
}