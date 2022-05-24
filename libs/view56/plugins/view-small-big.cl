find-objects-bf features="the_view_types" recursive=false 
|
insert_children { value="the_view_small_big" title="Окно в окне"; };

feature "the_view_small_big"
{
  tv: the-view 
    show_view={ show_visual_tab_small_big input=@tv; }
    scene3d=(@tv->sources | map_geta "scene3d" | arr_compact)
    scene2d=(@tv->sources | map_geta "scene2d")
    camera=@cam 
    camera2=@cam2 
    {
      cam: camera3d pos=[-400,350,350] center=[0,0,0];
      cam2: camera3d pos=[-400,350,350] center=[0,0,0];
    };
};

// todo: по клику на окно увеличить размер / и обратно
// понять как визпроцессу повлиять на камеру (типа вид на объект ближе к)
feature "show_visual_tab_small_big" {
   svsm: dom_group
   {

    show_sources_params input=(@svsm->input| geta "sources");

    show_3d_scene 
       scene3d=(@svsm->input | geta "scene3d" 0) 
       camera=(@svsm->input | geta "camera") 
       style_k="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-3";

    rrviews: row style="position: absolute; bottom: 30px; right: 30px; height: 30%; z-index:-2;
        justify-content: flex-end; gap: 1em;" 
    {
      repa: repeater input=(@svsm->input | geta "scene3d" "slice" 1) {
        src: dom style="flex: 0 0 350px;" {
          show_3d_scene 
            scene3d=@src->input 
            camera=(@svsm->input | geta "camera2") 
            ;
        };
      };
    };

   extra_screen_things: 
      column style="padding-left:2em; min-width: 80%; position:absolute; bottom: 1em; left: 1em;" {
         dom_group input=(@svsm->input | geta "scene2d");
      };

   }; // domgroup

}; // show vis tab