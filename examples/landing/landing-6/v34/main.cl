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

// прим: тут @root используется для хранения параметров и это правильно; но в коде он фигурирует как oneof
feature "one_of_keep_state" {
  root: modify input2=@. {
    console_log ">>>>>>>>>>>>>>>>>>>>>>> keep-state modifier applied";

    on "destroy_obj" {
       lambda @root->input2 code=`(oneof, obj, index) => {
         if (!oneof) return;
         let dump = obj.dump();
         let oparams = oneof.params.objects_params || [];
         oparams[ index ] = dump;
         //console.log("oneof dump=",dump)
         oneof.setParam("objects_params", oparams, true );
       }`;
     };

     on "create_obj" {
       lambda @root->input2 code=`(oneof, obj, index) => {
         console.log(">>>>>>>>>>>>>>>>>>>>>> on oneof create-obj: oneof=",oneof)
         if (!oneof) return;
         let oparams = oneof.params.objects_params || [];
         console.log(">>>>>>>>>>>>>>>>>>>>>> on oneof create-obj: objects_params=",oparams)
         let dump = oparams[ index ];
         console.log(">>>>>>>>>>>>>>>>>>>>>> on oneof create-obj: using dump to restore",dump)
         if (dump) {
             dump.manual = true;
             //console.log("one-of-keep-state: restoring from dump",dump)
             //console.log(oneof,obj,index)
             obj.restoreFromDump( dump, true );
         }
       }`;
     };

     on "save_state" {
       lambda @..->host code=`(oneof) => {
         if (!oneof) return;
         let obj = oneof.params.output;
         let index = oneof.params.index;
         if (obj && index >= 0) {
           let dump = obj.dump();
           let oparams = oneof.params.objects_params || [];
           oparams[ index ] = dump;
           //console.log("oneof saved current:",dump)
           oneof.setParam("objects_params", oparams, true );
         }  
       }`;
     }
  };
};

//find-objects-bf root=@of->output features="viewzavr-object" recursive=true | console_log_input "UUUUUUUUUUUUUU";


monitor_tree_params root=@of->output action={
  pause_apply {
    console_log text="eeeeeee";
    emit_event object=@of name="save_state";
  }
};


feature "monitor_tree_params" {
  root: {
    f: func {
      insert_children input=@f list=@root->action;
      // о поздравляю генератор таки ))) ну ибо func различает своих по другому смыслу.
    };

    find-objects-bf root=@root->root features="" recursive=true include_subfeatures=false
    //{{ console_log_params "UUUUUUUUUUUUUUUUUUUUU"}}
      | pause_input
      | console_log_input "modify input for param-changed"
      | x_modify {
      
      rt: x_on 'param_changed' {
        lambda @rt->host @f code="() => { console.log(33)}";
        
        /*
        lambda @rt->host @f code="(obj,f,name) => {
            console.log('see param change in', name,obj);
            if (obj && f) {
                let m = obj.getParamManualFlag( name );
                let i = obj.getParamOption(name,'internal')
                if (m && !i) {
                  //console.log('see manual param change in', name,obj);
                  f.callCmd('apply',obj,name);
                }
            }
        };";
        */
        
      };

      
      
    };    
  }
};

feature "pause_input" code=`
  env.feature("delayed");
  let pass = env.delayed( () => {
    env.setParam("output", env.params.input);
  },1000/30);

  env.onvalue("input",pass);
`;


feature "pause_apply" {
  r: func timeout=100 {{ delay_execution timeout=@r->timeout }};
};


/*
feature "timeout" code=`
  env.feature("delayed");
  let pass = env.delayed( () => {
    
  },1000/30);

  env.addCmd("apply",() => {
     pass();  
  })
`;
*/