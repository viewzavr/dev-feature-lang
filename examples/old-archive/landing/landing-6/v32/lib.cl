
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

feature "render_layers" {

rl_root: collapsible text=@.->title
    style="min-width:250px" 
    style_h = "max-height:90vh;"
    body_features={ set_params style_h="max-height: inherit; overflow-y: auto;"}
    {
     s: switch_selector_column {{ hilite_selected }} plashka
         items=(@rl_root->items | arr_map code="(v) => v.title") style="width:200px;";

     button "Добавить" margin="1em" {
        //creator target=@r1 input={show_vis}
        creator target=@r1 input={}
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
         if (!arr) return [];
       return arr.sort( (a,b) => {
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
               column {
                 deploy_many input=(@co->input | get_param name="gui");
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