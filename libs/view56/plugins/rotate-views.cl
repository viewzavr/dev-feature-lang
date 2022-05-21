// меняет экран по нажатию клавиши

find-objects-bf features="render_project" recursive=false 
|
insert_children { 
  abh: apply_by_hotkey "c" {
    call "../.." "goto_next_view";
    console_log_apply "test";
  };
};
