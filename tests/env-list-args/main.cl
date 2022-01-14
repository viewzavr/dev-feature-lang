load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

register_feature name="rslider" {
  rect width="300px" height="20px" color="blue" value=0
       item={ rect width="40px" height="40px" color="green";}
  {
    deploy input=@..->item dom_style_position="relative" y="-12px" {{
      deploy input=@..->item_features;
      //set_param name="x" value=0;

      //rect width="40px" height="40px" color="green" dom_style_position="relative" y="-12px" {{
      //attach_features input=@..->item_features;
/*
      compute param="x" v=@..->value w=@..->width mw=@.->width 
              code=`
                console.log("ddd uuu"); 
                feature_env.params.v * (parseFloat(feature_env.params.w) - parseFloat(feature_env.params.mw)) + "px"
              `;
      ;
*/
      onevent name="remove" {
        func code="debugger";
      };

      dom_event name="pointerdown" code=`
        env.setParam("dragging",true);
        env.setParam("drag_start_screen_x",args[0].screenX );
        // element.getBoundingClientRect();
        env.setParam("drag_start_x",parseFloat(env.params.x || 0) );
        env.dom.setPointerCapture( args[0].pointerId );
        console.log("SETTED DSX",args[0].screenX);
        args[0].preventDefault();
      `;

      dom_event name="pointerup" code=`
        env.setParam("dragging",false);
        args[0].preventDefault();
      `;

      dom_event name="pointermove" code=`
        if (env.params.dragging) {
          args[0].preventDefault();

          var event_data = args[0];
          
          //console.log(args);
          var maxx = parseFloat( env.ns.parent.params.width ) - parseFloat( env.params.width );
          var newx = event_data.screenX - env.params.drag_start_screen_x + env.params.drag_start_x;
          //debugger;
          //console.log("eeee",newx,maxx,env.params.width);
          if (newx < 0) newx = 0;
          if (newx > maxx) newx = maxx;
            //console.log("setting",newx + "px")
          env.setParam("x", newx + "px");
          //console.log("ddd vv",newx / maxx); 
          
          env.ns.parent.setParam( "value",newx / maxx );
        }
      `;

    }};
  };
};

screen auto_activate padding="1em" {
  sl1: rslider x="50px" y="150px" 
       item_features={
           //set_param name="color" value="yellow";
           //alter_shape shape="round"; 
           // https://developer.mozilla.org/ru/docs/Web/CSS/clip-path
           //set_param name="dom_style_clipPath" value="circle(50%)";
           clipping value="circle(55%)";
       }
       {{ set_param name="color" value="brown";
       }}
       //item={ button text="HI" width="50px" height="30px" color="cyan" dom_style_position="absolute";}
       item={ rect width="20px" height="50px" color="cyan";}
  {
    rect width="200px" color="white"
         {{ 
            compute param="width" in1=@sl1->value in2=@sl1->width code=`
              env.params.in1 * parseFloat(env.params.in2) + "px";
            `;
         }};
    /*
    text style="position:absolute;top:0px; left:0px;" {{
       // text=@sl1->value
      compute param="text" in=@sl1->value code=`
         feature_env.hasParam("in") ? feature_env.params.in.toFixed(2) : feature_env.params.in`;
    }};
    */
  };
  

/*
  r1: rect width="50px" height="50px" x="100px" y="100px"
        color="red" border_color="blue" ;

  r2: rect color="white" border_color=@r1->border_color 
    {{
      right to=@r1;
      y_line to=@r1;
      //clicked code=`env.setParam("color","blue");`;
      clicked {
        setter target="@r2->color" value="blue";
      };
      size width="200px" height="20px";
      label {
        row {
          text text="Privet";
          badge image="1.png";
        }
      }
    }};

   // rect color="yellow" modifiers={ right to=@r2 };
   // rect color="yellow" + right to=@r2;
   rect color="yellow" 
      {{
      l2: left to=@r1;
          y_line to=@r2;

      clicked code=`env.setParam("color","blue");`;
      }};
*/

};

register_feature name="clicked" {
    func 
    {{ js code=`
       let monitored_dom;
       env.host.onvalue("dom",(dom) => {
          unsub();
          dom.addEventListener( "click", f);
       })
       function f() {
          env.callCmd("apply");
          //if (feature_env.params.cmd) 
          //feature_env.callCmdByPath(feature_env.params.cmd);
       }
       function unsub() {
          if (monitored_dom)
              monitored_dom.removeEventListener( "clicked", f);
          monitored_dom = null;
       }
       env.on("remove",unsub);
    `;
  }}
};

register_feature name="rect" {
  dom dom_style_backgroundColor=@.->color 
      dom_style_borderColor=@.->border_color
      dom_style_width=@.->width 
      dom_style_height=@.->height
      dom_style_left=@.->x
      dom_style_top=@.->y
      width="10px" height="10px"
      border_color=@.->color
      //style="display: block;"
      dom_style_display="block"
      dom_style_position="absolute"
      dom_style_borderStyle="solid"
      x="0px" y="0px"
      ;
};

register_feature name="right" {
  js code='
    
    console.warn("right feature code called");
    let u1=()=>{};
    let u2=()=>{};

    u1 = env.onvalue("to",(other) => {
       u2();
       u2 = other.onvalues( ["x","width"], (x,w) => {
          env.host.setParam("x", `calc(${x} + ${w})` );
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
             env.setParam("x", `calc(${x} - ${myw})` );
          });
       });
    });
    env.on("remove",() => { u1(); u2(); u3(); })
  ';
};

register_feature name="y_line" {
  js code='
    console.warn("y-line code called");
    let u1=()=>{};
    let u2=()=>{};
    let u3=()=>{};
    u1 = env.onvalue("to",(other) => {
       u2();
       u2 = other.onvalues( ["y","height"], (y,h) => {
          u3();
          u3 = env.host.onvalue( "height",(myh) => {
            env.setParam("y", `calc(${y} + ${h}/2 - ${myh}/2)` );
          });
       });
    });
    env.on("remove",() => { u1(); u2(); u3(); })
  ';
};

register_feature name="size" {
  js code=`
    console.warn("'size' feature code called");

    env.onvalue("width",(v) => {
      console.log("SIZE feature is assigning width",v)
      //if (v == "200px") debugger;
      //env.setParam("dom_style_width",v)
      env.host.setParam("width",v)
    });
    env.onvalue("height",(v) => env.setParam("height",v));
    
    //env.setParam("dom_style_width",  feature_env.getParam("width") );
    //env.setParam("dom_style_height", feature_env.getParam("height") );
  `;
};

register_feature name="clipping" 
{
  set_param name="dom_style_clipPath" value="circle(50%)";
};

scene-explorer-screen;
apply_by_hotkey hotkey='b' {
  rotate_screens;
};