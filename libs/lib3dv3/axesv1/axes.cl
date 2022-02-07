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