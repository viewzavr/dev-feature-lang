// Описание языка программирования Compalang:
// https://github.com/viewzavr/vrungel/tree/main/develop/compalang

load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative";
load "56view";
//load "lib/init.cl";

load "uni-lib.cl";
load "loaders-ext/init.cl";

project: the_project 
  default_animation_parameter="project/adata/data->N"
{
  //insert_children input=@project manual=true active=(is_default @project | console-log-input "is-def") list={

    ld: dataset;
    av: addvis active_view=@rp->active_view project=@project;
    axes: axes-view size=10;

    v1: the_view_recursive title="Визуализация"
    /*
      actions = { 
        //show_sources_params input=(list @ld @av) show_visible_cb=false;
        //text tag="h3" "Визуализация" style="color: white;";
        //button "Добавить данные"; button "Добавить визуализацию"; text tag="h3" "Визуализация";
      }
    */  
      {
          // area sources_str="@ld,@av,@axes";
          // area sources_str="@axes";
          camera pos=[10,10,10];
          area_container_horiz {
            area_3d sources_str="@ld,@av,@axes"
          }
      };

  //};

};

//////////////////////////////////////////////////////// главное окно программы

screen1: screen ~auto-activate  {
  rp: render_project @project active_view_index=0;
  //text "privet"
};

////////////////////////////

find-objects-bf features="manage_universal_vp_co" recursive=false 
|
insert_children { 

/*
    template name="Загрузка каталога" {
       load_dir bbbbb {{ m_on "created" { add_to_current_view ..... }}}
    };
*/    

    bt: button_add_object "Загрузка каталога" 
         add_to=@..->project 
         add_type="load-dir-uni"
         curview=@..->curview
         {{
           created_add_to_current_view curview=@bt->curview;
         }};
};

feature "load-dir-uni" {
  load-dir active_view=@rp->active_view project=@project initial_mode=0;
};

