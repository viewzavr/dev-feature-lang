load "lib3dv3 csv params io gui render-params df scene-explorer-3d 12chairs.cl landing.cl";

screen1: screen auto-activate {
   column padding="1em" {
       ssr: switch_selector_row items=["Основное","Ракета"];

       one_of 
              index=@ssr->index
              {{ console_log_params }}
              list={ view1; view2; }
              ;

/*     views: list {view1} {view2};
       ssr: switch_selector_row items=(@views | map_param "text");
       one_of list=(@views | map_param "name" | arr_join with=";" | compalang)
              index=@ssr->index
              {{ console_log_params }}
              //list={ view1; view2; }
              ;
*/              
   };          
};

debugger-screen-r;