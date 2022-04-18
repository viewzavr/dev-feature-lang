load "lib3dv3 csv params io gui render-params df scene-explorer-3d 12chairs.cl landing.cl";

screen1: screen auto-activate {
   column padding="1em" {
       ssr: switch_selector_row items=["Основное","Ракета"];

       of: one_of 
              index=@ssr->index
              list={ view1; view2; }
              {{ one-of-keep-state }}
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

//modify @screen1 { red; };
// так то это аналог получается сейчас insert_features
// в том смысле что это поселение в поддерево особое
// ну и выставка .input ....

debugger-screen-r;

feature "one_of_keep_state" {
  root: modify input=@. {
    on "destroy_obj" {
       lambda @root->input code=`(oneof, obj, index) => {
         let dump = obj.dump();
         let oparams = oneof.params.objects_params || [];
         oparams[ index ] = dump;
         //console.log("dump=",dump)
         oneof.setParam("objects_params", oparams, true );
       }`;
     };

     on "create_obj" {
       lambda @root->input code=`(oneof, obj, index) => {
         let oparams = oneof.params.objects_params || [];
         let dump = oparams[ index ];
         //console.log("using dump to restore",dump)
         if (dump) {
             dump.manual = true;
             obj.restoreFromDump( dump, true );
         }
       }`;
     };
  };
};