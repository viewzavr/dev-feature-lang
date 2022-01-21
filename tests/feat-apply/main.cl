load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc svg set-params";

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
    button text="regenerate" cmd=@rep->refresh;
    button text="get svg file" {
      download_svg input=@svg1;
    };
    cb_bro: checkbox text="1. Browny";
    cb_gre: checkbox text="2. Greeny";
  };

  svg1: svg-group fill_parent viewbox="0 0 100 100" dom_style_z-index=-1 {

    rect width=100 height=100 fill="white";
    rep: repeater model=@sl1->value
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
  env {{
    set_param target="..->fill" value="lightgrey" ;
    set_param target="..->stroke" value="black";
    set_param target="..->stroke_width" value=0.1;
  }};
  // вот так вообще-то гораздо удобнее:
  //fill="lightgrey" stroke="black" stroke_width=0.1;
  // можно вот попробвоать будет: assign p1=.. p2=... и это есть выставление хосту параметров..
  // по сути это как set_params
  // но в целом конечно вопросы - зачем писать setparams если можно быб вообще не писать?
};

register_feature name="greeny" {
  fill="green" 
  stroke="darkgreen";
};

register_feature name="browny" {
  env {{
    set_param target="..->fill" value="brown";
  }};
};

debugger_screen_r;

/*
find-objects pattern="** rect krasivoe" 
  | console_log text="###################### found rects:" 
  | deploy_features features={ browny };
*/

/* работает
find-objects pattern="** rect krasivoe" 
  | console_log text="###################### found rects:" 
  | deploy_features features={
      set_param target=".->fill" value="brown";
    };
*/

/* работает
// вариант с фильтрацией
find-objects pattern="** rect krasivoe" 
  | console_log text="###################### found rects 1:" 
  | arr_filter code="(val,index) => index%2>0"
  | console_log text="###################### rects filtered:"
  | deploy_features features={
      set_param target=".->fill" value="brown";
    };
*/

if condition=@cb_bro->value {
find-objects pattern="** rect krasivoe" 
  | console_log text="###################### found rects 1:" 
  | arr_filter code="(val,index) => index%2>0"
  | console_log text="###################### rects filtered:"
  | deploy_features features={
      set_params fill="brown";
      // browny;
      //set_param target=".->fill" value="brown";
    };
};

if condition=@cb_gre->value {
find-objects pattern="** rect krasivoe" 
  | console_log text="###################### found rects 1:" 
  | arr_filter code="(val,index) => index%3 == 0"
  | console_log text="###################### rects filtered:"
  | deploy_features features={
      set_params fill="green";
    };
};


register_feature name="arr_filter" 
  code=`
  env.onvalues(["input","code"],process);

  function process(arr,code) {
    if (!Array.isArray(arr)) {
      env.setParam("output",[]);
      return;
    }
    //var f = new Function( "line", code );
    //var res = dfjs.create_from_df_filter( df, f );
    
    var f = eval( code );

    let res = [];
    arr.forEach( (v,index) => {
       let check = f( v,index );
       if (check) res.push( v );
    })
    env.setParam("output",res);
  }
`;