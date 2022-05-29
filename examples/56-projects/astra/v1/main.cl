load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative";
load "view56";
load "astra-view.cl";

project: the_project active_view_index=1 
{

  insert_default_children input=@project list={
    av1: astra-vis-1;
    //axes-view;

    v1: the-view-mix3d title="Общий вид" 
        sources_str="@av1";

  };

};


//////////////////////////////////////////////////////// главное окно программы

screen1: screen auto-activate  {
  render_project @project active_view_index=0;
};

debugger-screen-r;