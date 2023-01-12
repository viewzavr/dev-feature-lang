load "cats.cl"

///////////////////////////////////////////// проект

feature "the_project" {
  project: object
  default_animation_parameter=""
  //views=(get-children-arr input=@project | pause_input | arr_filter_by_features features="the-view")
  views=(find-objects-bf features="the-view" root=@project | sort_by_priority)
  //active_view=(@project->views | geta @ssr->index)
  
  //processes=(get-children-arr input=@project | arr_filter_by_features features="visual-process")
  layers=(find-objects-bf features="layer" root=@project recursive=false | sort_by_priority)
  //top_processes=(find-objects-bf features="top-visual-process" root=@project recursive=false | sort_by_priority)

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
  
  {{
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

  sibling_types=(@the_view_types_inst | get_children_arr | map_geta "value")
  sibling_titles=(@the_view_types_inst | get_children_arr | map_geta "title")

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
}

coview-record title="Слой" type="layer" cat_id="layer"

feature "layer" {
    l: object
    title="Слой"
    visible=true
    //scene3d={ return @l->output? }    
    gui={paint-gui @l}
    {
      gui {
        gui-tab "main" {
          gui-slot @l "title" gui={ |in out| gui-string @in @out}
        }
        gui-tab "content" {
            connect (event @b "click") (method @d "show")
            b: button "Слои" //on_click={ method @d "show" | put-value 1 }
            d: manage-lists-dialog (list 
                (list "Подслои" (find-objects-bf "layer" root=@l) @l (gather-cats ["layer"]))

                
                (list "Данные" (find-objects-bf "data-artefact" root=@project) @project (gather-cats ["data-io"]))
                (list "Расчёты" (find-objects-bf "computation" root=@project) @project (gather-cats ["compute"]))
                (list "Образы" (find-objects-bf "node3d" root=@project) @project (gather-cats ["basic"]))
            )

            //av=@project.active_view
            reaction (event @d "created") {: obj av=@rp.active_view?|
              ///console.log('created!!!!!',obj,av)
              // странно это все.. но типа фича не сразу применяется.. как так..
              setTimeout( () => {
                if (obj.is_feature_applied("layer")) {
                  av.append_source( obj )
                }
              }, 50)  
            :}          
        }
      }
    }
}

feature "process" {
  object title="Процесс"
}

