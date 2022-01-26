load files="lib3dv3 csv params io gui render-params df misc scene-explorer-3d";
// todo: уметь загружать lib3dv3/gltf-format

/// рендеринг 3D сцены

render3d bgcolor=[0.1,0.2,0.3] target=@view
{
    orbit_control;
    camera3d pos=[0,0,40] center=[0,0,0];

    dat: load_file_binary file="https://viewlang.ru/assets/lava2/ParticleData_Fluid_1192.vtk" | parse_vtk_points;

    @dat | points showparams dbg 
       {{ scale3d coef=0.05 showparams; 
          rotate3d showparams;
          color3d color=[0,1,0] showparams;
       }} colors=( @dat | df_get column=@cbcol->value | arr_to_colors showparams );

    points positions=[0,0,0,50,0,0,0,50,0];
};

/// интерфейс пользователя gui

screen auto-activate {

  column padding="1em" style="z-index: 3; position:absolute; background: rgba(255,255,255,0.5);" {
    find-objects pattern="** showparams" | render-guis with_features=true;

    bt: button text="get csv" {
      func {
        //setter target="@bt->dom_style_backgroundColor" value="cyan";
        //setter target="@bt->text" value="cyan";
        generate_csv input=(@dat | vtk_points_to_normalized_df) | download_file_to_user filename="lava.csv";
        //setter target="@bt->dom_style_backgroundColor" value="";
      };
    };

    text text="Select column to colorize";
    cbcol: combobox values=(compute_output in=@dat->output code=`return env.params?.in?.colnames`);
  };

  view: view3d style="position: absolute; width:100%; height: 100%; z-index:-2";

};

///////////////////// визуальная отладка

debugger_screen_r;

//////////////////// доп-ы


// по входному массива и выбранной колонке строит массив цветов
// input - массив
// color_func - функция раскрашивания
register_feature name="arr_to_colors" {
  root: color_func=(color_func_red) output=@color_arr->output dbg min=@mm->min max=@mm->max {
    mm: arr_find_min_max input=@root->input;

    param_float name="min" ;
    param_float name="max" ;
    param_cmd name="reset" {
       setter target="@root->min" value=@mm->min;
       setter target="@root->max" value=@mm->max;
    };
    
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

/*
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
    arr_to_colors_10 input=@norm-.output;
  }
};
*/

/*
    // df_get column=@..->column | rescale_to_01 | map code=@root->color_func;
    //df_extract columns=@..->column | df_map column=@..->column code="(line) => env.params.min + (env.params.max - env.params.min) * line.value;"

*/


register_feature name="color_func_red" code=`
  let f = function( t, acc, index ) {
     acc[index] = t;
  }
  env.setParam("output",f);
`;