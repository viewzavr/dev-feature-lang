find-objects-bf features="render_project_right_col" recursive=false 
|
insert_children { manage_views; };

feature "manage_views" {

  collapsible "Настройка экрана" {

           co: column plashka 
                style_r="position:relative;" 
                input=@rend->active_view 
            {

              button_add_object "Добавить новый экран" add_to=@rend->project add_type="the-view-mix3d";  

              column {
                object_change_type text="Способ отображения:"
                   input=@co->input
                   types=(@co->input | get_param "sibling_types" )
                   titles=(@co->input | get_param "sibling_titles");
              };

              column {
                insert_siblings list=(@co->input | get_param name="gui");
              };

              button "Удалить экран" //style="position:absolute; top:0px; right:0px;" 
              {
                lambda @co->input code=`(obj) => { obj.removedManually = true; obj.remove(); }`;
              };

           };

/*
           render_layers_inner title="Виды" expanded=true
           root=@rend->project
           items=[ { "title":"Виды", 
                     "find":"the-view",
                     "add":"the-view",
                     "add_to": "@rend->project"
                   } ];
*/                   
         };

};         