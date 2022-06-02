find-objects-bf features="render_project_right_col" recursive=false 
|
insert_children { manage_glob_addons; };

feature "manage_glob_addons" {

   button "Управление эффектами" //cmd="@addons_dialog->show"
   {
     //setter target="@addons_dialog->container" value=( @ma->input | geta "addons_container");
     setter target="@addons_dialog->input" value=@ma->input;
     call target="@addons_dialog" name="show";
   };  
  
};         