find-objects-bf features="render_project_right_col" recursive=false 
|
insert_children { manage_cameras; };

feature "manage_cameras" {

  mv: 
      collapsible "Камеры" 

      render_project=@..->render_project
      project=@..->project
      active_view=@..->active_view
      {

           co: column ~plashka 
                style_r="position:relative;" 
                input=@mv->active_view 
            {

              render_layers_inner title="Камеры" expanded=true
                root=@mv->project
                items=[ { "title":"Камеры", 
                     "find":"camera",
                     "add":"camera",
                     "add_to": "@mv->project"
                   } ];

           };

      };

};         