find-objects-bf features="the_view_types" recursive=false 
|
insert_children { value="the_view_mix3d" title="Одна сцена"; };

feature "the_view_mix3d" {
  tv: the-view
        camera=@cam
        show_view={ show_visual_tab_mix3d input=@tv; }
        scene3d=(@tv->sources | map_geta "scene3d")
        scene2d=(@tv->sources | map_geta "scene2d")
        {
          cam: camera3d pos=[-400,350,350] center=[0,0,0];
          insert_features input=@cam list=@tv->camera_modifiers;

          ////@cam | x-modify { insert list=@tv->camera_modifiers;
          // вот бы метод getCameraFor(i).. т.е. такое вычисление по запросу..
        };
};

feature "show_visual_tab_mix3d" {
   svt: dom_group 
     screenshot_dom = @s3d->dom
   {
    show_sources_params input=(@svt->input | geta "sources");

    dom style_k="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2"
    { // комбинатор-оверлей

      s3d: show_3d_scene 
         scene3d=(@svt->input | geta "scene3d") 
         camera=(@svt->input | geta "camera") 
      ;

      extra_screen_things: 
        column style="padding-left:2em; min-width: 80%; position:absolute; bottom: 1em; left: 1em;" {
           dom_group input=(@svt->input | geta "scene2d");
        };
    };

   }; // domgroup
}; // show vis tab