load "lib3dv3 csv params io gui render-params df scene-explorer-3d 12chairs.cl";


///////////////////////////////////////
/////////////////////////////////////// точка входа
///////////////////////////////////////

views: list @screen1 @screen2;

//append_feature "qqq" "red";

register_feature name="common_part" {
   roro: row style="width:100%;" {
     text "Визуализация ракеты";
     ssr: switch_selector_row items=["Общий вид","Ракета"] qqq;
  };

};

feature "red" {
  console_log "РРРРРРРРРРРРРРРРРРРРРРРР";
  set_params style="background-color: red;"
};

feature "qqq" {
  console_log "РРРРРРРРРРРРРРРРРРРРРРРРqqq"; 
};

/* рабочее */
find-objects-bf "qqq" | console_log "найдено" | insert_features {
      //set_params style="background-color: red;"
      red;
      
      on "param_index_changed" {
        lambda code="(items,index) => {
           
           if (items) 
              items[index].callCmd('activate');
        }" @views->output;
      };
};


/* фантазия
find-objects-bf "qqq" | console_log "найдено" | modify {{
      set_params style="background-color: red;"
      on "param_index_changed" {
        lambda code="(items,index) => {
           debugger;
           if (items) 
              items[index].callCmd('activate');
        }" @views->output;
      };
}};
*/

/*
insert_features @roro {
  set_params style="background-color: red;"
};
*/  

find-objects-bf "qqq" | insert_children {
  text "добавка";
};

/*
create_by_user_type index=@view_selector->index 
          list=@views->list
          mapping={
              channel="main" target=@main;
              channel="screen" target=@viewscreen;
          };

al: create_by_user_type 
        list=(find-objects pattern="** data_visual")
        active=@dv->active
        mapping={
            channel="render3d-items" target=@dv->scene;
            channel="screen-items"   target=@dv->screen;
        };
      };
*/      

screen1: screen auto-activate {
   common_part;

   text "Экран 1";
};

screen2: screen {
   common_part;

   text "Экран 2";
};