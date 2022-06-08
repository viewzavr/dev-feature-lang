load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative";
load "56view";
load "astra-view.cl";
//load "rotate-camera-z-plugin.cl";

project: the_project 
  active_view_index=1 
  default_animation_parameter="project/av1/astradata->N"
{
  insert_children input=@project manual=true active=(is_default @project) list={
    adata: astra-source;
    av1: astra-vis-1;
    camfly1: camera-fly-vp;
    //axes-view;
    camrotate: astra-camera-rotate;

    v1: the-view-uni title="Общий вид" {
          area sources_str="@adata, @av1,@camrotate, @camfly1";
          camera pos=[0,1.7724860904458464,1.8847246126475379] center=[0,0,0];
        };
  };

};


//////////////////////////////////////////////////////// главное окно программы

screen1: screen auto-activate  {
  render_project @project active_view_index=0;
};

//debugger-screen-r;