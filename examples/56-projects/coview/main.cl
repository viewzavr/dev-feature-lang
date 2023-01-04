// Описание языка программирования Compalang:
// https://github.com/viewzavr/vrungel/tree/main/develop/compalang

load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative";
load "56view";


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
          (list "Данные" (find-objects-bf "artefact" root=@project) @project)
          (list "Расчёты" (find-objects-bf "computation" root=@project) @project)
          (list "Образы" (find-objects-bf "visual-process" root=@project) @project)
          (list "Экраны" (find-objects-bf "the_view_recursive" root=@project) @project)
      )

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

feature "manage-objects-list-dialog" {
  dlg: dialog 
    list=[] 
    right={ |obj|
      /*
      if (@obj.gui?) {
        insert_children input=(@obj.gui or
      }
      */
      render-params @obj
      //console-log "@obj=" @obj
    }
    style="width: 600px"
  {
    row {
      column {
        cb: combobox style="margin: 5px;" dom_size=10
          titles=(@dlg.list | map_geta "title")
         //index=0
         //values=(@objects_list | map_geta "id")
         //titles=(@objects_list | map_geta "title")
        row gap="0.1em" {
          button "+"
          button "-"
        }
      }
      r:column { // right
        let selected_object = (@dlg.list | geta @cb.index? default=null)
        ic: insert_children input=@r list=@selected_object.gui

        /*ic: insert_children input=@r list=@dlg.right //@selected_object
        reaction (create_channel @selected_object) {: sobj ic=(channel @ic 0)|
          ic.set( null )
          // я не понимаю, почему это работает... ну ладно..
          // почему оно успевает отреагировать на.. ну везет... 
          // но это все так неявно.. 
          ic.set( sobj )
        :}
        */
      }
    }
  }
}

/*
  list = массив элементов вида [ надпись, список-объектов, куды-добавлять-новое, функция-фильтр-категорий-нового ] 
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
            add: add-object-dialog target=@target_for_new
            connect (event @bplus "click") (method @add "show")

            reaction (event @bminus "click") {: cobj=@selected_object | cobj.remove() :}
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

feature "coview-category"
feature "coview-record"

coview-category title="Основное" id="basic"
coview-record title="Оси координат" type="axes-view" id="basic"

// filter_cats_func=func add_to=object
/*
feature "add-object-dialog" 
{
  dialog 
  style="min-width: 500px"
  list=@alist
  {{
    let types = (find-objects-bf "coview-record")
    //console-log "types=" @types
    let alist = (find-objects-bf "coview-category" | map { |x|
      list @x.title (m-eval {: types=@types id=@x.id | 
          //console.log("filtering types",types)
          return types.filter( x => x.params.id == id ) 
      :})
    })
  }}
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
               
        }
        r:column { // right
          let selected_object = (@list | geta @cb.index? default=null)
          //ic: insert_children input=@r list=@selected_object.gui

        }
      }

    } // колонка главная

  }
}
*/


feature "add-object-dialog" {
  dlg: manage-lists-dialog 
    list=@alist 
    below=null 
    style_w="min-width: 500px"
    target=null // куда добавлять
    filter_func={: return true :} // функция фильтр категорий
    right={ |obj|
      button_add_object add_to=@dlg.target add_type=@obj.type
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