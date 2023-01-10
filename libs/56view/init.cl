load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative";
load "main-lib.cl plugins.cl gui5.cl gui4addons.cl editor-abstractions.cl";

///////////////////////////////////////////// проект

feature "the_project" {
  project: object
  default_animation_parameter=""
  //views=(get-children-arr input=@project | pause_input | arr_filter_by_features features="the-view")
  views=(find-objects-bf features="the-view" root=@project | sort_by_priority)
  //active_view=(@project->views | geta @ssr->index)
  
  //processes=(get-children-arr input=@project | arr_filter_by_features features="visual-process")
  processes=(find-objects-bf features="visual-process" root=@project recursive=false | sort_by_priority)
  top_processes=(find-objects-bf features="top-visual-process" root=@project recursive=false | sort_by_priority)

  cameras=(find-objects-bf features="camera" root=@project | sort_by_priority)

  //{{ @project->processes | x-modify { x-set-params project=@project } }}
  ;

};


//////////////////////////// 
feature "camera" {
  ccc: camera3d title="Камера" sibling_titles=["Камера"] sibling_types=["camera"]
    ~editable-addons 
    {{ x-param-string name="title"}}
    gui={ render-params @ccc; }
  ;
};

///////////////////////////////////////////// экраны и процессы

// тпу таблица типов экранов
feature "the_view_types";
the_view_types_inst: the_view_types;

// project ему выставляется
feature "the_view" 
{
  tv:  object
  title="Новый экран"
  gui={ 
    render-params @tv; 
    //console_log "tv is " @tv "view procs are" (@tv | geta "sources" | map_geta "getPath");

    qq: object tv=@tv; // без этого внутри ссылка на @tv уже не робит..
    text "Включить:";

    read @tv->project | geta "processes" | repeater //target_parent=@qoco 
    {
       i: checkbox text=(@i->input | geta "title") 
             value=(@qq->tv | geta "sources" | arr_contains @i->input)
          {{ x-on "user-changed" {
              toggle_visprocess_view_assoc2 process=@i->input view=@qq->tv;
          } }};
    };

    insert-children input=@.. list=@tv->gui2;
  }
  {{
    x-param-string name="title";
    // дале чтобы сохранялось всегда даж для введенных в коде вьюшек
    x-param-option name="title" option="manual" value=true;
    x-param-option name="sources_str" option="manual" value=true;
  }}
  sources_str=""
  sources=(find-objects-by-pathes input=@tv->sources_str root=@tv->project)


  // эта штука соединяет удаление визпроцесса и удаление его из списка визпроцессов экрана
  {{
    @tv->sources | x-modify {
      x-patch-r @tv code=`(view,src) => {
        return src.on("remove", () => view.callCmd("forget_process",src));
      }`;
    };
  }}
  

  visible_sources = (@tv->sources | filter_geta "visible")
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
      
      let filtered = view.params.sources_str.split(',').filter( (v) => v.length>0 && v.trim() != add)
      let nv = filtered.concat([add]).join(',');
      view.setParam( 'sources_str', nv, true);
    }`);
  }}

  {{ x-param-option name="forget_process" option="visible" value=false }}
  {{ x-add-cmd name="forget_process" code=(i-call-js view=@tv code=`(val) => {
      let view = env.params.view;
      view.params.sources ||= [];
      view.params.sources_str ||= '';
      if (!val) return;

      let curind = view.params.sources.indexOf( val );
      if (curind >= 0) return;

      let project = view.params.project;
      let add = '@' + val.getPathRelative( project );

      let filtered = view.params.sources_str.split(',').filter( (v) => v.length>0 && v.trim() != add).join(",");
      view.setParam( 'sources_str', filtered, true);
    }`);
  }}

  ;
};

feature "visual_process" {
    vp: object
    title="Визуальный процесс"
    visible=true
    scene3d={ return @vp->output? }
    //scene3d={ object output=@vp->output?; } // типа это мостик
    //output=@~->scene3d?
    //project=""

    {{ x-param-string name="title" }}
    ; // это сделано чтобы визпроцесс можно было как элемент сцены использовать
};

feature "top_visual_process" {
};