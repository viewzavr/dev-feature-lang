load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative";
load "56view";
load "astra-view.cl";

project: the_project active_view_index=1 default_animation_parameter="project/av1/astradata->N"
{

  insert_default_children input=@project list={
    av1: astra-vis-1;
    //axes-view;

    v1: the-view-mix3d title="Общий вид" 
        sources_str="@av1"
        camera_modifiers={ x-set-params pos=[0,-4,1] center=[0,0,0] }
        ;

  };

};


//////////////////////////////////////////////////////// главное окно программы

screen1: screen auto-activate  {
  render_project @project active_view_index=0;
};

debugger-screen-r;