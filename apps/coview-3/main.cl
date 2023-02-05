// Описание языка программирования Compalang:
// https://github.com/viewzavr/vrungel/tree/main/develop/compalang

load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative"
load "init.cl"

//////

show-file-progress export-image animation
settings-cmd
coview-app-design

project: the_project 
{

  l1: layer title="Слой №1" {
    cv-select-files title="Файлы проекта"
    
    //test-process count=77
    cam: camera pos=[10,10,10];
    axes_view

    //ic: cv_intersect_center
    //link from="@ic->successful_coords" to="@cam->center" soft_mode=true
  }

  l2: layer title="Физкульт-привет 2" {
    //test-process count=77
    text_sprite_one text='TEST' size=50 radius=10 ~layer_object position=[10,10,10] title="Спрайт"
    cv-spheres positions=[10,10,10] radius=0.1

    cam2: camera pos=[10,10,10];
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