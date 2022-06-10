load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative";
load "56view";
load "lava-vp.cl obj-vp.cl";

project: the_project 
  active_view_index=0 
  default_animation_parameter="project/adata/data->N"
{
  insert_children input=@project manual=true active=(is_default @project) list={
    adata: vtk-source;
    av1: vtk-vis-1;
    //axes-view;

    objdata: obj-source;
    objvis: obj-vis;

    axes: axes-view size=10;

    v1: the-view-uni title="Общий вид" {
          area sources_str="@adata, @av1, @objdata, @objvis, @axes";
          camera pos=[-1.213899509537966, -6.483218783513895, 6.731292315078603] center=[-1.3427112420191143,2.246045687869776,2.985181087924206];
    };
  };

};


//////////////////////////////////////////////////////// главное окно программы

screen1: screen auto-activate  {
  render_project @project active_view_index=0;
};