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

register_feature name="svg-group" {
 main:  svg tag="svg" dom_x=@.->x dom_y=@.->y dom_z=@.->z
            dom_width=@.->width dom_height=@.->height
            x=0 y=0 z=0
            dom_viewBox=@.->viewbox
            ;
};

register_feature name="svg-text" {
  svg tag="text" svg-attrs-to-dom
     // идея на будущее
     //{{ svg-attrs-to-dom list={ а:а1, б:б1, .... }}
     dom-font-family=@.->font-family
     dom-font-size=@.->font-size
     innerText=@.->text;
};
//<text x="0" y="50" font-family="Verdana" font-size="35" fill="blue">Hello</text>

register_feature name="svg-attrs-to-dom" {
   dom_fill=@.->fill
   dom_stroke=@.->stroke
   dom_stroke-width=@.->stroke_width
   dom_x=@.->x
   dom_y=@.->y
   dom_z=@.->z
   dom_width=@.->width
   dom_height=@.->height
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