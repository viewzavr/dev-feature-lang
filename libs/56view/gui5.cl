register_feature name="collapsible" {
  cola: 
  column text=@.->0 expanded=false
  //button_type=["button"]
  {
    shadow_dom {
      btn: button text=@../..->text {
        m_apply "(env) => env.setParam('expanded', !env.params.expanded, true)" @cola;
      };

      pcol: 
      column visible=@cola->expanded? {{ use_dom_children from=@../..; }};

      insert_features input=@btn  list=@cola->button_features?;
      insert_features input=@pcol list=@cola->body_features?;

    };

  };
};

register_feature name="plashka" {
  style_p="background: rgba(99, 116, 137, 0.86); padding: 5px;"
  style_b="border-left: 8px solid #00000042;
                      border-bottom: 1px solid #00000042;
                      border-radius: 5px;
                     "
  style_border_b="margin-bottom: 5px;"               
};

feature "sort_by_priority"
{
    eval code="(arr) => {
       if (!env.params.input) return [];
       let qprev;
       for (let q of env.params.input) {
         if (q.params.block_priority == null)
          {
            if (qprev)
              q.setParam('block_priority', qprev.params.block_priority+1,true);
            else
              q.setParam('block_priority',0,true);
          }
          else
          if (qprev && q.params.block_priority == qprev.params.block_priority)
            q.setParam('block_priority', qprev.params.block_priority+1,true);
         qprev = q;   
       }
       //console.log('after cure, arr is ',env.params.input);
       return env.params.input.sort( (a,b) => {
        function getpri(q) { 
            return q.params.block_priority;
          }
        return getpri(a) - getpri(b); 
       })
       }";    
};

feature "created_mark_manual" {
  onevent name="created" 
     code=`
         args[0].manuallyInserted=true;  
     `;
  ;    
};

// добавка
// curview параметр обязательный, процесс приезжает в аргументе
feature "created_add_to_current_view" {
  x-on "created" 
     code=`
         let item = arg2;
         env.params.curview.append_process( item );
         //let project = args[0].ns.parent;
         //args[0].manuallyInserted=true;
     `;
  ;
};

// add_to 
// add_type
feature "button_add_object" {
  bt_root: button "Добавить" margin="0.5em" {
        
        link from="@bt_root->add_to" to="@cre->target" soft_mode=true;

        cre: creator input={}
          {{ onevent 
             name="created" 
             newf=@bt_root->add_type
             btroot=@bt_root
             code=`
                 arg1.manuallyInserted=true;

                 // сейчас мы через фичи инициализируем новые объекты через manual_features
                 // чтобы выбранный тип "сохранялся" в состоянии сцены.
                 // в будущем это можно будет изменить на другой подход
                 //args[0].manual_feature( "linestr" );
                 //args[0].setParamManualFlag("manual_features");
                 //let s = "linestr";

                 let s = env.params.newf;
                 arg1.setParam("manual_features",s,true)
                 
                 console.log("created",arg1)

                 env.params.btroot.emit("created", arg1 );
             `
          }};
     };    
};

// add_to
// add_template это шаблон
feature "button_add_object_t" {
  bt_root: button "Добавить" margin="0.5em" {
        
        link from="@bt_root->add_to" to="@cre->target" soft_mode=true;

        cre: creator input=@bt_root->add_template
          {{ onevent 
             name="created" 
             //newf=@bt_root->add_type
             btroot=@bt_root
             code=`
                 arg1.manuallyInserted=true;

                 // сейчас мы через фичи инициализируем новые объекты через manual_features
                 // чтобы выбранный тип "сохранялся" в состоянии сцены.
                 // в будущем это можно будет изменить на другой подход
                 //args[0].manual_feature( "linestr" );
                 //args[0].setParamManualFlag("manual_features");
                 //let s = "linestr";

                 //let s = env.params.newf;
                 //arg1.setParam("manual_features",s,true)
                 
                 console.log("created",arg1)

                 env.params.btroot.emit("created", arg1 );
             `
          }};
     };    
};

//target_obj | object_change_type | console_log;
//вот тут хотелось бы... чтобы вместо object_change_type оказалось бы 2 объекта..

// можно оказывается напрямую на русском языке писать и это будут фичи;

// комбо выбиралки типа объекта
// input - объект, 
// types - список типов
// titles - список названий
feature "object_change_type"
{
   cot: text="Образ: " {};

   text @cot->text;

   cbb: combobox 
            values=@cot->types?
            titles=@cot->titles?
            value=(detect_type @cot->input? @cbb->values?)
            style="width: 120px;"
           {{ on "user_changed_value" {
              lambda @cot->input? @cot code=`(obj,cot, v) => {
                // вот мы спотыкаемся - что это, начальное значение или управление пользователем

                //console.log("existing obj",obj,"creating new obj type",v);

                let dump = obj.dump();

                let origparent = obj.ns.parent;
                obj.remove();

                //console.log("dump is",dump)

                let newobj = obj.vz.createObj({parent: origparent});
                Promise.allSettled( newobj.manual_feature( v ) ).then( () => {
                  newobj.manuallyInserted=true;

                  console.log("setted manual feature",v);

                  if (dump) {
                    if (dump.params)
                        delete dump.params['manual_features'];
                    dump.manual = true;
                    //console.log("restoring dump",dump);
                    newobj.restoreFromDump( dump, true );
                    console.log("created obj", newobj)
                  }

                  cot.emit('type-changed');
                });
                

                }`;

           }
           }}; // on user changed

};

