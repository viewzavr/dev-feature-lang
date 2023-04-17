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

          jsfunc "mktitle2" {: obj selected | return `${obj == selected ? "🡆" : ""} ${obj.params.title}` :}

feature "layer" {
    l: layer_object ~node3d // F-LAYER-IS-NODE3D
    title="Слой"
    visible=true
    //scene3d={ return @l->output? }    
    gui={paint-gui @l }
    sidebar_gui={paint-gui @l filter=["content"]}
    add_dialog_categories=(primary-cats) // (gather-cats ["data","process","gr3d","gr2d"])
    //subitems=(find-objects-bf "layer_object" root=@l include_root=false recursive=false)
    {
      addon-click-intersect // по умолчанию всем решил пока
      gui {

        gui-tab "content" "Состав" {

          ////////////////////////////// управление объектами

          row gap="0.1em" style="margin-left: 10px; margin-top:2px;" {
            bplus:  button "+ добавить" class="important_button"
            //button "Общее"
            //button "Модификаторы"
            
            bminus: button "-"
            bup:    button "↑"
            bdown:  button "↓"
            

            add: add-object-dialog target=@l list=@l.add_dialog_categories

            connect (event @bplus "click") (method @add "show")

            reaction (event @bminus "click") {: cobj=@dasd.selected | if (cobj) cobj.remove(); else console.log('cobj is null',cobj) :}
          }

          ////////////////////////////// выбор объекта

          let list_of_layer_items=@l.subitems
          //let list_of_layer_items=(walk_objects @l "subitems" | m-eval {: arr | return arr.slice(1) :} )
          //let list_of_layer_items=(walk_objects @l "subitems" | m-eval "slice" 1 )

          column style="margin-left: 10px; gap:1px;" {
            read @l.subitems | repeater { |item|
              /*
              collapsible text=@item.title {
                paint-gui @item
              }*/
              row {
                btn: button (mktitle2 @item @dasd.selected) style="min-width:220px"
                checkbox
                reaction @btn.click {: evt item=@item dasds=(param @dasd "selected")|
                   dasds.set( item )
                :}
              }
            }
          }



          dasd: object selected = @l.subitems.0

          ////////////////////////////// гуи объекта
/*
          column ~plashka {
            text @dasd.selected.title
            paint-gui @dasd.selected
          }*/
          column ~plashka {

            ////////////////////////////// управление под-объектами
            
            //let list_of_object_items=(walk_objects @dasd.selected "subitems" | m-eval {: arr | return arr.slice(1) :})
            let list_of_object_items=(walk_objects @dasd.selected "subitems" )
            let current_top_item=(read @list_of_object_items | geta 0)

            column gap="0.2em" style="margin-top: 5px;" {
              cb: combobox visible=(m-eval {: list=@list_of_object_items | return list.length > 1:})
                       values=(@list_of_object_items | map-geta "id")
                       titles=(@list_of_object_items | map-geta "title")
                       index=0 
                       dom_size=(m-eval {: arr=@list_of_object_items | return Math.min( 10, 1+arr.length ) :})

              let selected_object = (@list_of_object_items | geta @cb->index default=null | geta "obj")

              column {
                paint-gui (or @selected_object @dasd.selected)
              }
              
            }

          }
        }  

        /*
        gui-tab "main" {
          gui-slot @l "title" gui={ |in out| gui-string @in @out}
        }*/
/*
        read @l.subitems | repeater  { |item index| 
          gui-tab @index (mktitle @item) {
            paint-gui @item
          }
        }
        jsfunc "mktitle" {: obj | return obj.params.title[0] :}
*/        
/*
        gui-tab "content" "Состав" {

          read @l.subitems | repeater { |item|
            btn: button (mktitle @item)
          }

          jsfunc "mktitle" {: obj | return obj.params.title[0] :}

          let active_top_subitem = @l
          let list_of_layer_items=(if (@active_top_subitem == @l) then={ object output=[] } else={ walk_objects @active_top_subitem "subitems" })
          //let list_of_layer_items=(walk_objects @l "subitems" | m-eval "slice" 1 )

          column gap="0.2em" style="margin-top: 5px;" {
            cb: combobox 
                     values=(@list_of_layer_items | map-geta "id")
                     titles=(@list_of_layer_items | map-geta "title")
                     index=0 
                     dom_size=(m-eval {: arr=@list_of_layer_items | return Math.min( 10, 1+arr.length ) :})

            row gap="0.1em" {
              bplus:  button "+ добавить" class="important_button"
              bminus: button "-"
              bup:    button "↑"
              bdown:  button "↓"

              add: add-object-dialog target=@l list=@l.add_dialog_categories

              connect (event @bplus "click") (method @add "show")

              reaction (event @bminus "click") {: cobj=@selected_object | if (cobj) cobj.remove(); else console.log('cobj is null',cobj) :}
            }

            let selected_object = (@list_of_layer_items | geta @cb->index default=null | geta "obj")

            column {
              paint-gui @selected_object
            }
          }

        }

        gui-tab "content-" "Состав-" {
          let list_of_layer_items=(walk_objects @l "subitems" | m-eval {: arr | return arr.slice(1) :} )
          //let list_of_layer_items=(walk_objects @l "subitems" | m-eval "slice" 1 )

          column gap="0.2em" style="margin-top: 5px;" {
            cb: combobox 
                     values=(@list_of_layer_items | map-geta "id")
                     titles=(@list_of_layer_items | map-geta "title")
                     index=0 
                     dom_size=(m-eval {: arr=@list_of_layer_items | return Math.min( 10, 1+arr.length ) :})

            row gap="0.1em" {
              bplus:  button "+ добавить" class="important_button"
              bminus: button "-"
              bup:    button "↑"
              bdown:  button "↓"

              add: add-object-dialog target=@l list=@l.add_dialog_categories

              connect (event @bplus "click") (method @add "show")

              reaction (event @bminus "click") {: cobj=@selected_object | if (cobj) cobj.remove(); else console.log('cobj is null',cobj) :}
            }

            let selected_object = (@list_of_layer_items | geta @cb->index default=null | geta "obj")

            column {
              paint-gui @selected_object
            }
          }
       }   
*/          

        
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

      }
*/   
      }           
    }
}

