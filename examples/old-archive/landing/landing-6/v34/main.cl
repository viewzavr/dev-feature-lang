load "lib3dv3 csv params io gui render-params df scene-explorer-3d 12chairs.cl landing.cl new-modifiers";

fileparams: {
  //f1_info: param_label "Укажите текстовый файл с данными";
  f1:  param_file value="https://viewlang.ru/assets/other/landing/2021-10-phase.txt";
  lines_loaded: param_label (@data_from_file | get name="length");

  data_from_file: load-file file=@fileparams->f1
         | parse_csv separator="\s+";

  // on изменение в выборе файла - перейти в вид1
  // но опять же - при старте программы это изменение тоже происходит.. 


};

timeparams: {
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

prgparams:
{

  loaded_data: @data_from_file | df_set X="->x[м]" Y="->y[м]" Z="->z[м]" T="->t[c]"
                RX="->theta[град]" RY="->psi[град]" RZ="->gamma[град]"
              | df_div column="RX" coef=57.7
              | df_div column="RY" coef=57.7
              | df_div column="RZ" coef=57.7;

};

feature "view0" text="Выбор файла" {
  column plashka {
    text "Укажите текстовый файл с данными";
    render-params  input=@fileparams;
    text "params done";
  };  
  // а зачем тут render-params - можно просто гуи порисовать
  // on изменение в выборе файла - перейти в вид1
  // порисовал - выглядит некрасиво
};

screen1: screen auto-activate {
   column padding="1em" {
       ssr: switch_selector_row index=1 items=["Выбор файла","Основное","Ракета"] 
                style_qq="margin-bottom:15px;" {{ hilite_selected }};

                
       of: one_of 
              index=@ssr->index
              list={ 
                view0;
                view1 loaded_data0=@data_from_file->output
                      loaded_data=@loaded_data->output 
                      time_index=@time->index 
                      time=@timeparams->time
                      time_params=@timeparams;
                view2 loaded_data0=@data_from_file->output 
                      loaded_data=@loaded_data->output 
                      time_index=@time->index 
                      time=@timeparams->time
                      time_params=@timeparams;
                view3;       
              }
              {{ one-of-keep-state; one_of_all_dump; }}
              ;

   };          
};

debugger-screen-r;

// *****************************
feature "view3" {
  column {
    text "privet";
  }
}