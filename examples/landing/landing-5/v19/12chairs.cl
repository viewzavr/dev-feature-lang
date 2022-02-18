///////////////////////////////////////////////////////////
////////////////////////// создавалка объектов по описанию
/////////////////////////////////////////////////////

// модель  работы. на вход поступает массив описаний возможных объектов
// пользователю дается выбор какой объект создавать (на основе title описания)
// затем этот объект создается
// при этом анализируются его поля, содержащие описания окружений
// которые следуте добавить к тем или иным окружениям программы
// таким образом реализуется модель "добавок" в программу.
// это может быть использовано как для подключения функциональности к программе
// так и для реализации наборной модели визуального программирования.

// вход: list - объект содержащий список типов добавок.
//       mapping - окружение с описанием кого куда
register_feature name="addon_layer" {
  vlayer: 
    gui_title=( @.->list | get child=@selected_show->value | get_param name="title")
    items_in_list=(@.->list | get_children_arr | arr_filter code=`(c) => c.params.title`)
    active=true
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
           extra_features={set_params input=@vlayer->input active=@vlayer->active visible=@vlayer->active }
           {{ keep_state }}; // keep_state сохраняет состояние при переключении типов объектов
      };
    };

    //param_cmd name="dbg" text="test" in1=@vlayer->input code=`console.log( env.params.in1 )`;

    // todo теперь сюда как-то суб-фичи прикрутить
    // мб. по селектору subfeature_target фильтровать

  };
};

register_feature name="keep_state" {
  ksroot: {
    connection object=@ksroot->.host event_name="before_deploy" vlayer=@ksroot code=`
          //console.log("EEEE0 args=",args,"object=",env.params.object);
          let envs = args[0] || [];
          let existed_env = envs[0];
          
          if (!existed_env) return;
          
          let dump = existed_env.dump();
          //console.log("EEEE generated dump",dump);

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
          //console.log("UUUU0 using dump",dump);

          if (!dump) return;
          
          //dump.keepExistingChildren = true;
          //dump.keepExistingParams = true;
          dump.manual = true;
          tenv.restoreFromDump( dump, true );
        `;     
  };
};