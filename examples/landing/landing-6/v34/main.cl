load "lib3dv3 csv params io gui render-params df scene-explorer-3d 12chairs.cl landing.cl new-modifiers";

fileparams: {
  //f1_info: param_label "Укажите текстовый файл с данными";
  f1:  param_file value="https://viewlang.ru/assets/other/landing/2021-10-phase.txt";
  lines_loaded: param_label (@dat0 | get name="length");

  dat0: load-file file=@fileparams->f1
         | parse_csv separator="\s+";

  // on изменение в выборе файла - перейти в вид1
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

  loaded_data: @dat0 | df_set X="->x[м]" Y="->y[м]" Z="->z[м]" T="->t[c]"
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
};

screen1: screen auto-activate {
   column padding="1em" {
       ssr: switch_selector_row index=1 items=["Выбор файла","Основное","Ракета"] 
                style_qq="margin-bottom:15px;" {{ hilite_selected }};

       of: one_of 
              index=@ssr->index
              list={ 
                view0;
                view1 loaded_data=@loaded_data->output time_index=@time->index time_params=@timeparams;
                view1 loaded_data=@loaded_data->output time_index=@time->index time_params=@timeparams; 
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

// работает в связке с one_of - сохраняет данные объекта и восстанавливает их
// идея также - сделать передачу параметров между объектами в духе как сделано переключение 
// типа по combobox/12chairs (см lib.cl)
// дополнительно - делает так чтобы в дамп системы не попадали параметры сохраняемого объекта
// а сохранялись бы внутри one-of и затем использовались при пересоздании
// таким образом one-of целиком сохраняет состояние всех своих вкладов в дампе системы

// прим: тут @root используется для хранения параметров и это правильно; но в коде он фигурирует как oneof
feature "one_of_keep_state" {
  root: x_modify 
    {{ on 'attach' {
        //console_log_apply ">>>>>>>>>>>>>>>>>>>>>>> keep-state modifier applied 1";
     }
    }}
  {

    x-patch {
      lambda code=`(env) => {
         let origdump = env.dump;
         env.dump = () => {
           env.emit( "save_state");
           return origdump();
         }
       }`;
       //console_log_apply ">>>>>>>>>>>>>>>>>>>>>>> keep-state modifier applied 2";
    };

    x-on "save_state" {
       lambda code=`(oneof) => {
         if (!oneof) return;
         let obj = oneof.params.output;
         let index = oneof.params.index;
         if (obj && index >= 0) {
           let dump = obj.dump(true);
           let oparams = oneof.params.objects_params || [];
           oparams[ index ] = dump;
           oneof.setParam("objects_params", oparams, true );
         }  
       }`;
     };    

    x-on "destroy_obj" {
       lambda code=`(oneof, obj, index) => {
         if (!oneof) return;
         let dump = obj.dump(true);
         let oparams = oneof.params.objects_params || [];
         oparams[ index ] = dump;
         //console.log("oneof dump=",dump)
         oneof.setParam("objects_params", oparams, true );
       }`;
     };

     x-on "create_obj" {
       lambda code=`(oneof, obj, index) => {
         //console.log(">>>>>>>>>>>>>>>>>>>>>> on oneof create-obj: oneof=",oneof)
         if (!oneof) return;
         let oparams = oneof.params.objects_params || [];
         //console.log(">>>>>>>>>>>>>>>>>>>>>> on oneof create-obj: objects_params=",oparams)
         let dump = oparams[ index ];
         //console.log(">>>>>>>>>>>>>>>>>>>>>> on oneof create-obj: using dump to restore",dump)
         if (dump) {
             dump.manual = true;
             //console.log("one-of-keep-state: restoring from dump",dump)
             //console.log(oneof,obj,index)
             obj.restoreFromDump( dump, true );
         }

         let origdump = obj.dump;
         obj.dump = (force) => {
            if (force) return origdump();
         }
       }`;
     };
  };
};
