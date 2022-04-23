load "lib3dv3 csv params io gui render-params df scene-explorer-3d 12chairs.cl landing.cl";

fileparams: {
  f1_info: param_label "Укажите текстовый файл с данными";
  f1:  param_file value="https://viewlang.ru/assets/other/landing/2021-10-phase.txt";
  lines_loaded: param_label (@dat0 | get name="length");

  dat0: load-file file=@fileparams->f1
         | parse_csv separator="\s+";

  // on изменение в выборе файла - перейти в вид1
};

prgparams:
{

  loaded_data: @dat0 | df_set X="->x[м]" Y="->y[м]" Z="->z[м]" T="->t[c]"
                RX="->theta[град]" RY="->psi[град]" RZ="->gamma[град]"
              | df_div column="RX" coef=57.7
              | df_div column="RY" coef=57.7
              | df_div column="RZ" coef=57.7;

  time_slider: param_slider
       min=0 
       max=(@loaded_data->output | get "length" | @.->input - 1)
       //max3=(eval @_dat->output code="(df) => df ? df.length-1 : 0")
       //max2=(@time->values | arr_length | compute_output code=`return env.params.input-1`) 
       step=1 
       value=@time->index
       ;

  time: param_combo 
       values=(@loaded_data | df_get column="T")
       index=@time_slider->value
       ;

};

feature "view0" text="Выбор файла" {
  render-params  input=@fileparams;
};

screen1: screen auto-activate {
   column padding="1em" {
       ssr: switch_selector_row index=1 items=["Выбор файла","Основное","Ракета"];

       column {
         if (@ssr->index > 0) {
           column plashka {
            text "Время";
            render-params @prgparams;
           };
         };
       };

       of: one_of 
              index=@ssr->index
              list={ 
                view0;
                view1 loaded_data=@loaded_data->output time_index=@time->index;
                view1 loaded_data=@loaded_data->output time_index=@time->index; 
              }
              {{ one-of-keep-state }}
              ;

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