load "lib3dv3 csv params io gui render-params df scene-explorer-3d 12chairs.cl landing.cl";

prgparams:
{
  f1:  param_file value="https://viewlang.ru/assets/other/landing/2021-10-phase.txt";
  lines_loaded: param_label value=(@dat0 | get name="length");

  dat0: load-file file=@prgparams->f1
         | parse_csv separator="\s+";

  loaded_data: @dat0 | df_set X="->x[м]" Y="->y[м]" Z="->z[м]" T="->t[c]"
                RX="->theta[град]" RY="->psi[град]" RZ="->gamma[град]"
              | df_div column="RX" coef=57.7
              | df_div column="RY" coef=57.7
              | df_div column="RZ" coef=57.7;

};

screen1: screen auto-activate {
   column padding="1em" {
       ssr: switch_selector_row items=["Основное","Ракета"];

       render-params @prgparams;

       of: one_of 
              index=@ssr->index
              list={ view1 loaded_data=@loaded_data->output; view2; }
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
             console.log("one-of-keep-state: restoring from dump",dump)
             obj.restoreFromDump( dump, true );
         }
       }`;
     };
  };
};