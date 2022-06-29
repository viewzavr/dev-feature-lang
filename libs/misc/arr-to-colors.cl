// по входному массива и выбранной колонке строит массив цветов
// input - массив
// color_func - функция раскрашивания
register_feature name="arr_to_colors" {
  root:  {{ console_log_life "EEE"}}
     color_func=(color_func_white) 
     output=@color_arr->output 

    {{ x-param-option name="recalculate" option="priority" value=110 }}
    {{ x-param-option name="help" option="priority" value=0 }}
    {{ x-param-vector name="minmax" }}
    {{ x-param-vector name="minmax_computed" }}
    {{ x-param-option name="minmax_computed" option="readonly" value=true }}

    {{ x-param-option name="datafunc" option="priority" value=120 }}
    {{ x-param-combo name="datafunc" values=["linear","log","sqrt", "sqrt4", "sqrt8"] 
        titles=["Линейная","Логарифм","Корень","Корень^4","Корень^8"]
    }}
    
    data_func_f =( m_eval "(type) => {
        let t = { log: (x) => Math.log(1+x),
         sqrt: (x) => Math.sqrt(x),
         sqrt4: (x) => Math.sqrt( Math.sqrt(x) ),
         sqrt8: (x) => Math.sqrt( Math.sqrt( Math.sqrt(x) ))
        };
        return t[type] || ((x)=>x);
      }" @root->datafunc)

    minmax_computed=@mm->output
    {
    mm: arr_find_min_max input=@root->input;
    
    param_cmd name="recalculate" {
       setter target="@root->minmax" value=@mm->output;
    };
    param_checkbox name="auto_calculate" value=true;

    if (@root->auto_calculate) then={
       setter target="@root->minmax" value=@mm->output auto_apply;
    };
    
    //param_label name="help" value="Выбор мин и макс<br/>значения для раскраски";
    
    color_arr: m_eval `(input,minmax,colorfunc,datafunc) => {

        let min = minmax[0];
        let max = minmax[1];
        let diff = max-min;

        let acc = new Float32Array( input.length*3 );
        //console.log('minmax',minmax)

        //let f = (x) => Math.log(1+x);
        let f = (x) => Math.sqrt( Math.sqrt(x) );
        diff = datafunc(diff);
        
        for (let i=0,j=0; i<input.length; i++,j+=3) {
          let t = datafunc(input[i] - min) / diff;
          colorfunc( t, acc, j );
        }
        return acc;
    }` @root->input @root->minmax @root->color_func @root->data_func_f;

  };

};

register_feature name="color_func_red" code=`
  let f = function( t, acc, index ) {
     acc[index] = t;
  }
  env.setParam("output",f);
`;

register_feature name="color_func_white" code=`
  let f = function( t, acc, index ) {
     acc[index] = t;
     acc[index+1] = t;
     acc[index+2] = t;
  }
  env.setParam("output",f);
`;

// идеи - функция из функций, например логарифм и затем раскраска
// конструктор функций с гуи.. (можно даже чистым dom)
// просто выбиралка функций (можно из 2х стадий - расчет и раскраска) (на параметрах)
// ...

// ................................ старое

/*
register_feature name="arr_to_colors_10" {
  compute_output color_func=(color_func_red) code=`
      env.onvalues(["input","color_func"], (input,cf) => {
        acc = new Float32Array( input.length*3 );
        for (let i=0,j=0; i<input.length; i++,j+=3) {
          let t = input[i];
          cf( t, acc, j );
        }
        env.setParam( "output", acc );
      })
    `;  
};


// по входному dataframe и выбранной колонке строит массив цветов
// input - dataframe
// column - имя колонки
register_feature name="df_to_colors" {
  root: color_func=@red->output output=@color_arr->output {
    datacol: df_get column=@..->column;
    @datacol | mm: arr_find_min_max;
    
    @datacol | color_arr: compute_output cf=@root->color_func min=@mm->min diff=@mm->diff code=`
      debugger;
      env.onvalues(["input","cf","min","diff"], (input,cf,min,diff) => {
        debugger;
        acc = new Float32Array( input.length*3 );
        for (let i=0,j=0; i<input.length; i++,j+=3) {
          let t = min + diff * input[i];
          cf( t, acc, j );
        }
        env.setParam( "output", acc );
      })
    `;

    red: color_func_red;

  };
};

register_feature name="arr_to_colors" {
  {
    norm: normalize_array input=@..->input;
    arr_to_colors_10 input=@norm->output;
  }
};

*/

/*
    // df_get column=@..->column | rescale_to_01 | map code=@root->color_func;
    //df_extract columns=@..->column | df_map column=@..->column code="(line) => env.params.min + (env.params.max - env.params.min) * line.value;"

*/

