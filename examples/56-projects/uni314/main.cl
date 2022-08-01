load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative";
load "56view";
load "lib/init.cl";
load "loaders-ext/init.cl";

addons_list: (find-objects-bf features="addon");

feature "addvis" {
  x: visual_process title="Добавить образ"
    gui={
      column plashka gap="0.4em" {
        text "Артефакт данных";
        cb: combobox titles=(@artefacts->output | map_geta "title") values=(@artefacts->output | map_geta "getPath");
        text "Образ";
        ct: combobox titles=(@compatible_visual_processes->output | map_geta "title")
                 values=(@compatible_visual_processes->output | map_geta "type")
        ;
        //button "Добавить";
        ba: button_add_object "Добавить" 
           add_to=@project
           add_type=@ct->value
           {{
             created_add_to_current_view curview=@x->active_view;
           }};
        @ba | get_cell "created" | c-on "(obj,art) => {
          debugger;
          if (Array.isArray(obj)) 
             obj=obj[0]; // todo че за массив
          if (Array.isArray(obj)) 
             obj=obj[0]; // todo че за массив 2   
          //obj.setParam('element',art);
          obj.setParam('input',art.params.output);
          //obj.setParam('input',art.params.output);
        }" @curart;

        curart: (@artefacts->output | geta @cb->index );
        console_log "curart" @curart;

        compatible_visual_processes: m_eval "(list,elem) => {
            if (!elem) return [];
            let res = list.filter( it => it.params.crit( elem ) )
            console.log('filtered',res)
            return res;
          }" @addons_list (@curart | geta "output");
      };
    }
    {{
       artefacts: find-objects-bf features="load-dir" root=@project;
    }};
};


project: the_project 
  default_animation_parameter="project/adata/data->N"
{
  insert_children input=@project manual=true active=(is_default @project) list={

    ld: dataset;
    av: addvis active_view=@rp->active_view;
    axes: axes-view size=10;

    v1: the-view-uni title="Визуализация" 
      {
          area sources_str="@ld,@av,@axes";
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