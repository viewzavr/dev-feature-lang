register_feature name="collapsible" {
  cola: 
  column //button_type=["button"]
  {
    shadow_dom {
      //btn: manual_features=@cola->button_type text=@../..->text cmd="@pcol->trigger_visible";
      btn: button text=@../..->text cmd="@pcol->trigger_visible";

      pcol: 
      column visible=@cola->expanded {{ use_dom_children from=@../..; }};
      // сохраняет состояние развернутости колонки в collapsible-е
      // без этого сохранения не получится т.к. содержимое колонки 
      // не проходит dump по причине что shadow_dom вычеркнул себя из списка детей.
      // возможно это стоит и полечить.
      link from="@pcol->visible" to="@cola->expanded" manual_mode=true;

      insert_features input=@btn  list=@cola->button_features;
      insert_features input=@pcol list=@cola->body_features;

    };

  };
};

register_feature name="plashka" {
  style_p="background: rgba(99, 116, 137, 0.86); padding: 5px;"
  style_b="border-left: 8px solid #00000042;
                      border-bottom: 1px solid #00000042;
                      border-radius: 5px;
                      margin-bottom: 5px;
                     ";
};


// рисует набор кнопочек для управления объектами сцены
/*
   пример
    render_layers 
         title="Визуальные объекты" 
         root=@vroot
         items=[ {"title":"Объекты данных", find":"guiblock datavis","add":"linestr"},
                 {"title":"Статичные","find":"guiblock staticvis","add":"axes"},
                 {"title":"Текст","find":"guiblock screenvis","add":"select-t"}
               ];

   заметки
    sibling_titles sibling_types - внедрены в. мб вынести            
*/

feature "render_layers_inner" {
};

feature "render_layers" {

rl_root: 
    collapsible text=@.->title
    style="min-width:250px" 
    style_h = "max-height:90vh;"
    body_features={ set_params style_h="max-height: inherit; overflow-y: auto;"}
    {
     s: switch_selector_column {{ hilite_selected }} plashka
         items=(@rl_root->items | arr_map code="(v) => v.title") style="width:200px;";

     button "Добавить" margin="1em" {
        
        link from=(@rl_root->items | get @s->index | get "add_to") to="@cre->target";

        cre: creator input={} // target=@r1
          {{ onevent name="created" 
             newf=(@rl_root->items | get @s->index | get "add")
             code=`
                 args[0].manuallyInserted=true;

                 // сейчас мы через фичи инициализируем новые объекты через manual_features
                 // чтобы выбранный тип "сохранялся" в состоянии сцены.
                 // в будущем это можно будет изменить на другой подход
                 //args[0].manual_feature( "linestr" );
                 //args[0].setParamManualFlag("manual_features");
                 //let s = "linestr";
                 let s = env.params.newf;
                 args[0].setParam("manual_features",s,true)
                 
                 console.log("created",args[0])
             `
          }};
     };

     find-objects-bf (@rl_root->items | get @s->index | get "find") 
                     root=@rl_root->root
                     recursive=false
     | eval code="(arr) => {
       if (!env.params.input) return [];
       return env.params.input.sort( (a,b) => {
        function getpri(q) { 
            if (!q.params.block_priority)
               q.setParam( 'block_priority', q.$vz_unique_id,true )
            return q.params.block_priority;   
          }
        return getpri(a) - getpri(b); 
       })
       }"
     | repeater {
             co: column plashka style_r="position:relative;" {
               //text (@co->input);
               row {
                 text "Образ: ";
                 combobox  values=(@co->input | get_param "sibling_types" )
                           titles=(@co->input | get_param "sibling_titles")
                           value=(detect_type @co->input @.->values)
                           style="width: 120px;" 
                   {{ on "user_changed_value" { // "param_value_changed"
                      lambda @co->input code=`(obj,v) => {
                        // вот мы спотыкаемся - что это, начальное значение или управление пользователем

                        //console.log("existing obj",obj,"creating new obj type",v);

                        let dump = obj.dump();

                        //console.log("dump is",dump)

                        let newobj = obj.vz.createObj({parent: obj.ns.parent});
                        newobj.manual_feature( v );
                        newobj.manuallyInserted=true;

                        //newobj.feature( v );
                        //let newobj = obj.vz.createObjByType({type: v, parent: obj.ns.parent});

                        if (dump) {
                          if (dump.params)
                              delete dump.params['manual_features'];
                          dump.manual = true;
                          //console.log("restoring dump",dump);
                          newobj.restoreFromDump( dump, true );
                        }

                        obj.remove();

                        }`;

                   }
                   }};
               };
               /*
               col: column {
                  insert_children input=@col list=(@rl_root->before_each | get @s->index)
                    | console_log_input "yyyyyyyyyyyyyyyyyyy"
                    // | x-modify { x-set-params obj_input=@co->input }
                    ;
               };
               */
               column {
                  insert_children input=@.. list=(@co->input | get_param name="gui");
               };

               button "x" style="position:absolute; top:0px; right:0px;" 
               {
                 lambda @co->input code=`(obj) => { obj.removedManually = true; obj.remove(); }`;
               };  
             };
          };

    };

}; // render-layers            

