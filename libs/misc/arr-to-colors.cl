// по входному массива и выбранной колонке строит массив цветов
// input - массив
// color_func - функция раскрашивания
register_feature name="arr_to_colors" {
  root: color_func=(color_func_white) output=@color_arr->output min=@mm->min max=@mm->max 
    {{ x-param-option name="reset" option="priority" value=110 }}
    {{ x-param-option name="help" option="priority" value=0 }}
    {
    mm: arr_find_min_max input=@root->input;


    param_float name="min" ;
    param_float name="max" ;
    param_cmd name="reset" {
       setter target="@root->min" value=@mm->min;
       setter target="@root->max" value=@mm->max;
    };
    
    //param_label name="help" value="Выбор мин и макс<br/>значения для раскраски";
    
    color_arr: js input=@root->input cf=@root->color_func min=@root->min max=@root->max code=`
      env.onvalues(["input","cf","min","max"], (input,cf,min,max) => {
        let diff = max-min;

        let acc = new Float32Array( input.length*3 );
        
        for (let i=0,j=0; i<input.length; i++,j+=3) {
          let t = (input[i] - min) / diff;
          cf( t, acc, j );
        }
        env.setParam( "output", acc );
      })
    `;

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

