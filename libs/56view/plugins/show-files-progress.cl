// меняет экран по нажатию клавиши

find-objects-bf features="render_project" recursive=false 
|
insert_children { 
  column style="background-color: green; border: 1px solid lime; color: white; padding: 0.2em;" 
      style_pos="position:absolute; right: 1em; bottom: 1em;"
      //opacity=( cond ( (@/->loading_files | geta "length") "100%") ( "0%") )
      visible=( (@/->loading_files | geta "length") > 0 )
      style_q="opacity: 85%;"
  {
    text "Загружаются файлы...";
    repeater input=@/->loading_files {
      text @.->input;
    };
  };
};
