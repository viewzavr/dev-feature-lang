// Описание языка программирования Compalang:
// https://github.com/viewzavr/vrungel/tree/main/develop/compalang

load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative"
load "init.cl"

//////

show-file-progress export-image animation
settings-cmd
coview-app-design

project: the_project artefacts_library=@proj_files
{

  l1: layer title="Слой №1" {
    proj_files: cv-select-files title="Файлы проекта"
    
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
  rp: render_project @project active_view_index=0
        top_row_items={
          bt: button "+ Добавить файлы" class="important_button"
          bt2: button "+ Добавить визуализацию" class="important_button"

          reaction @bt.click (event @proj_files "add_new")
          reaction @bt2.click (method @add "show")

          add: add-object-dialog target=@l1 list=(gather-cats ["process","gr3d"])

          reaction @add.created {: obj s=@setup_params |
              s.setParam("obj",obj)
              s.show()
            :}

          setup_params: dialog obj=null {
            column {
              text "Настройка параметров"
              paint-gui @setup_params.obj
            }  
            // %pain %idea paint-gui @obj типа параметры объявленные выше идут в скопу!
          }
        }
}