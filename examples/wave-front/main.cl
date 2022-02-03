load files="lib3dv3 csv params io gui render-params df misc scene-explorer-3d";

flist : load-file file="http://viewlang.ru/assets/other/2022-02-pavel-lebedev-front/files.txt" 
        | text_to_arr 
        | arr_map code="(val,index) => 'http://viewlang.ru/assets/other/2022-02-pavel-lebedev-front/' + val";
 
render3d target=@view1 bgcolor=[0,0,0] {
  axes_box; 
  orbit_control; camera3d pos=[0,40,40] center=[0,0,0];

/*
  auto_grid {
    @flist | repeater {
      load_file file=@.->input | parse_csv | mesh color=[0,0,1]; //material=@me1->output;
    };
  };
*/
  load_file file=(@flist | get name=@sl->value) | parse_csv | mesh color=[0,0,1]; //material=@me1->output;
};
 
screen auto_activate {
  //render-params
  sl: slider min=0 max=(compute_output arr=@flist code=`return env.params.arr.length-1`);
  //me1: material_generator_gui text="Surface look";
  // кстати вопрос - хотелось бы иметь материал общий на все поверхности
  // что этому мешает?
  view1: view3d fill_parent below_others;
};

debugger_screen_r;

register_feature name="auto_grid" {
  node3d;
}

