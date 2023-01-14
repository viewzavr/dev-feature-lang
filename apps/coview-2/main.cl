// Описание языка программирования Compalang:
// https://github.com/viewzavr/vrungel/tree/main/develop/compalang

load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative"
load "init.cl"

////// фичи

load "features/init.cl"

//////

show-file-progress export-image animation

project: the_project 
{

  l1: layer title="Слой №1" {
    //test-process count=77
    camera pos=[10,10,10];
    axes_view
  }

  l2: layer title="Физкульт-привет 2" {
    //test-process count=77
    camera pos=[10,10,10];
  }

    v1: the_view_recursive title="Визуализация"
    actions={}
    {
        area_container_horiz {
          area_3d sources_str="@l1"
        }
    }

}

//////////////////////////////////////////////////////// главное окно программы

screen1: screen ~auto-activate  {
  rp: render_project @project active_view_index=0;
}