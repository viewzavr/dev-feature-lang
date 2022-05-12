load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc imperative";

debugger-screen-r;


s: arr=[1,2,3,4,5]
  {
  alfa: beta=15;
  teta:
    beta=25
  {{ x-add-cmd name="cmd1" code=(i-call-block {
      args: i-args;
      i-console-log "privet"; //output=22; 
      i-sum  @args->0 2;
      })
  }}
  {
    zita: r=4;
    tuta: js={"a":5, "b":4};
  };
};

screen auto_activate {
    column {
    
      text (join "result is 4?" (geta input=@s "teta" "zita" "r" )); // доступ к параметру поглубже
      
    
      text (join "result is 1? " (@s->arr | geta 0) {{ console_log_params }}); // тест массива
      
      
      text (join "result is 15? " (geta input=@s "alfa" "beta")); // доступ к параметру
      text (join "result is nul? " (geta input=@s "alfa" "beta" "teta" "zita" )); // промах
      
      text (join "result is obj? " (geta input=@s "teta" "zita" )); // доступ к объекту
      
      text (join "result is 22 (and log message)? " (geta input=@s "teta" "cmd1" 20 )); // доступ к методу
      text (join "result is 5? " (geta input=@s "teta" "tuta" "js" "a" )); // json-доступ
      
      text (join "result is child names separated by ::? " (geta input=@s (i-call-js @.->input code="(obj) => obj.ns.getChildNames()") "join" "::" )); // вычисление функции
      
      
      // map_get
      
      //text (join "result is suares of 1..5? " (map_get input=@s->arr (i-mul @~->input @~->input)));
      // тут косяк в том что мы передаем элемент в i-mul уже как позиционный (такова сигнатура наша в geta) и i-mul портится..
      // а input ему даж не прилетает... а @.->input выше - это обращение к наруже.. какие чудеса..
      text (join "result is squares of 1..5? " (map_geta input=@s->arr (i-call-block { args: i-args; i-mul @args->0 @args->0})));
      
      text (join "result is squares of 1..5 +10? " 
                  (map_geta input=@s->arr 
                     (i-call-block { args: i-args; i-mul @args->0 @args->0})
                     (i-call-block { args: i-args; i-sum @args->0 10})
                  )
          );
          
      text (join "result is squares of 1..5 +10? (using pipes)"
               (@s->arr 
                  | map_geta (i-call-block { args: i-args; i-mul @args->0 @args->0})
                  | map_geta (i-call-block { args: i-args; i-sum @args->0 10})
               )
          );
          
      text (join "result is 15,25? " (map_geta input=(get_children_arr input=@s->.) "beta"));
      
      text (join "result is 15,25? 2nd syntax" (map_geta input=(@s | get_children_arr) "beta"));
      
      text (join "result is 15,25? 3rd syntax" (@s->. | get_children_arr | map_geta "beta"));
      
      text (join "result is 15,25? 3rd syntax and no nulls" (@s->. | get_children_arr | map_geta "beta" | arr_filter code="(val,index) => val != null" ));

      
   };
};      
      

/*      
      text (
        join "result is sum of squares of 1..5? " 
          (map_get input=@s->arr (i-call-block { args: i-args; i-mul @args->0 @args->0})) | arr_reduce (i-lambda { args: i-args; i-sum @args->0 @args->1 }) 0;
      );

      text (
        join "result is sum of squares of 1..5? " 
          (map_get input=@s->arr (i-call-block { args: i-args; i-mul @args->0 @args->0})) | arr_reduce (lambda (args) ( i-sum @args->0 @args->1 )) 0;
      );

    };
*/
/*
    spisok {
      text (join "result is " (geta input=@s "alfa" "beta"));
      text (join "result is " (geta input=@s "alfa" "beta" "teta" "zita" ));
      text (join "result is " (geta input=@s "teta" "zita" "r" ));
      text (join "result is " (geta input=@s "teta" "zita" ));
    };
};
*/
/*
todo: 
* children должны быть св-вом чтобы пересчитываться когда чилдрены меняются..
* прикладное дерево (и setParent для него)

feature "spisok" {
  in: input=(@in->. | geta "children") {
    insert input=@in->.. {
      dom tag="ul" {
        @in->input | repeater {
          t: dom tag="li" {
            @t->input | geta "setAppParent" @t;
          };
        };
      };
    };
  };
};
*/