load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative";
load "56view";
load "lib/init.cl";
load "loaders-ext/init.cl";

project: the_project 
  default_animation_parameter="project/adata/data->N"
{
  insert_children input=@project manual=true active=(is_default @project) list={

    ld: load-dir active_view=@rp->active_view;
    axes: axes-view size=10;

    v1: the-view-uni title="Загрузка данных" {
          area sources_str="@ld, @axes";
          camera pos=[10,10,10];
    };

  };

};


//////////////////////////////////////////////////////// главное окно программы

screen1: screen auto-activate  {
  rp: render_project @project active_view_index=0;
};