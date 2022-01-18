load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc svg";

register_feature name="random" code=`
  env.setParam( "output", Math.random() )
`;

register_feature name="num_mul" code=`
  env.onvalues(["input","coef"],(input,c) => {
    env.setParam( "output", input*c )  
  });
`;

config: N=5;

//rect width=30 height=30 x=(compute_output code=`Math.random()*100`) y=(random max=100)
scr: screen auto_activate {
  column padding="1em" gap="0.5em" {
    text text="number of squares";
    sl1: input_float value=@config->N;
    button text="get svg file" {
      download_svg input=@svg1;
    }
  };

  svg1: svggroup fill_parent dom_viewBox="0 0 100 100" dom_style_z-index=-1 {

    rect width=100 height=100 fill="white";
    repeater model=@sl1->value
    {
      //rect width=10 height=10 x=50 y=(random | num_mul coef=100); 
      rect width=10 height=10 x=(random | num_mul coef=90) y=(random | num_mul coef=90)
        {{ krasivoe; }}
        //greeny browny
      ;
    };
  };
};

// вот тут мы видим ситуацию когда порождающий узел мог бы и развернуться
// в итоговые узлы...
register_feature name="krasivoe" {
  debugger {{
    set_param target="..->fill" value="lightgrey" ;
    set_param target="..->stroke" value="black";
    set_param target="..->stroke_width" value=0.1;
  }};
  //fill="lightgrey" stroke="black" stroke_width=0.1;
};

register_feature name="greeny" {
  fill="green" 
  stroke="darkgreen";
};

register_feature name="browny" {
  set_param name="fill" value="grey";
};

debugger_screen_r;

find-objects pattern="** rect krasivoe" 
  | console_log text="###################### found rects:" 
  | deploy_features features={ browny };