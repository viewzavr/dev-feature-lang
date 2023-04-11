/////////////////////////////////////////////////// axes

// axes box рисует оси и подписи заданного размера
// size - размер
// пример: axes_box size=10;

coview-record title="Оси координат" type="axes-view" cat_id="gr3d"

feature "axes_view" {
  root: node3d size=10 gui={ paint-gui @root } ~layer_object title="Оси координат" axes_titles=@axes_titles
  {

    gui {
      gui-tab "main" {
        gui-slot @root "size" gui={ |in out| gui-slider @in @out }
        //render-params input=@root
      }
      /*
      gui-tab "Вектора" {
        render-params input=@axes_lines
      }
      gui-tab "Подписи" {
        //render-params input=@axes_titles
        paint-gui @axes_titles
      }
      */
    }

  	//size: param_slider min=0 max=100 step=1;

    axes_lines: axes_lines2 title="Вектора"
      color=@root->color? size=@root->size

    //text3d_one color=[ 0.2, 0.2, 0.2 ] text=@ds->output;
    axes_titles: axes_titles2 title="Подписи"
      color=@root->color? s=@root->size size=(@root->size / 10)

    // хорошее место чтобы воткнуть модификатор аргумент, todo
    // в т.ч. названия осей (через модификатор!)
    // !! имеется ввиду что у axes_box был бы аргумент - модификатор для axes_titles и axes_lines
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
feature "axes_lines2" {
  l: lines ~layer_object
    positions=(compute_output s=@l->size code=`
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
feature "axes_titles2" {
  t: text3d ~layer_object
    names="X Y Z"
    lines=(eval @t->names code=`(str) => str.split(/\s+/)`)
    positions=(eval @t->s code=`(s) => {
    if (!isFinite(s)) return [];
    return [ s,0,0,
             0,s,0,
             0,0,s
     ]
    }`;)
    {
      //ps: param_string name="names" value="X Y Z";

      gui {
        gui-tab "main" {
          gui-slot @t "names" gui={ |in out| gui-string @in @out }
          render-params @t
        }
      }
    }
};
