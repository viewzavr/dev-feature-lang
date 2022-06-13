load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative";
load "56view";
load "vp.cl";

project: the_project 
  active_view_index=0
  default_animation_parameter="project/adata/astradata->N"
{
  insert_children input=@project manual=true active=(is_default @project) list={
    adata: source;
    av1: vis-1;
    ab: axes_view size=1;

    v1: the-view-uni title="Общий вид" {
          area sources_str="@adata, @av1, @ab";
          camera pos=[0,1.7724860904458464,1.8847246126475379] center=[0,0,0];
        };
  };

};


//////////////////////////////////////////////////////// главное окно программы

screen1: screen auto-activate  {
  render_project @project active_view_index=0;
};

//debugger-screen-r;