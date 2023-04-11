//////////////////////////////// понятие категории и записи в категории

feature "coview-category" {
  x: object 
      records=(m-eval {: known_records=@known_records id=@x.id | return (known_records || []).filter( x => x.params.cat_id == id ) :})
}

feature "coview-record"

// filter_cats_func=func add_to=object

let known_cats = (find-objects-bf "coview-category")
let known_records = (find-objects-bf "coview-record")

// вход: массив идентификаторов категорий которые нам подходят; либо вариант 2 - функция
// выход: список list в формате для add-object-dialog
fun "gather-cats" { |id_array|

  let my_cats = (m-eval {: cats=@known_cats id_array=@id_array |
    if (Array.isArray( id_array ))
      return id_array.map( id => cats.find( c => c.params.id == id))
    return cats.filter( x => id_array(x) )
  :})

  return (@my_cats | map { |cat|
    list @cat.title @cat.records
  })
}

feature "primary-cats" {
  object output=(find-objects-bf "primary-cat" | map { |cat|
    list @cat.title @cat.records
  })
}
feature "primary_cat" {}

////////////////////////////////////////// диалог управления списком объектов

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
    style_w="min-width: 600px; min-height: 500px;" // todo увеличивать эти значения по мере роста диалога
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
      //paint-gui @obj
      let default_painting={paint-gui @obj}
      column {
         insert_children input=@.. list=(@obj.gui? or @default_painting)
      } 
    }
  {
    column {
      // console-log "@dlg.list=" @dlg.list
      // insert_children input=@.. list=@dlg.above

      ssr: switch_selector_row 
                 index=0
                 items=(@dlg.list | map_geta 0)
                 {{ hilite_selected }}
    
      row {
        let list = (@dlg.list | geta @ssr.index | geta 1)

        column {
          cb: combobox style="margin: 5px; min-width: 150px;" dom_size=10
            titles=(@list | map_geta "title")
            {{ cb-follow-last-on-length-change }}

          insert_children input=@.. list=@dlg.below
        }

        r:column style="margin: 5px;" { // right
          let selected_object = (@list | geta @cb.index? default=null)
          //ic: insert_children input=@r list=@selected_object.gui
          ic: insert_children input=@r list=@dlg.right @selected_object
        }
      }

    } // колонка главная

  } // диалог
}

///////////////////// диалог добавления нового объекта


// вход: list=(список записей о категориях) target=куда-вставлять
// list = массив элементов вида [ надпись, список-объектов-record ] 
// выход: событие created(obj)
feature "add-object-dialog" 
{
  dlg: dialog 
  style="min-width: 500px"
  { 
    connect (event @dlg "opened") {: list=@dlg.list |
       //console.log("opened, list=",list)
      :}
    //console-log "add-object-dialog list=" @dlg.list
    column {

      ssr: switch_selector_row 
                 index=0
                 items=(@dlg.list | map_geta 0)
                 {{ hilite_selected }}
                 visible=(@dlg.list.length > 0)
    
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

/*
          reaction (event @ba "created") {: obj dlg=@dlg| 
             console.log('emitting manually_added',obj); 
             debugger
             dlg.feature("delayed")
             dlg.timeout( () => {
               obj.emit( 'manually_added' ) 
             }, 10)  
          :}
*/         

          event (event @ba "created" | get-value) "manually_added" | pause_input 10 | put-value true

          // codea заменить слово reaction на connect. и тогда вот мы соединяем каналы между собой, каналы с кодами..

          // todo button_add_object перенести куды сюды поближе

          //connect @ba.created @dlg.created
          //ic: insert_children input=@r list=@selected_object.gui

        }
      }

    } // колонка главная

  }
}
