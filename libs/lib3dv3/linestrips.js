
import * as utils from "./utils.js";

export function setup(vz, m) {
  vz.register_feature_set( m );
}

// вот такая жизнь.. но есть надежда что на фиче-ланге это будет проще
export function linestrips( env ) {
  var convertor_env = env.create_obj({},{name:"convertor"});
  convertor_env.feature( "linestrips_to_lines" );
  convertor_env.linkParam( "input","..->input");
  var painter_env = env.create_obj({},{name:"lines-env"});
  painter_env.linkParam( "input","../convertor->output");
  painter_env.feature("lines");
  env.linkParam("output","lines-env->output");

  env.feature("param_mirror");
  for (var g of painter_env.getGuiNames()) {
    env.addParamMirror(g,"lines-env->"+g);
  };
  // типа потом еще могут добавить (так и оказвыается - lines не сразу применяются)
  painter_env.on("gui-added",(g) => {
    env.addParamMirror(g,"lines-env->"+g);
  })

  env.trackParam("color",(v) => {
    //console.log("LL:",v);
    //debugger;
  });

  env.trackParam("radius",(r) => {
    //console.log("r=",r)
  })

}

export function linestrip( env ) {
  return linestrips(env);
}

import * as df from "../df/df.js";

// идея - сведем к lines
// сделаем просто конвертор
export function linestrips_to_lines( env ) {
  env.trackParam("input",(dat) => {
    if (!df.is_df(dat)) {
      console.error( "linestrips_to_lines: incoming value is not df", dat)
      return
   };

    var prevn = -1;
    var vals = {X:[],Y:[],Z:[],X2:[],Y2:[],Z2:[],R:[],G:[],B:[],R2:[],G2:[],B2:[]}
    //var Nvals = dat.N ? dat.N : [];
    var Nvals = dat.N;
    for (var i = 0; i<dat.length; i++)
    {
      var n = Nvals ? Nvals[i] : -1;
      if (n == prevn) {
        if (i > 0) { // todo optimize
          vals.X.push( dat.X[i-1] );
          vals.Y.push( dat.Y[i-1] );
          vals.Z.push( dat.Z[i-1] );
          vals.X2.push( dat.X[i] );
          vals.Y2.push( dat.Y[i] );
          vals.Z2.push( dat.Z[i] );

          if (dat.R) {
            vals.R.push( dat.R[i-1] );
            vals.G.push( dat.G[i-1] );
            vals.B.push( dat.B[i-1] );
            vals.R2.push( dat.R[i] );
            vals.G2.push( dat.G[i] );
            vals.B2.push( dat.B[i] );
          }
        }
      }
      prevn = n;
    }
    if (!dat.R) vals.R=undefined;
    var newdf = df.create_from_hash( vals );
    env.setParam("output", newdf)
  });
  if (env.params.input) env.signalParam("input");
}

///////////////////// ??
function add_std( obj ) {
  obj.addArray("positions",[],3,function(v) {
    obj.positions = v;
  } );
  obj.setParamOption("positions","internal",true);
  
  obj.addArray("radiuses",[],1,function(v) {
    obj.radiuses = v;
  } );
  obj.setParamOption("radiuses","internal",true);  
  
  obj.addArray("colors",[],1,function(v) {
    obj.colors = v;
  } );
  obj.setParamOption("colors","internal",true);    
  
  obj.addCheckbox("visible",true,(v) => {
    obj.visible=v;
  });

  obj.addString("count","0");

}
