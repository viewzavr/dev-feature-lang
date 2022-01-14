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

/////////////// соотношения CSS 
// не прокатило, css не умеет вложенные calc( .... calc .... )

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