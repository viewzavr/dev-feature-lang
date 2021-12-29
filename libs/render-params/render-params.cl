/*
  вход 
  * object - массив объектов, параметры которых следует нарисовать

  * todo:
  * opened_states - массив что раскрыть а что схлопнуть
  * opened - true/false сразу про всех
*/

register_feature name="render-guis" {
  repeater model=@.->objects opened=true {
        column {
          button text=@btntitle->output cmd="@pcol->trigger_visible";
          
          pcol: column visible=false { /* @../../..->opened */
            render-params object=@../..->modelData;
            btntitle: compute_output object=@../..->modelData code=`
              return env.params.object?.ns.name;
            `;
          }
          
        };
      };
};

/* вход: input - путь к объекту [или сам объект наверное..ну пусть будет путь]
         либо 
         object - прямо  объект

*/

register_feature name="render-params" {
  column gap="0.1em" {
    link to=".->object" from=@..->object_path tied_to_parent=true; // тут надо maybe что там объект и тогда норм будет..
    repeater model=@getparamnames->output {
      column {
        //text text=@..->modelData;
        render-one-param obj=@../..->object name=@..->modelData;
      }
    };

//    objfind: path2obj input=@..->input;
    getparamnames: compute_output input=@..->object code=`
      
      // console.log("GPN: object=",env.params.input, "GN=",env.params.input ? env.params.input.getGuiNames() : "null")
      if (env.params.input)
          return env.params.input.getGuiNames(); /// так-то было бы удобно если бы эти gui-names были тоже просто параметром
    ` {
      js code=`
            env.ns.parent.on("remove",() => {
        console.log("getparamnames removes..");
        //debugger;
        });

      env.ns.parent.on("parentChanged",() => {
        console.log("getparamnames parent changed..");
        //debugger;
      });
      env.ns.parent.on("parent_change",() => {
        console.log("getparamnames parent changed..");
        //debugger;
      });
      `;
    };

    // а кстати классно было бы cmd="(** file_uploads)->recompute"
    connection object=@..->object event_name="gui-added" cmd="@getparamnames->recompute";

  };
};

// вход: obj объект, name имя параметра

register_feature name="render-one-param" code='
  var tr;
  env.onvalue("obj",(obj) => {
    //debugger;
    if (tr) tr();
    tr = env.onvalue("name",(name) => {
        // итак есть объект, есть параметр в переменной name
        var g = obj.getGui(name);
        if (!g) return;
        //if (name.length <= 1 || name == "object") debugger;
        env.setParam("param_path",obj.getPath() + "->" + name);
        env.setParam("gui",g);
        env.feature( `render-param-${g.type}` );
        // вот. вызвали фичу сообразно типу
    })
  });
';

/* апи рисования параметров
   вход
     param_path - путь к параметру (объект->имя)
     obj объект
     name имя параметра
     gui - gui-запись о параметре
   выход
     ожидается что фича будет отображать визуально значение указанного параметра,
     и менять значения указанного параметра по мере ввода пользователя
*/

register_feature name="render-param-string" {
  column {
    text text=@..->name;
    dom tag="input" {
      link from=@../..->param_path to=".->dom_value" tied_to_parent=true;
      dom_event name="change" code=`
        object.ns.parent.setParam("value",env.params.object.dom.value,true);
      `;
    };
  };
};

register_feature name="render-param-cmd" {
  button text=@.->name cmd=@.->param_path;
};

register_feature name="render-param-float" {
  dom tag="input" {
    link from=@..->param_path to=".->dom_value" tied_to_parent=true;
    link to=@..->param_path from=".->value" tied_to_parent=true;
    dom_event name="change" code=`
      object.setParam("value",env.params.object.dom.value,true);
    `;
  };
};

register_feature name="render-param-checkbox" {
  checkbox text=@.->name {
    link from=@..->param_path to=".->value" tied_to_parent=true;
    link to=@..->param_path from=".->value" tied_to_parent=true manual_mode=true;
  }
};

register_feature name="render-param-color-todo" {
  select_color {
    link from=@..->param_path to=".->value" tied_to_parent=true;
    link to=@..->param_path from=".->value" tied_to_parent=true manual_mode=true;

    connection event_name="param_value_changed" object=@.. code=`
      debugger;
    `;
  }
};

register_feature name="render-param-file" {
  file {
    link from=@..->param_path to=".->value" tied_to_parent=true;
    link to=@..->param_path from=".->value" tied_to_parent=true;
  };
};

register_feature name="render-param-label" {
  row {
    text text=@..->name;
    text text=" = ";
    text {
      link to=".->text" from=@../..->param_path tied_to_parent=true;
    };
  };
};

register_feature name="render-param-slider" {
  column {
    text text=@..->name;
    row {
      slider {
        link from=@../../..->param_path to=".->value" tied_to_parent=true;
        link to=@../../..->param_path from=".->value" tied_to_parent=true;
        //link from=@..->param_path->min to="..->min";
        compute obj=@../../..->object name=@../../..->name gui=@../../..->gui code=`
          var sl = env.ns.parent;
          if (env.params.gui) {
            sl.setParam("min", env.params.gui.min );
            sl.setParam("max", env.params.gui.max );
            sl.setParam("step", env.params.gui.step );
          }
        `;
      };
      if2: input_float style="width:30px;" {
        link from=@../../..->param_path to=".->value" tied_to_parent=true;
        link to=  @../../..->param_path from=".->value" tied_to_parent=true;
      };
      console_log text="IF2 value=" input=@if2->value;

      /*
      dom tag="input" style="width:30px;" {
        link from=@../../..->param_path to=".->dom_value" tied_to_parent=true;
      }
      */
    };
  };
};

register_feature name="render-param-combovalue"
{
  combobox {
    link from=@..->param_path to=".->value" tied_to_parent=true;
    link to=@..->param_path from=".->value" tied_to_parent=true;
    //link from=@..->param_path" to="..->min";

    compute obj=@..->obj name=@..->name code=`
      
      if (env.params.obj && env.params.name) {
        var values = env.params.obj.getParamOption( env.params.name,"values" ) || [];

        env.ns.parent.setParam("values",values);
        // todo ловить когда эти values меняются.
        // по сути все-таки "параметр" с его ключами
        // должен вести себя как объект, тогда можно к нему залинковаться..
      }
    `;
  }
};