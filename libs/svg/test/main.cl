load files="csv params io gui render-params df scene-explorer-3d misc svg";

screen auto_activate {
  text text="Hello";

  свггруппа занять_родителя {
    штука1: 
       абстракция_номер_2;

    абстракция_номер_2 {{ 
      справа от=@штука1; 
    }};

    svg tag="circle" dom_cx=50 dom_cy=50 dom_r=30 dom_fill="red" dom_stroke="blue" dom_stroke-width="5";           

    /*
    svg tag="rect" dom_x=50 dom_y=50 dom_width=30 dom_height=120 
           dom_fill="red" dom_stroke="blue" dom_stroke-width="5";
    */           
  };

};

//новое имя="абстракция_номер_2" {
register_feature name="абстракция_номер_2" {  
  свггруппа подсчет_размеров {
    абстракция_номер_1 икс=0 игрек=0 {{ 
      сверху от=@кмал; 
      горизонталь как=@кмал; 
    }};
    кмал: квадрат_малевича икс=100 игрек=100 ширина=300;    
  };
};

register_feature name="абстракция_номер_1" {
 свггруппа подсчет_размеров {
    круг1: круг   цвет="зеленый" контур="orange" ширина_контура=5
                  центр_икс=50
                  центр_игрек=130
                  радиус=30
                  ;

    п1: прямоугольник цвет="голубой" ширина=150 высота=10 обводка="серый"
        {{ справа от=@круг1; 
           вертикаль как=@круг1; 
        }};

    круг цвет="#f5f5dc" радиус=15 {{ справа от=@п1; вертикаль как=@п1; }};

    квадрат ширина=50 {{ снизу от=@п1; горизонталь как=@п1; }};
  }
};

/// квадрат_малевича
register_feature name="квадрат_малевича" {
  гр: свггруппа высота=@.->ширина {
    квадрат цвет="черный" ширина="100%" высота="100%";
    квадрат цвет="белый" ширина="40%" икс="40%" игрек="40%";
  };
};

debugger_screen_r;

////////////////////// разное

register_feature name="fill_parent" {
  style="position: absolute; width:100%; height: 100%; left: 0px; top: 0px;"
};

///////////////////// примитивы

// проблема - вычисления вокруг circle в параметры пытаются записать ерунду (undefined и т.п.)
// и надо не пропускать эти записи - а то круг вычислений замыкается
// решение - поставим проверку check_finite которая будет пропускать данные если они норм числа
register_feature name="check_finite" {
  compute code=`
    env.onvalue("input",(i) => {
       if (isFinite(i))
         env.setParam("output",i);
    })
  `;
};

register_feature name="group" {
 main:  svg tag="g";
};

register_feature name="svggroup" {
 main:  svg tag="svg" dom_x=@.->x dom_y=@.->y dom_z=@.->z
            dom_width=@.->width dom_height=@.->height
            x=0 y=0 z=0
            ;
};

register_feature name="circle" {
 main:  svg tag="circle"
       dom_fill=@.->fill
       dom_stroke=@.->stroke
       dom_stroke-width=@.->stroke_width
       dom_r=@.->r
       dom_cx=@.->cx
       dom_cy=@.->cy
       x=(compute_output cx=@main->cx r=@main->r code=`return env.params.cx - env.params.r` | check_finite)
       y=(compute_output cy=@main->cy r=@main->r code=`return env.params.cy - env.params.r` | check_finite)
       width=(compute_output r=@main->r code=`return 2*env.params.r` | check_finite)
       height=@.->width
       // обратные расчеты - на случай если будут выставлять x,y
       cx=(compute_output x=@main->x r=@main->r code=`return env.params.x + env.params.r` | check_finite)
       cy=(compute_output y=@main->y r=@main->r code=`return env.params.y + env.params.r` | check_finite)

       x2=(compute_output x=@main->x w=@main->width code=`return env.params.x + env.params.w` | check_finite)
       y2=(compute_output y=@main->y h=@main->height code=`return env.params.y + env.params.h` | check_finite)
       ;

       // краткость qml:
       // cx: x+r
       // x: cx-r
};

