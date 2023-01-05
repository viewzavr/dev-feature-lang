// Описание языка программирования Compalang:
// https://github.com/viewzavr/vrungel/tree/main/develop/compalang

load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative"
load "56view"

project: the_project 
{

    axes: axes-view size=10
    axes2: axes-view size=5 title="Малые оси"

    v1: the_view_recursive title="Визуализация"
    actions={
      //b: button "Визпроцессы" //on_click={ method @d "show" | put-value 1 }
      //d: manage-objects-list-dialog list=(find-objects-bf "visual-process" root=@project)
           //list=(list @axes)
      //reaction (event @b "click") {: console.log('click') :}
      //connect (event @b "click") (method @d "show")

      connect (event @b "click") (method @d "show")

      b: button "Сущности" //on_click={ method @d "show" | put-value 1 }
      d: manage-lists-dialog (list 
          (list "Данные" (find-objects-bf "data-artefact" root=@project) @project (gather-cats ["data-io"]))
          (list "Расчёты" (find-objects-bf "computation" root=@project) @project [])
          (list "Образы" (find-objects-bf "visual-process" root=@project) @project (gather-cats ["basic"]))
          (list "Экраны" (find-objects-bf "the_view_recursive" root=@project) @project [])
      )

      //av=@project.active_view
      reaction (event @d "created") {: obj av=@rp.active_view?|
        ///console.log('created!!!!!',obj,av)
        // странно это все.. но типа фича не сразу применяется.. как так..
        setTimeout( () => {
          if (obj.is_feature_applied("visual-process")) {
            av.append_process( obj )
          }
        }, 50)  
      :}

      //console-log d={(event @b "click") => (method @d "show")}

      //@b.click => @d.show
    }
    /*
      actions = { 
        //show_sources_params input=(list @ld @av) show_visible_cb=false;
        //text tag="h3" "Визуализация" style="color: white;";
        //button "Добавить данные"; button "Добавить визуализацию"; text tag="h3" "Визуализация";
      }
    */  
      {
          camera pos=[10,10,10];
          area_container_horiz {
            area_3d sources_str="@axes"
          }
      }

}

//////////////////////////////////////////////////////// главное окно программы

screen1: screen ~auto-activate  {
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

/*
    bt: button_add_object "Загрузка каталога" 
         add_to=@..->project 
         add_type="load-dir-uni"
         curview=@..->curview
         {{
           created_add_to_current_view curview=@bt->curview;
         }};
*/         
};

/*
feature "load-dir-uni" {
  load-dir active_view=@rp->active_view project=@project initial_mode=0;
};
*/

//////////////////////////////////////////

/*
  list = массив элементов вида [ надпись, список-объектов, куды-добавлять-новое, категории-нового ] 
  нарисует вверху табы с надписями, для каждой табы - покажет список объектов,
  для текущего объекта - параметры.

  идеи 
  - справа тоже кнопочка плюс
  - нужна визуальная разно-модальность...
*/
feature "manage-lists-dialog" {
  dlg: dialog 
    style_w="min-width: 400px"
    list=@.->0
    below={
      row gap="0.2em" {
            bplus: button "+ добавить"
            bminus: button "-"

            let target_for_new = (@dlg.list | geta @ssr.index | geta 2)
            let cats_for_new = (@dlg.list | geta @ssr.index | geta 3)
            add: add-object-dialog target=@target_for_new list=@cats_for_new

            connect (event @bplus "click") (method @add "show")
            reaction (event @bminus "click") {: cobj=@selected_object | if (cobj) cobj.remove(); else console.log('cobj is null',cobj) :}

            //console-log "add-e=" (event @add "created")

            connect (event @add "created") (event @dlg "created")

            reaction (event @dlg "created") {: obj|
              //console-log "see new obj" @obj
              //console.log("see new obj on dlg",obj)
            :}
          }
    }
    right={ |obj|
      column {
        insert_children input=@.. list=@obj.gui
      }  
    }
  {
    column {
      //insert_children input=@.. list=@dlg.above

      ssr: switch_selector_row 
                 index=0
                 items=(@dlg.list | map_geta 0)
                 {{ hilite_selected }}
    
      row {
        let list = (@dlg.list | geta @ssr.index | geta 1)

        column {
          cb: combobox style="margin: 5px; min-width: 150px;" dom_size=10
            titles=(@list | map_geta "title")
            {{ cb-follow-last }}

          insert_children input=@.. list=@dlg.below
        }
        r:column { // right
          let selected_object = (@list | geta @cb.index? default=null)
          //ic: insert_children input=@r list=@selected_object.gui
          ic: insert_children input=@r list=@dlg.right @selected_object
        }
      }

    } // колонка главная

  } // диалог
}

