// Описание языка программирования Compalang:
// https://github.com/viewzavr/vrungel/tree/main/develop/compalang

load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative"
load "init.cl"

project: the_project 
{

  layer title="Физкульт-привет" {
    process output=(list @pts) {
      pts: cv_spheres input=(df_create X=[0,1,2] Y=[1,1,5] Z=[1,0,1])
      //pts: cv_spheres input=(df positions=[1,2,3, 5,5,2 ]
    }
    camera pos=[10,10,10];
  }

//    axes: axes-view size=10
//    axes2: axes-view size=5 title="Малые оси"

    v1: the_view_recursive title="Визуализация"
    actions={
      //b: button "Визпроцессы" //on_click={ method @d "show" | put-value 1 }
      //d: manage-objects-list-dialog list=(find-objects-bf "visual-process" root=@project)
           //list=(list @axes)
      //reaction (event @b "click") {: console.log('click') :}
      //connect (event @b "click") (method @d "show")

/*    connect (event @b "click") (method @d "show")
      b: button "Сущности" //on_click={ method @d "show" | put-value 1 }
      d: manage-lists-dialog (list 
          (list "Данные" (find-objects-bf "data-artefact" root=@project) @project (gather-cats ["data-io"]))
          (list "Расчёты" (find-objects-bf "computation" root=@project) @project (gather-cats ["compute"]))
          (list "Образы" (find-objects-bf "visual-process" root=@project) @project (gather-cats ["basic"]))
          (list "Экраны" (find-objects-bf "the_view_recursive" root=@project) @project (gather-cats ["screen"]))
      )
*/      

      connect (event @b "click") (method @d "show")
      b: button "Слои" //on_click={ method @d "show" | put-value 1 }
      d: manage-lists-dialog (list 
          (list "Слои" (find-objects-bf "layer" root=@project) @project (gather-cats ["layer"]))
          (list "Экраны" (find-objects-bf "the_view_recursive" root=@project) @project (gather-cats ["screen"]))

          /* хотя это же идея - сквозной поиск.. ммм
          (list "Данные" (find-objects-bf "data-artefact" root=@project) @project (gather-cats ["data-io"]))
          (list "Расчёты" (find-objects-bf "computation" root=@project) @project (gather-cats ["compute"]))
          (list "Образы" (find-objects-bf "visual-process" root=@project) @project (gather-cats ["basic"]))
          */          
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
      {
          camera pos=[10,10,10];
          area_container_horiz {
            area_3d //sources_str="@axes"
          }
      }

}

//////////////////////////////////////////////////////// главное окно программы

screen1: screen ~auto-activate  {
  rp: render_project @project active_view_index=0;
}