register_feature name="rect" {
 main: svg tag="rect"
       dom_fill=@.->fill
       dom_stroke=@.->stroke
       dom_stroke-width=@.->stroke_width
       dom_width=@.->width
       dom_height=@.->height
       dom_x=@.->x
       dom_y=@.->y

       x2=(compute_output x=@main->x w=@main->width code=`return env.params.x + env.params.w` | check_finite)
       y2=(compute_output y=@main->y h=@main->height code=`return env.params.y + env.params.h` | check_finite)
       ;
};

register_feature name="square" {
  rect height=@.->width;
};

/////////////// соотношения CSS

/*
register_feature name="right" {
  js code='
    let u1=()=>{};
    let u2=()=>{};

    u1 = feature_env.onvalue("to",(other) => {
       //debugger;
       u2();
       u2 = other.onvalues( ["x","width"], (x,w) => {
          env.setParam("x", `calc(${x} + ${w})` );
          // это вопрос конечно.. может стоит фичу положения завести?..
          // и говорить типа env.subenvs.pos.setParam("x",...)
       });
    });

    feature_env.on("remove",() => { u1(); u2(); })
  ';
};

register_feature name="y_line" {
  js code='
    let u1=()=>{};
    let u2=()=>{};
    let u3=()=>{};
    u1 = feature_env.onvalue("to",(other) => {
       u2();
       u2 = other.onvalues( ["y","height"], (y,h) => {
          u3();
          u3 = env.onvalue( "height",(myh) => {
            env.setParam("y", `calc(${y} + ${h}/2 - ${myh}/2)` );
          });
       });
    });
    feature_env.on("remove",() => { u1(); u2(); u3(); })
  ';
};
*/

/////////////// соотношения

// кстати вот в QML была модель якорей.. и там бы мы писали: 
// Rect { anchors.left: other.right }
// ну у нас, наверное, так: rect {{ anchors left=@other->right; }}
// или в переводе на русский: rect {{ расположить лево=@круг->право }}
// прочем это звучит криво...

// ну и еще идея была: расположить что=@круг справа от=@квадрат;

register_feature name="right" {
  js code='
    let u1=()=>{};
    let u2=()=>{};

    u1 = env.onvalue("to",(other) => {
       
       u2();
       u2 = other.onvalues( ["x","width"], (x,w) => {
          env.host.setParam("x", parseFloat(x) + parseFloat(w) );
          // это вопрос конечно.. может стоит фичу положения завести?..
       });
    });

    env.on("remove",() => { u1(); u2(); })
  ';
};

register_feature name="left" {
  js code='
    let u1=()=>{};
    let u2=()=>{};
    let u3=()=>{};
    u1 = env.onvalue("to",(other) => {
       u2();
       u2 = other.onvalues( ["x"], (x) => {
          u3();
          u3 = env.host.onvalue( "width",(myw) => {
            env.setParam("x", parseFloat(x) - parseFloat(myw) );
          });
       });
    });
    env.on("remove",() => { u1(); u2(); u3(); })
  ';
};

register_feature name="bottom" {
  js code='
    let u1=()=>{};
    let u2=()=>{};

    u1 = env.onvalue("to",(other) => {
       //debugger;
       u2();
       u2 = other.onvalues( ["y","height"], (y,h) => {
          env.host.setParam("y", parseFloat(y) + parseFloat(h) );
          // это вопрос конечно.. может стоит фичу положения завести?..
       });
    });

    env.on("remove",() => { u1(); u2(); })
  ';
};

register_feature name="top" {
  js code='
    let u1=()=>{};
    let u2=()=>{};
    let u3=()=>{};
    u1 = env.onvalue("to",(other) => {
       u2();
       u2 = other.onvalues( ["y"], (y) => {
          u3();
          u3 = env.host.onvalue( "height",(myh) => {
            env.host.setParam("y", parseFloat(y) - parseFloat(myh) );
          });
       });
    });
    env.on("remove",() => { u1(); u2(); u3(); })
  ';
};

// выравнивает по y-центру
register_feature name="y_align" {
  js code='
    let u1=()=>{};
    let u2=()=>{};
    let u3=()=>{};
    u1 = env.onvalue("to",(other) => {
       u2();
       u2 = other.onvalues( ["y","height"], (y,h) => {
          u3();
          u3 = env.host.onvalue( "height",(myh) => {
            env.host.setParam("y", parseFloat(y) + parseFloat(h)/2 - parseFloat(myh)/2 );
          });
       });
    });
    env.on("remove",() => { u1(); u2(); u3(); })
  ';
};

