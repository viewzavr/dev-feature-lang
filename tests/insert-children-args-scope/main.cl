load files="lib3dv3 csv params io gui render-params df misc";

obj1: object a={ |txt| text @txt; text "mir"; };
obj2: object a={ |txt| button @txt; text "mir"; };

screen ~auto_activate {
  row {
    co: column gap="0.2em" style="border: 1px solid black;";
    co2: column gap="0.2em" style="border: 1px solid black;";
  };  
  insert-children input=@co list={ text "test"; text "test 2" };
  insert-children input=(list @co @co2) list=@obj1->a "privet";

  //insert-children input=@co list=(list @obj1 @obj2 | map_geta "a" | arr_flat | console_log_input "QQ") "privet";
  //console-log (list @obj1 @obj2 | map_geta "a");
};
