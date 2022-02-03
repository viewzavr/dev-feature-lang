load files="lib3dv3 csv params io gui render-params df misc scene-explorer-3d";

dat : load-file file="a.csv" | parse_csv;
 
render3d target=@view1 bgcolor=[1,1,1] {
  axes_box; 
  orbit_control; camera3d pos=[0,40,40] center=[0,0,0];

  @dat | points radius=@sl->radius;  
};
 
screen auto_activate {
  sl: slider min=10 max=100 step=5 value=10;
  view1: view3d fill_parent;
};

debugger_screen_r;

////////////////////////////////// порисуем оси
//////////////////////////////////
//////////////////////////////////

// большие вопросы - что есть axes_box, что мы от него хотим
register_feature name="axes_box" {
  root: node3d input=@..->output; {
    axes_lines color=[ 0.2, 0.2, 0.2 ] size=@ds->output;

    //text3d_one color=[ 0.2, 0.2, 0.2 ] text=@ds->output;
    axes_titles color=[ 0.2, 0.2, 0.2 ] s=@ds->output size=1;
    // хорошее место чтобы воткнуть модификатор аргумент, todo
    // в т.ч. названия осей (через модификатор!)
    // тогда мы сможем рулить этим вопросом не приходя в сознание
    // напрямую, не создавая прокси-свойств в axes_box
    // это мб непривычно, но это прямое управление - играет на произведение функций!
    // кстати!!!!

    ds: compute_data_radius input=@root->input except=@root->output;
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