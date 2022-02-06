/////////////////////////////////////////////////// axes

// axes box рисует оси и подписи заданного размера
// size - размер
// пример: axes_box size=10;

register_feature name="axes_box" {
  root: node3d 
  {

  	size: param_slider min=0 max=100 step=1;

    axes_lines color=@root->color? size=@root->size include_gui;

    //text3d_one color=[ 0.2, 0.2, 0.2 ] text=@ds->output;
    axes_titles color=@root->color? s=@root->size size=1 include_gui;

    // хорошее место чтобы воткнуть модификатор аргумент, todo
    // в т.ч. названия осей (через модификатор!)
    // тогда мы сможем рулить этим вопросом не приходя в сознание
    // напрямую, не создавая прокси-свойств в axes_box
    // это мб непривычно, но это прямое управление - играет на произведение функций!
    // кстати!!!!

    // ds: compute_data_radius input=@root->input except=@root->output;
    // надо отдельно
  }
};

// рисует три линии осей координат
// вход size
register_feature name="axes_lines" {
  lines
    positions=(compute_output s=@.->size code=`
    let s = env.params.s;
    if (!isFinite(s)) return [];
    return [0,0,0, 0,0,s,
            0,0,0, 0,s,0,
            0,0,0, s,0,0
     ]
  `;)
};

// рисует подписи осям
// вход: s - сдвиг
register_feature name="axes_titles" {
  text3d
    lines=["X","Y","Z"]
    positions=(compute_output s=@.->s code=`
    let s = env.params.s;
    if (!isFinite(s)) return [];
    return [ 0,0,s,
             0,s,0,
             s,0,0
     ]
  `;)
};

/////////////////////////////////////////////////// mesh_visualizer0


register_feature name="mesh_visualizer0" {
   root: mesh input=@collected_df {

     collected_df: copy_params_to_obj {{dbg}} {
        link to=".->X" from=@input_data->X tied_to_parent=true;
        link to=".->Y" from=@input_data->Y tied_to_parent=true;
        link to=".->Z" from=@input_data->Z tied_to_parent=true;
     };

     connection object=@collected_df event_name="param_changed" root=@root code=`
       if (env.params.root) {
        env.params.root.signalTracked( "input" );
       }
     `;

     /*
     {
       call target=@root name="signalTracked"
       @root->signalTracked "input";
     }
     */

     input_data: include_gui {
       param_ref df_column_ref name="X";

       param_ref df_column_ref name="Y";
       param_ref df_column_ref name="Z";
     };
   };
};


/////////////////////////////////////////////////// mesh_visualizer

register_feature name="mesh_visualizer" {
   root: mesh {
     link to="..->input" from=@input_data->input;

     input_data: include_gui {
       param_ref df_ref name="input";
     };
   };
};

/////////////////////////////////////////////////// points_visualizer

register_feature name="points_visualizer" {
   root: points {
     link to="..->input" from=@input_data->input;

     input_data: include_gui {
       param_ref df_ref name="input";
     };
   };
};



