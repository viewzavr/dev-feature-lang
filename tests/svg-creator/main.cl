load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc svg set-params";

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
    button text="get svg file" {
      download_svg input=@svg1;
    };
    text text="Tools";
    button text="Add rect" {
      creator target=@svg1 input={
        rect width=10 height=10 x=50 y=50 fill="green" stroke="grey" krasivoe {{ dbg }}
      };
    };

/*
    button text="info" {
      func svg=@svg1 code=`
        debugger;
        console.log( env.params.svg.dom.getClientRect() );
      `;
    }
*/    
  };

  svg1: svg-group fill_parent viewbox="0 0 100 100" dom_style_z-index=-1 {

    rect width=100 height=100 fill="white";
    
  };
};

debugger_screen_r;

find-objects pattern="** krasivoe" | console_log | deploy_features features={
   hitmove {{
     connection event_name="start" {
       func hm=@hitmove code=`
         //console.log("start",args[0])
         let hm = env.params.hm;
         let obj = env.params.hm.host;
         hm.startmove = [obj.params.x,obj.params.y];
       `;
     };
     connection event_name="moving" {
       func hm=@hitmove canv=@svg1 code=`
         //console.log(args[0])
         let hm = env.params.hm;
         let obj = env.params.hm.host;

         let bb = env.params.canv.dom.getBoundingClientRect();
         let kx = 100 * args[0].dx / bb.width;
         let ky = 100 * args[0].dy / bb.height;
         
         obj.setParam("x", hm.startmove[0] + kx );
         obj.setParam("y", hm.startmove[1] + ky );
       `;
     };
  }};
};
// ээх компонент нет