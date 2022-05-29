load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative";
load "56view";
load "landing-view.cl";

project: the_project active_view_index=1 
{

  insert_default_children input=@project list={
    lf: landing-file;
    lv: landing-view;
    //a1: axes-view size=100;
    //a2: axes-view title="Оси координат 2";

    v0: the-view-mix3d title="Данные" 
        sources_str="@lf";

    v1: the-view-mix3d title="Общий вид" 
        sources_str="@lv/lv1";

    v2: the-view-mix3d title="Вид на ракету" 
        sources_str="@lv/lv2";
  };

};


//////////////////////////////////////////////////////// главное окно программы

screen1: screen auto-activate  {
  render_project @project active_view_index=1;
};

debugger-screen-r;