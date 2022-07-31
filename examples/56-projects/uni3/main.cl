load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative";
load "56view";
load "lib/init.cl";
load "loaders-ext/init.cl";

project: the_project 
  default_animation_parameter="project/adata/data->N"
{
  insert_children input=@project manual=true active=(is_default @project) list={

    ld: load-dir active_view=@rp->active_view initial_mode=0;
    axes: axes-view size=10;

    v1: the-view-uni title="Набор данных" 
      actions={
        //button "Добавить каталог";
         button_add_object "Добавить файлы" 
           add_to=@project
           add_type="load-dir"
           {{
             created_add_to_current_view curview=@rp->active_view;
           }};
      }
    {
          area sources_str="@ld, @axes";
          camera pos=[10,10,10];
    };

    v2: the-view-uni title="Визуализация" 
      actions={
        button "Добавить образ";
        /*
         button_add_object "Добавить каталог" 
           add_to=@project
           add_type="load-dir"
           {{
             created_add_to_current_view curview=@rp->active_view;
           }};
        */   
      }
      {
          area sources_str="@axes";
          camera pos=[10,10,10];
      };

  };

};

//////////////////////////////////////////////////////// главное окно программы

screen1: screen auto-activate  {
  rp: render_project @project active_view_index=0;
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