// по объекту выдает его первичный тип (находя его в массиве types)
// эта странная вещь т.к. я отказался от типа объекта и теперь его не знаю. хм.
detect_type: feature {
  eval code="(obj,types) => {
    //console.log('detect_type:',obj,types)
    if (obj && types) {
      for (let f of types)
        if (obj.$features_applied[f]) {
          //console.log(f);
          return f;
        };
    };
    //console.log(undefined)
  }"
};

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

/*
   рисует "интерфейс". пример:

   render_interface
       left={
          collapsible text="Основные параметры" style="min-width:250px;" padding="10px"
          {
            render-params  input=@mainparams;
          }; 
       }
       middle={}
       right={
        render_layers title="Визуальные объекты" 
           root=@vroot
           items=[ {"title":"Объекты данных", "find":"guiblock datavis","add":"linestr"},
                   {"title":"Статичные","find":"guiblock staticvis","add":"axes"},
                   {"title":"Текст","find":"guiblock screenvis","add":"select-t"}
                 ];
       };
*/

feature "render_interface" {

    dg: dom_group 
      {{ insert_children @left list=@dg->left;
         insert_children @middle list=@dg->middle; 
         insert_children @right list=@dg->right; 
      }}
      {
        row style="z-index: 3; color: white;" 
            class="vz-mouse-transparent-layout" 
            align-items="flex-start" // эти 2 строчки решают проблему мышки
        {
          left: column;
          middle: column;
        }; // row

        right: column style="position:absolute; right: 20px; top: 10px;"; 
    };
};




// работает в связке с one_of - сохраняет данные объекта и восстанавливает их
// идея также - сделать передачу параметров между объектами в духе как сделано переключение 
// типа по combobox/12chairs (см lib.cl)
// дополнительно - делает так чтобы в дамп системы не попадали параметры сохраняемого объекта
// а сохранялись бы внутри one-of и затем использовались при пересоздании
// таким образом one-of целиком сохраняет состояние всех своих вкладов в дампе системы

// прим: тут @root используется для хранения параметров и это правильно; но в коде он фигурирует как oneof
/*
feature "one_of_keep_state" {
  root: x_modify 
  {
    x-patch {
      lambda code=`(env) => {
         let origdump = env.dump;
         env.dump = () => {
           env.emit( "save_state");
           return origdump();
         }
       }`;
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
*/

// сохраняет состояние вкладок при переключении
feature "one_of_keep_state" {
  root: x_modify 
  {
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
         if (!oneof) return;
         let oparams = oneof.params.objects_params || [];
         let dump = oparams[ index ];
         if (dump) {
             dump.manual = true;
             //console.log("restoring tab",dump)
             obj.restoreFromDump( dump, true );

             /* 
             env.feature("delayed");
             let q = env.delayed( () => obj.restoreFromDump( dump, true ), 5);
             //obj.restoreFromDump( dump, true );
             q();
             */
         }
       }`;
     };
  };
};

// заменяет dump у one-of и у создаваемого им объекта таким образом, чтобы
// 1 создаваемый объект не выдавал dump при общем сохранении
// 2 создаваемый объект сохранял бы dump в переменную save_state[i] у one-of
// это позволяет корректно сохранять состояние всех вкладок 
// и восстанавливает его при перезагрузке страницы
feature "one_of_all_dump" {
  root: x_modify 
  {
    x-patch {
      lambda code=`(env) => {
         let origdump = env.dump;
         env.dump = () => {
           env.emit( "save_state");
           return origdump();
         }
       }`;
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

     x-on "create_obj" {
       lambda code=`(oneof, obj, index) => {
         let origdump = obj.dump;
         obj.dump = (force) => {
            if (force) return origdump();
         }
       }`;
     };
  };
};


