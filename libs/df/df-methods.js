export function setup(vz, m) {
  vz.register_feature_set( m );

/* idea:
  vz.compalang(`
      .......
`);
*/
}

// устанавливает колонки
// пример: df_set X=<значение> Y="->Z"
// тогда в колонке X будет константа указанного значения, а в Y - скопируется колонка Z
// тут set считается что в своем окружении и опирается на параметры этого окружения
export function df_set( env, opts ) {
 //Object.keys( args ) 
 env.trackParam("input",(value) => {
   if (!df.is_df(value)) return;

   var output = df.create_from_df_no_slice( value );

   var cols = env.getParamsNames();
   var colvals = env.params;
   // моно сделать фильтр что выставлено из языка
   for (let colname of cols) {
     var colvalue = colvals[colname];
     var colarr;
     if (typeof(colvalue) == "string" && colvalue.slice(0,2) == "->" ) {
        colarr = value[ colvalue.slice( 2 ) ] || []; // так-то get_column здесь..
     }
     else
        colarr = new Array( df.get_length(value) ).fill(colvalue); // так то тут выгоднее ставить функцию было бы
        // но для этого df должен уметь поддержать колонку-функцию
        // и кстати эта ф-я не обязана быть константой...
        // но надо решить вопросы с копированием тогда..

    df.add_column( output, colname, colarr );
   }
   env.setParam("output",output);
 })
 if (env.params.input) env.signalParam("input");
}

// параметр: count
// выбирает подстроки с шагом count
export function df_skip_every( env, opts ) {
 //Object.keys( args ) 
 env.trackParam("input",(value) => {
   if (!df.is_df(value)) return;
   if (!(env.params.count > 0)) return;
   var output = df.skip_every( value,env.params.count)
   env.setParam("output",output);
 })
 if (env.params.input) env.signalParam("input");
}

// выбирает подмножество строк
// start, count
export function df_slice( env, opts ) {
 //Object.keys( args )
 env.trackParam("input",(value) => {
   if (!df.is_df(value)) return;
   //if (!(env.params.step > 0)) return;
   var start = env.params.start || 0;
   var finish = (env.params.count > 0) ? start + env.params.count : value.length;
   var output = df.slice( value,start,finish)
   env.setParam("output",output);
 })
 if (env.params.input) env.signalParam("input");
}

// фильтр надо сделать по колонке..
