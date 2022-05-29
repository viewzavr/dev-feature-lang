load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative";
load "main-lib.cl plugins.cl gui5.cl";

///////////////////////////////////////////// проект

feature "the_project" {
  project:
  //views=(get-children-arr input=@project | pause_input | arr_filter_by_features features="the-view")
  views=(find-objects-bf features="the-view" root=@project | sort_by_priority)
  //active_view=(@project->views | geta @ssr->index)
  
  //processes=(get-children-arr input=@project | arr_filter_by_features features="visual-process")
  processes=(find-objects-bf features="visual-process" root=@project recursive=false | sort_by_priority)
  top_processes=(find-objects-bf features="top-visual-process" root=@project recursive=false | sort_by_priority)
  ;
};

///////////////////////////////////////////// экраны и процессы

// тпу таблица типов экранов
feature "the_view_types";
the_view_types_inst: the_view_types;

// project ему выставляется
feature "the_view" 
{
  tv: 
  title="Новый экран"
  gui={ 
    render-params @tv; 
    //console_log "tv is " @tv "view procs are" (@tv | geta "sources" | map_geta "getPath");

    qq: tv=@tv; // без этого внутри ссылка на @tv уже не робит..
    text "Включить:";

    @tv->project | geta "processes" | repeater //target_parent=@qoco 
    {
       i: checkbox text=(@i->input | geta "title") 
             value=(@qq->tv | geta "sources" | arr_contains @i->input)
          {{ x-on "user-changed" {
              toggle_visprocess_view_assoc2 process=@i->input view=@qq->tv;
          } }};
    };

  }
  {{
    x-param-string name="title";
    // дале чтобы сохранялось всегда даж для введенных в коде вьюшек
    x-param-option name="title" option="manual" value=true;
    x-param-option name="sources_str" option="manual" value=true;
  }}
  
  sources=(find-objects-by-pathes input=@tv->sources_str root=@tv->project)
  project=@..

  //sibling_types=["the-view-mix3d","the-view-row", "the-view-small-big"] 
  //sibling_titles=["Одна сцена","Слева на право", "Окно в окне"]
  sibling_types=(@the_view_types_inst | get_children_arr | map_geta "value")
  sibling_titles=(@the_view_types_inst | get_children_arr | map_geta "title")
  

  // todo добавить методы "подключить процесс"
  // мысли - похоже процесс это просто процесс а в какой экран идет это уже параметр ассоциации...
  // которую не вполне ясно как пока идентифицировать..

  {{ x-param-option name="append_process" option="visible" value=false }}
  {{ x-add-cmd name="append_process" code=(i-call-js view=@tv code=`(val) => {
      let view = env.params.view;
      view.params.sources ||= [];
      view.params.sources_str ||= '';
      if (!val) return;
      
      let curind = view.params.sources.indexOf( val );
      if (curind >= 0) return;

      let project = view.params.project;
      let add = '@' + val.getPathRelative( project );
      
      let filtered = view.params.sources_str.split(',').filter( (v) => v.length>0)
      let nv = filtered.concat([add]).join(',');
      view.setParam( 'sources_str', nv, true);
    }`);
  }}

  ;
};

feature "visual_process" {
    title="Визуальный процесс"
    visible=true
    output=@~->scene3d

    {{ x-param-string name="title" }}
    ; // это сделано чтобы визпроцесс можно было как элемент сцены использовать
};

feature "top_visual_process" {
};

//////////////////////////////////////////////////////// рендеринг проекта

// отображение. тут и параметр как компоновать
// параметр - список визуальных процессов видимо.
// ну а может контейнер ихний. посмотрим
// input 

// так это уже конкретная показывалка - с конкретным методом комбинирования.
// мы потом это заоверрайдим чтобы было несколько методов комбинирования и был выбор у человека
// хотя это можно и как параметр этой хрени и как суб-компоненту сделать.

// обновление. input это объект вида. the-view.
// у вью ожидаются - параметр sources - массив где каждый элемент
// имеет записи gui, scene2d, scene3d

feature "show_visual_tab" {
  sv: dom_group 
        screenshot_dom=(@ic->output | geta 0 | geta "screenshot_dom") 
  {
    ic: insert_children input=@sv list=(@sv->input | get_param "show_view");
  };
};

/*
.. короче я тут начал подтягивать из вьюшек тип отображения
.. а при этом считаю что будет меняться этот тип отображения во вьюшках
.. например за счет смены типа вьюшек через методу render_layers_inner
.. которую я покажу рядом с кнопкой таблицы настройки видов
*/

//global_modifiers: render_project_right_col={};
// render_project_right_col_modifier: x-modify {};

feature "render_project_right_col";

feature "render_project" {
   rend: column padding="1em" project=@.->0 
            active_view_index=0 
            active_view=(@rend->project|geta "views"|geta @ssr->index) 

            {{ x-add-cmd name="goto_next_view" code=(i-call-js ssr=@ssr code=`(val) => {
              let ssr = env.params.ssr;
              let len = ssr.params?.items?.length || 0;
              if (len > 0)
                 ssr.setParam( "index", (ssr.params.index+1) % len );
            }`);
            }}

            {

       ssr: switch_selector_row 
               index=@rend->active_view_index
               items=(@rend->project | get_param "views" | sort_by_priority | map_param "title")
               style_qq="margin-bottom:15px;" {{ hilite_selected }}
                ;

       right_col: 
       
       column render_project_right_col 
         style="padding-left:2em; min-width: 80px; position:absolute; right: 1em; top: 1em; gap: 0.2em;" 
         project=@rend->project
         //render_project=@rend
         active_view=@rend->active_view
         active_view_tab=@of->output
         //render_project=@rend
         //{{ x-modify list=@render_project_right_col_modifier }}
        {
        }; // column справа

       of: one_of 
              index=@ssr->index
              list={ 
                show_visual_tab input=(@rend->project | get_param "views" | get 0); // так то.. так то.. показывай просто текущий, согласно project[index].. но параметры сохраняй...
                show_visual_tab input=(@rend->project | get_param "views" | get 1);
                show_visual_tab input=(@rend->project | get_param "views" | get 2);
                show_visual_tab input=(@rend->project | get_param "views" | get 3);
                show_visual_tab input=(@rend->project | get_param "views" | get 4);
                show_visual_tab input=(@rend->project | get_param "views" | get 5); // так то.. так то.. показывай просто текущий, согласно project[index].. но параметры сохраняй...
                show_visual_tab input=(@rend->project | get_param "views" | get 6);
                show_visual_tab input=(@rend->project | get_param "views" | get 7);
                show_visual_tab input=(@rend->project | get_param "views" | get 8);
                show_visual_tab input=(@rend->project | get_param "views" | get 9);                
              }
              {{ one-of-keep-state; one_of_all_dump; }}
              ;


   };  
}
