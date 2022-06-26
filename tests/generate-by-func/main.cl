load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

screen auto_activate {
  r1: row {
    text "privet";
  };
};

@r1 | insert_children list={ text "mir" };

@r1 | insert_children list=(m_eval "(color) => {
  return env.vz.compalang(`dom style='border: 1px solid black; width:100px; height:50px;' dom_style_background=@color`, {color:color});
}" "yellow");