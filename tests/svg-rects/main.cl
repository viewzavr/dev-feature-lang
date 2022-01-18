load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc svg";

register_feature name="random" code=`
  env.setParam( "output", Math.random() )
`;

register_feature name="num_mul" code=`
  env.onvalues(["input","coef"],(input,c) => {
    env.setParam( "output", input*c )  
  });
`;

//rect width=30 height=30 x=(compute_output code=`Math.random()*100`) y=(random max=100)
scr: screen auto_activate {
  column padding="1em" gap="0.5em" {
    //sl1: slider min=10 max=1000 step=10 sliding=false;
    text text="number of squares";
    sl1: input_float value=100;
    button text="get svg file" {
      download_svg input=@svg1;
    }
  };

  svg1: svg-group fill_parent dom_viewBox="0 0 100 100" dom_style_z-index=-1 {

    rect width=100 height=100 fill="white";
    repeater model=@sl1->value
    {
      //rect width=10 height=10 x=50 y=(random | num_mul coef=100); 
      rect fill="green" width=10 height=10 x=(random | num_mul coef=90) y=(random | num_mul coef=90)
        stroke="darkgreen"
      ;
    };
  };
};

debugger_screen_r;
