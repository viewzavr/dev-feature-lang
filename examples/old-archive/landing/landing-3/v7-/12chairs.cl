///////////////////////////////////////////////////////////
////////////////////////// создавалка объектов по описанию
/////////////////////////////////////////////////////

// вход: list - объект содержащий список типов добавок.
//       mapping - окружение с описанием кого куда
register_feature name="addon_layer" {
  vlayer: 
    gui_title=( @.->list | get child=@selected_show->value | get param="title")
    items_in_list=(@.->list | get_children_arr | arr_filter code=`(c) => c.params.title`)
  {

    //gui_title: param_string;

    selected_show: param_combo 
       values=(@vlayer->items_in_list | arr_map code=`(c) => c.ns.name`)
       titles=(@vlayer->items_in_list | arr_map code=`(c) => c.params.title`);

    mapping_obj: {
         deploy_many input=@vlayer->mapping;
    };

    get_children_arr input=@mapping_obj | | arr_filter code=`(c) => c.params.target` 
    | repeater {
      recroot: // input это запись о мэппинге. это окружение с параметрами channel и target 
      channel=(@.->input | get param="channel")
      target=(@.->input | get param="target")
      { 
        deploy_many_to target=@recroot->target
           input=( @vlayer->list | get child=@selected_show->value | get param=@recroot->channel )
           include_gui_from_output
           {{ keep_state }}; // keep_state сохраняет состояние при переключении типов объектов
      };
    };

    // todo теперь сюда как-то суб-фичи прикрутить
    // мб. по селектору subfeature_target фильтровать

  };
};

register_feature name="keep_state" {
  ksroot: {
    connection object=@ksroot->.host event_name="before_deploy" vlayer=@ksroot code=`
          console.log("EEEE0 args=",args,"object=",env.params.object);
          let envs = args[0] || [];
          let existed_env = envs[0];
          
          if (!existed_env) return;
          
          let dump = existed_env.dump();
          console.log("EEEE generated dump",dump);

          //if (!env.params.vlayer) return;
          env.params.vlayer.setParam("item_state", dump);
        `;

        //onevent name="after_deploy" vlayer=@vlayer code=`
        // выглядит что проще добавить в onevent тоже обработку object, и уметь делать ссылки на хост.. @env->host
        // ну или уже сделать параметр такой..
    connection object=@ksroot->.host event_name="after_deploy" vlayer=@ksroot code=`
          //console.log("UUUU0",args);
          let envs = args[0] || [];
          let tenv = envs[0];
          
          if (!tenv) return;

          let dump = env.params.vlayer.getParam("item_state");
          console.log("UUUU0 using dump",dump);

          if (!dump) return;
          
          //dump.keepExistingChildren = true;
          //dump.keepExistingParams = true;
          dump.manual = true;
          tenv.restoreFromDump( dump, true );
        `;     
  };
};

/////////////////////////////////////////////////////
//////////////////////////////////////// гуи версия 1
/////////////////////////////////////////////////////

// вход - input, список объектов чьи гуи нарисовать
register_feature name="render-guis-nested" {
  rep: repeater opened=true {
    col: column {
          button 
            text=(compute_output object=@col->input code=`return env.params.object?.params.gui_title || env.params.object?.ns.name`) 
            cmd="@pcol->trigger_visible";

          pcol: column visible=true style="padding-left: 1em;" {
            render-params object=@col->input;

            find-objects pattern_root=@col->input pattern="** include_gui_inline"
               | 
               repeater {
                 render-params object=@.->input;
               };

            find-objects pattern_root=@col->input pattern="** include_gui"
               | render-guis;

            button text="Удалить" obj=@col->input {
              call target=@col->input name="remove";
            };
           };
         
        };
    };
};

// вход - input, объект чьу гуи нарисовать
register_feature name="render-guis-nested2" {
  col: column visible=true style="padding-left: 1em;" {

      column {

        render-params object=@col->input;

        find-objects pattern_root=@col->input pattern="** include_gui_inline"
             | 
             repeater {
               render-params object=@.->input;
             };

        find-objects pattern_root=@col->input pattern="** include_gui"
           | render-guis;

        // соберем из объектов созданных в каналах (render3d-items и т.п.)  
        find-objects pattern_root=@col->input pattern="** include_gui_from_output"
           | repeater {
               subr: column { // здесь input это каждый найденный объект в полях output

                  @subr->input | get param="output" | repeater {
                        find-objects pattern_root=@.->input pattern="** include_gui_inline"
                          | 
                           repeater {
                             render-params object=@.->input;
                           };
                   };

                  @subr->input | get param="output" | repeater {
                        find-objects pattern_root=@.->input pattern="** include_gui"
                          | render-guis;
                      };
                   };
               };

       };

       column {
         render-guis input=@extra;
       };

       extra: gui_title = "Настройки" {
          param_string name="title" value=(@col->input | get param="gui_title")
          {{
             onevent name="param_value_changed" tgt=@col->input in=@extra->title code=`
               if (env.params.tgt)
                   env.params.tgt.setParam("gui_title", env.params.in );
             `;
          }};
          param_cmd name="удалить слой" {
            call target=@col->input name="remove";
          };
        };

/*
       button text="[x]" style="position: absolute; right: 0px; bottom: 0px;" {
            call target=@col->input name="remove";
       };
*/       
         
   };
};

// вход: list - окружение со списоком описаний добавок.
//       mapping - соответствие каналов добавок объектам приложения (куды добавлять)
register_feature name="layers_gui" {

  lgui: column title=(@.->list | get param="title") {

      dom tag="h3" innerText=@lgui->title;

      button text="+ Добавить слой" style="margin-bottom:1em;" {
        creator target=@lgui input={
          addon_layer list=@lgui->list mapping=@lgui->mapping;
          // кстати вот не передавать бы аргументы а использовать модификатор тут..

        } {{ onevent name="created" code=`args[0].manuallyInserted=true;` }};
      };

      column gap="0.1em" {
        cb: combobox values=(@fo->output | arr_map code=`(r,index) => (1+index).toString()`)
               index=(@fo->output | compute_output code=`return (env.params.input?.length || 1)-1`);

        fo: find-objects pattern="** visual_layer";
        cobj: value=(@fo->output | get name=@cb->index);
        render-guis-nested2 input=@cobj->value; 
      };
  };

}      