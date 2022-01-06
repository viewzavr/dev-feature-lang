load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

screen auto_activate padding="1em" {
  r1: rect width="50px" height="50px" x="100px" y="100px"
        color="red" border_color="blue" ;
  r2: rect color="white" border_color=@r1->border_color 
    {{
      //right to=@r1;
      //y_line to=@r1;
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
   rect color="yellow" {{ 
      right to=@r2 y_line;
      }};
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
      ;
};

register_feature name="right" {
  js code='
    
    console.warn("right feature code called");

    feature_env.onvalue("to",(other) => {
       other.onvalues( ["x","width"], (x,w) => {
          env.setParam("x", `calc(${x} + ${w})` );
       });
    });
  ';
};

register_feature name="left" {
  js code='
    feature_env.onvalue("to",(other) => {
       other.onvalues( ["x","width"], (x,w) => {
          env.onvalue( "width",(myw) => {
             env.setParam("x", `calc(${x} + ${w} - ${myw})` );
          });
       });
    });
  ';
};

register_feature name="y_line" {
  js code='
    console.warn("y-line code called");
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

register_feature name="size" {
  js code=`
    console.warn("'size' feature code called");

    feature_env.onvalue("width",(v) => {
      console.log("SIZE feature is assigning width",v)
      //if (v == "200px") debugger;
      //env.setParam("dom_style_width",v)
      env.setParam("width",v)
    });
    feature_env.onvalue("height",(v) => env.setParam("height",v));
    
    //env.setParam("dom_style_width",  feature_env.getParam("width") );
    //env.setParam("dom_style_height", feature_env.getParam("height") );
  `;
};

scene-explorer-screen;
apply_by_hotkey hotkey='b' {
  rotate_screens;
};