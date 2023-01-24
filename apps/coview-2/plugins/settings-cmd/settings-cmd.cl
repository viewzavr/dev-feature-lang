find-objects-bf features="render_project_right_col" recursive=false 
    |
    insert_children { manage_main_objects block_priority=-5; };

feature "manage_main_objects" {
  dom_group {
      b: button "Настройка"

      d: manage-lists-dialog (list 
          (list "Слои" (find-objects-bf "layer" root=@project) @project (gather-cats ["layer"]))
          (list "Экраны" (find-objects-bf "the_view_recursive" root=@project) @project (gather-cats ["screen"]))
          (list "Плагины" (find-objects-bf "plugin" root=@/) @/ (gather-cats ["plugin"]))
      )

      connect (event @b "click") (method @d "show")        

      // слои цепляем в текущее вью новые
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