// выравнивает по x-центру
register_feature name="x_align" {
  js code='
    let u1=()=>{};
    let u2=()=>{};
    let u3=()=>{};
    u1 = env.onvalue("to",(other) => {
       u2();
       u2 = other.onvalues( ["x","width"], (x,w) => {
          u3();
          u3 = env.host.onvalue( "width",(myw) => {
            env.host.setParam("x", parseFloat(x) + parseFloat(w)/2 - parseFloat(myw)/2 );
          });
       });
    });
    env.on("remove",() => { u1(); u2(); u3(); })
  ';
};

register_feature name="compute_width_height" {
  js code=`
    env.feature("delayed");
    var delayed_f = env.delayed(f)
    var delayed_monitor_children = env.delayed(monitor_children)
    env.on('appendChild',delayed_monitor_children);

    delayed_f();
    delayed_monitor_children();

    // организуем пересчет. спасибо getBBox
    function f() {
       if (!env.dom) return;
       /*
       let box = env.dom.getBBox();
       debugger;
       env.setParam("width",box.width);
       env.setParam("height",box.height);
       */
      let rect={x:0,y:0,x2:0,y2:0}
      for (let c of env.ns.getChildren()) {
        let mx = (c.params.x||0) + c.params.width;
        if (isFinite(mx))
          rect.x2 = Math.max( rect.x2, mx );
        let my = (c.params.y||0) + c.params.height;
        if (isFinite(my))
          rect.y2 = Math.max( rect.y2, my );
      }
      env.setParam("width",rect.x2);
      env.setParam("height",rect.y2);
    }
    
    // ставим мониторинг изменениев размеров дитей
    let acc = [];
    let unsub_func = () => {
        acc.forEach( (a) => a.apply() );
        acc = [];
    };
    function monitor_children() {  
      unsub_func();
      acc = [];
      for (let c of env.ns.getChildren()) {
        let sub = c.onvalues_any(["x","y","width","height"],() => {
           delayed_f();
        });
        acc.push( sub );
      }
    }
  `;
};

/////////////// перевод цветов на русский язык

register_feature name="translate_color" {
  compute code=`
    let colors = {
      "красный":"red",
      "синий":"blue",
      "зеленый":"green",
      "фиолетовый":"purple",
      "оранжевый" :"orange",
      "голубой":"cyan",
      "серый":"grey",
      "белый":"white",
      "черный":"black"
    }; 
    // todo может быть стоит найти какую-то библиотеку цветов?

    // такая идея = вот мы эту таблицу тут копим. а хотелось бы уметь еще доп-ом ее распределенно копить
    // итого нужна операция "добавить-в-таблицу( цветов, новые-записи )"
    
    env.onvalue("input",(c) => {
      
      let res = colors[c] || c;
      env.setParam("output",res);
    })
  `;
};

////////////// перевод примитивов и их параметров на русский язык

register_feature name="новое" {
  register_feature name=@.->имя;
};

register_feature name="группа" {
   group;
};

register_feature name="занять_родителя" {
   fill_parent;
};

register_feature name="свггруппа" {
   svggroup
       x=@.->икс
       y=@.->игрек
       z=@.->зет
       width=@.->ширина
       height=@.->высота
       ;
};

register_feature name="круг" {
   circle
       fill=(translate_color input=@.->цвет)
       stroke=(translate_color input=@.->цвет_контура)
       cx=@.->центр_икс
       cy=@.->центр_игрек
       r =@.->радиус
       stroke_width=@.->ширина_контура
       ;
};

register_feature name="прямоугольник" {
   rect
       fill=(translate_color input=@.->цвет)
       stroke=(translate_color input=@.->цвет_контура)
       x=@.->икс
       y=@.->игрек
       width=@.->ширина
       height=@.->высота
       stroke_width=@.->ширина_контура
       ;
};

register_feature name="квадрат" {
  прямоугольник высота=@.->ширина цвет="красный";
};

register_feature name="справа" {
  right to=@~->от;
};

register_feature name="слева" {
  left to=@~->от;
};

register_feature name="сверху" {
  top to=@~->от;
};

register_feature name="снизу" {
  bottom to=@~->от;
};

register_feature name="вертикаль" {
  y_align to=@~->как;
};

register_feature name="горизонталь" {
  x_align to=@~->как;
};

register_feature name="подсчет_размеров" {
  compute_width_height;
};