// рисует набор кнопочек для управления объектами сцены
/* root - сцена где искать объекты
   пример
    render_layers_inner 
         title="Визуальные объекты" 
         root=@vroot
         items=[ {"title":"Объекты данных", find":"guiblock datavis","add":"linestr","add_to":"@some->path_param"},
                 {"title":"Статичные","find":"guiblock staticvis","add":"axes"},
                 {"title":"Текст","find":"guiblock screenvis","add":"select-t"}
               ];

   при этом у объектов должны быть параметры
    sibling_titles sibling_types - используется для смены типа объекта
    gui - используется для рендеринга визуального интерфейса
*/


feature "render_layers_inner" {

rl_root: 
    column text=@.->title
    style="min-width:250px" 
    style_h = "max-height:80vh;"
    {
     s: switch_selector_row {{ hilite_selected }} 
         items=(@rl_root->items | arr_map code="(v) => v.title")
         plashka style_qq="margin-bottom:0px !important;"
         ;

     link to="@ba->add_to" from=(@rl_root->items | geta @s->index | geta "add_to")
          {{ attach_scope @rl_root -2 }}
           ;
          
     ba: button_add_object 
                       add_type=(@rl_root->items | geta @s->index | geta "add");

     objects_list:
     find-objects-bf (@rl_root->items | geta @s->index | geta "find") 
                     root=@rl_root->root
                     recursive=false
                     include_root=false
     | sort_by_priority;
     ;

     /// выбор объекта

     cbsel: combobox style="margin: 5px;" dom_size=5 
       values=(@objects_list->output | arr_map code="(elem) => elem.$vz_unique_id")
       titles=(@objects_list->output | map_param "title")
       visible=( (@cbsel->values |geta "length") > 0)
       ;

    /// параметры объекта   

     co: column plashka style_r="position:relative; overflow: auto;"  
            input=(@objects_list->output | geta @cbsel->index? default=null)
            visible=(@co->input?)
      {
        row visible=((@co->input?  | geta  "sibling_types" | geta "length" default=0) > 1) 
        {
          object_change_type input=@co->input?
            types=(@co->input?  | geta  "sibling_types" )
            titles=(@co->input? | geta "sibling_titles")
            //types=(@co->input  | geta  "items" | geta (i_call_js code="Object.keys"))
            //titles=(@co->input  | geta  "items" | geta (i_call_js code="Object.values"))
            ;
        };

        column {
          insert_children input=@.. list=(@co->input? | geta "gui" default=[]);
        };

        if (has_feature input=@co->input? name="editable-addons") then={
          manage_addons input=@co->input?;
        };

        button "x" style="position:absolute; top:0px; right:0px;" 
        {
          lambda @co->input? code=`(obj) => { obj.removedManually = true; obj.remove(); }`;
        };

     };


  };   

};



// добавляет запись в таблицу типов
// todo сделать проще, просто @some->items | geta "push" {record};
feature "add_sib_item" code=`
  env.onvalues([0,1,2],(tgt,code,title)=> {
    let nv = (tgt.params.sibling_types || []).concat([code]);
    let nv2 = (tgt.params.sibling_titles || []).concat([title]);
    tgt.setParam("sibling_types",nv);
    tgt.setParam("sibling_titles",nv2);
    // может быть еще уж добавлять append-feature
    // env.vz.register_feature_append( code,tgt.params.name );
    // todo подумать не запутает ли это нас
  })
`;


// по объекту выдает его первичный тип (находя его в массиве types)
// эта странная вещь т.к. я отказался от типа объекта и теперь его не знаю. хм.
detect_type: feature {
  eval code="(obj,types) => {
    //console.log('detect_type:',obj,types)
    if (obj && types) {
      for (let f of types)
        //if (obj.$features_applied[f]) 
        if (obj.is_feature_applied(f)) 
        { 
          //console.log('detect-type',f,obj);
          return f;
        };
    };
    console.log('detect-type failed',obj,types);
  }";

};

/*
detect_type_l: feature {
  lambda code="(obj,types) => {
    if (obj && types) {
      for (let f of types)
        if (obj.$features_applied[f]) {
          return f;
        };
    };
  }"
};
*/

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
         //console.log("oneof: dump is",dump,oneof.params.objects_params)
         if (dump) {
             dump.manual = true;

             env.feature("delayed");
             env.delayed( () => {
                //console.log("oneof:restoring tab 2",dump)
                obj.restoreFromDump( dump, true );
             }, 15) (); // типа пусть репитер отработает.. если там внутрях есть..  

         }
       }`;
     };

    // выяснилась доп-история что на старте программы объект уже может быть создан
    // и нам надо это отловить..
    x-patch {
      lambda code=`(env) => {

        env.restoreFromDump = function ( edump, manualParamsMode, $scopeFor ) {
          
          if (env.params.output) { 
             let obj = env.params.output;
             let oparams = edump.params.objects_params || [];
             if (oparams) {
               let dump = oparams[ env.params.index ];
               //console.log("oneof: using extra dump",edump)
               if (dump) {
                   dump.manual = true;
                   //debugger;
                   env.feature('delayed');
                   env.delayed( () => {
                      //console.log("oneof:restoring tab",dump,obj)
                      obj.restoreFromDump( dump, true );
                    }, 15) (); // типа пусть репитер отработает.. если там внутрях есть..  
                   
               }
             }
          }
          return env.vz.restoreObjFromDump( edump, env, manualParamsMode, $scopeFor );
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