//////// короче делаем диалог добавления

coview-category title="Основное" id="basic" 
coview-record title="Оси координат" type="axes-view" id="basic"

//////////////////

feature "coview-category" {
  x: object 
      records=(m-eval {: known_records=@known_records id=@x.id | return (known_records || []).filter( x => x.params.id == id ) :})
}
feature "coview-record"

// filter_cats_func=func add_to=object

let known_cats = (find-objects-bf "coview-category")
let known_records = (find-objects-bf "coview-record")

// вход: массив идентификаторов категорий
// выход: список list в формате для add-object-dialog
fun "gather-cats" { |id_array|
  
  let my_cats = (m-eval {: cats=@known_cats id_array=@id_array |
    return cats.filter( x => id_array.indexOf( x.params.id )>=0 )
  :})

  //return (read @my_cats | map_geta "records" | arr_compact)
  //return (read @my_cats | map_geta "title" | arr_compact)

  return (@my_cats | map { |cat|
    list @cat.title @cat.records
  })
}

// вход: list=(список записей о категориях) target=куда-вставлять
// list = массив элементов вида [ надпись, список-объектов-record ] 
// выход: событие created(obj)
feature "add-object-dialog" 
{
  dlg: dialog 
  style="min-width: 500px"
  {
    column {

      ssr: switch_selector_row 
                 index=0
                 items=(@dlg.list | map_geta 0)
                 {{ hilite_selected }}
                 visible=(@ssr.items.length > 0)
    
      row {
        // list есть список объектов coview-record
        let list = (@dlg.list | geta @ssr.index | geta 1)
        column {
          cb: combobox style="margin: 5px; min-width: 150px;" dom_size=10
            titles=(@list | map_geta "title")
            index = 0
        }
        r:column { // right
          let selected_object = (@list | geta @cb.index? default=null)
          ba: button_add_object add_to=@dlg.target add_type=@selected_object.type
            visible=@selected_object
          connect (event @ba "created") (method @dlg "close")
          connect (event @ba "created") (event @dlg "created")
          //connect @ba.created @dlg.created
          //ic: insert_children input=@r list=@selected_object.gui

        }
      }

    } // колонка главная

  }
}

// вход: 
feature "add-object-dialog-0" {
  dlg: manage-lists-dialog 
    list=@alist 
    below=null 
    style_w="min-width: 500px"
    target=null // куда добавлять
    filter_func={: return true :} // функция фильтр категорий
    right={ |obj|
      ba: button_add_object add_to=@dlg.target add_type=@obj.type
      connect (event @ba "click") (method @dlg "close")
    }
  {
    let types = (find-objects-bf "coview-record")
    //console-log "types=" @types
    let alist = (find-objects-bf "coview-category" | map { |x|
      list @x.title (m-eval {: types=@types id=@x.id | 
          //console.log("filtering types",types)
          return types.filter( x => x.params.id == id ) 
      :})
    })
  }
}

/*
coview-category title="Основное" id="basic"
coview-record title="Оси координат" type="axes-view" id="basic"
feature "coview-category"
feature "coview-record" {
  x: object gui={
    button_add_object add_to
    //button "Добавить"
    //creator
  }
}
*/

load "./data-artefact.cl"