feature "layer_object" {
  x: object 
       subitems=(find-objects-bf "layer_object" root=@x include_root=false depth=1)
     ~apply_old_modifiers
 /*  
  {{
     // подключаем модификаторы
     x-modify-list input=@x list=(find-objects-bf root=@x include_root=false "addon-object" depth=1 | filter_geta "visible")
     // типа встроенный apply_old_modifiers
  }}
 */
       
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

// ну особенно вот это - оно зачем? layer_object да и все.. 
// ну process на худой конец.. но с другой стороны оно может быть node3d...
// ну да, сделано что это node3d.. 
feature "visual_process" {
    vp: layer_object
    title="Визуальный процесс"
    visible=true
    gui={paint-gui @vp}
    ~node3d
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

feature "have-scene-env"
feature "have-scene2d"


feature "camera" {
  ccc: camera3d title="Камера" 
    sibling_titles=["Камера"] sibling_types=["camera"]
    ~layer_object
    {{ x-param-string name="title"}}
    gui={ paint-gui @ccc; }
  {
    gui {
      gui-tab "main" {
        gui-slot @ccc "pos"    gui={ |in out| gui-vector @in @out }
        gui-slot @ccc "center" gui={ |in out| gui-vector @in @out }
        gui-slot @ccc "theta"  gui={ |in out| gui-slider @in @out min=-180 max=180 step=0.1 }
        gui-slot @ccc "ortho"  gui={ |in out| gui-checkbox @in @out }
        gui-slot @ccc "ortho_zoom"  gui={ |in out| gui-slider @in @out min=1 max=100 step=0.01 }
        gui-box "commands" {
          column {
            
            row gap = "0.1em" {
              gui-cmd "reset" (cmd @ccc "reset")
              // apply width="50px"
              // ну либо возможность вводить фичу локально.. а наверное можно?
              gui-cmd "X" style="width:40px" (cmd @ccc "look_x")
              gui-cmd "Y" style="width:40px" (cmd @ccc "look_y")
              gui-cmd "Z" style="width:40px" (cmd @ccc "look_z")
            }
            // reaction @ccc.reset {: console.log("reset called") :}
          }
        }
      }
    }
    param-info "theta" out=true in=true
    param-info "pos" out=true in=true
    param-info "center" out=true in=true

    //m-eval {: camera=@ccc.output | camera.layers.enable(1) :} // разрешим еще и 1 рисовать
    // это следует делать на уровне private-camera как оказалось
  }
}

feature "plugin" 
{
  tv:  layer_object
  title="Плагин"
}