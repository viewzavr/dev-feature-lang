find-objects-bf features="the_view_types" recursive=false 
|
insert_children { value="the_view_row" title="Слева на право"; };

feature "the_view_row"
{
  tv: the-view 
    show_view={ show_visual_tab_row input=@tv; }
    scene3d=(@tv->sources | map_geta "scene3d" | arr_compact)
    scene2d=(@tv->sources | map_geta "scene2d")
    camera=@cam 
    {
      cam: camera3d pos=[-400,350,350] center=[0,0,0];
    };
};

feature "show_visual_tab_row" {
   svr: dom_group
      screenshot_dom = @rrviews->dom
   {

    show_sources_params input=(@svr->input | geta "sources");

    rrviews: row style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2;
        justify-content: center;"
    {
      repa: repeater input=(@svr->input | geta "scene3d") {
        src: dom style="flex: 1 1 0;" {
          show_3d_scene
            scene3d=@src->input
            camera=(@svr->input | geta "camera") 
            style="width:100%; height:100%;";
        };
      };

      extra_screen_things: 
        column style="padding-left:2em; min-width: 80%; position:absolute; bottom: 1em; left: 1em;" {
           dom_group input=(@svr->input | geta "scene2d");
        };
    };

   }; // domgroup

}; // show vis tab