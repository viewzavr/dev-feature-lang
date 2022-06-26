load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

screen auto_activate {
  r1: dom {
    text "privet";
    k: slider min=0 max=100 value=10;
  };
};

@r1 | bz: insert_children 
  list=(compalang2 //{{ console_log_life }}
        "dom style='border: 1px solid black; ' dom_style_background=@color;"
         color="brown"
       );

@bz->output | insert_children
  list=(compalang2 //{{ console_log_life }}
        (m_eval `(i) => {
          let str="";
          for (let a=0; a<i; a++)
            str += "dom style='border: 1px solid black; width:50px; height:50px; margin:1em; display: inline-block;' dom_style_background=@color;"
          return str;
          }
          ` @k->value)
         color="purple"
       );