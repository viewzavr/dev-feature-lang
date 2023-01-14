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

///////////////////////////////////////////// экраны и процессы

// тпу таблица типов экранов
feature "the_view_types";
the_view_types_inst: the_view_types;

// project ему выставляется
feature "the_view" 
{
  tv:  layer_object
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

coview-record title="Слой" type="layer" cat_id="layer"

feature "layer" {
    l: layer_object
    title="Слой"
    visible=true
    //scene3d={ return @l->output? }    
    gui={paint-gui @l }
    sidebar_gui={paint-gui @l ~plashka true}
    //subitems=(find-objects-bf "layer_object" root=@l include_root=false recursive=false)
    {
      gui { |is_sidebar|
        /*
        gui-tab "main" {
          gui-slot @l "title" gui={ |in out| gui-string @in @out}
        }*/
        gui-tab "Состав" {
          let list_of_layer_items=(walk_objects @l "subitems" | m-eval {: arr | return arr.slice(1) :} )
          //let list_of_layer_items=(walk_objects @l "subitems" | m-eval "slice" 1 )

          column gap="0.2em" {
            cb: combobox 
                     values=(@list_of_layer_items | map-geta "id")
                     titles=(@list_of_layer_items | map-geta "title")
                     index=0 
                     dom_size=(m-eval {: arr=@list_of_layer_items | return Math.min( 10, 1+arr.length ) :})

            row {
              bplus:  button "+ добавить"
              bminus: button "-"
              bup:    button "↑"
              bdown:  button "↓"

              add: add-object-dialog target=@l list=(gather-cats ["data","process","gr3d","gr2d"])

              connect (event @bplus "click") (method @add "show")

              reaction (event @bminus "click") {: cobj=@selected_object | if (cobj) cobj.remove(); else console.log('cobj is null',cobj) :}
            }

            let selected_object = (@list_of_layer_items | geta @cb->index default=null | geta "obj")

            column {
              paint-gui @selected_object
            }
          }

        }
/*
        gui-tab "Состав2" enabled=false {
            // console-log "privet omlet" @l

            connect (event @b "click") (method @d "show")
            b: button "Объекты слоя" //on_click={ method @d "show" | put-value 1 }
            d: manage-lists-dialog (list 
                (list "Объекты" (find-objects-bf "layer_object" root=@l include_root=false) @l (gather-cats ["layer","compute","data-io","basic"] ))

                (list "Подслои" (find-objects-bf "layer" root=@l include_root=false) @l (gather-cats ["layer"]))
                
                //(list "Расчёты" (find-objects-bf "computation" root=@project) @project (gather-cats ["compute"]))
                //(list "Данные" (find-objects-bf "data-artefact" root=@project) @project (gather-cats ["data-io"]))
                //(list "Расчёты" (find-objects-bf "computation" root=@project) @project (gather-cats ["compute"]))
                //(list "Образы" (find-objects-bf "node3d" root=@project) @project (gather-cats ["basic"]))
                
            )

            //av=@project.active_view
            reaction (event @d "created") {: obj av=@rp.active_view?|
              ///console.log('created!!!!!',obj,av)
              // странно это все.. но типа фича не сразу применяется.. как так..
            :}          
        }
*/        
      }
    }
}

feature "layer_object" {
  x: object subitems=(find-objects-bf "layer_object" root=@x include_root=false depth=1)
}

////////////////////////// вот это следующее непонятнО, нужно ли вообще..

feature "process" {
 p: layer_object 
    title="Процесс"
    gui={paint-gui @p}
    {
      gui { }
    }
}

// ну особенно вот это - оно зачем? layer_object да и все.. ну process на худой конец.. но с другой стороны оно может быть node3d...
feature "visual_process" {
    vp: layer_object
    title="Визуальный процесс"
    visible=true
    gui={paint-gui @vp}
    //scene3d={ return @vp->output? }
    //scene3d={ object output=@vp->output?; } // типа это мостик
    //output=@~->scene3d?
    //project=""

    {{ x-param-string name="title" }}
    {
      gui {}
    }
    // это сделано чтобы визпроцесс можно было как элемент сцены использовать
}

feature "camera" {
  ccc: camera3d title="Камера" 
    sibling_titles=["Камера"] sibling_types=["camera"]
    ~layer_object
    ~editable-addons 
    {{ x-param-string name="title"}}
    gui={ paint-gui @ccc; }
  {
    gui {
      gui-tab "main" {
        gui-slot @ccc "pos"    gui={ |in out| gui-vector @in @out }
        gui-slot @ccc "center" gui={ |in out| gui-vector @in @out }
        gui-slot @ccc "theta"  gui={ |in out| gui-slider @in @out min=-180 max=180 step=0.1 }
      }
    }
  }
};