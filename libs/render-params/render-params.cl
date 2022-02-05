/*
  вход 
  * objects - массив объектов, параметры которых следует нарисовать
  * input - массив объектов, параметры которых следует нарисовать

  * todo:
  * opened_states - массив что раскрыть а что схлопнуть
  * opened - true/false сразу про всех
*/

/*
register_feature name="render_gui_title" code=`
  env.onvalue("text", (v) => {
    debugger;
    env.host.render_gui_title = v;

  });
`;
*/
// env.params.object?.render_gui_title ||


register_feature name="render-guis" {
  rep: repeater opened=true {
    column {
          button text=@btntitle->output cmd="@pcol->trigger_visible" 
           {{ deploy input=@rep->button_features }};
          
          pcol: column visible=false { /* @../../..->opened */
            render-params object=@../..->modelData;
            btntitle: compute_output object=@../..->modelData code=`
              return env.params.object?.params.gui_title || env.params.object?.ns.name;
            `;
          }
          
        };
    };
};

/* вход: object_path - путь к объекту
         либо 
         object - прямо  объект

*/

register_feature name="render-params" {
  rp: column gap="0.1em" {
    link to=".->object" from=@..->object_path tied_to_parent=true soft_mode=true; // тут надо maybe что там объект и тогда норм будет..
    repeater model=@getparamnames->output {
      column {
        //text text=@..->modelData;
        render-one-param obj=@rp->object name=@..->modelData;
      }
    };

    getparamnames: compute_output input=@..->object code=`
      // console.log("GPN: object=",env.params.input, "GN=",env.params.input ? env.params.input.getGuiNames() : "null")
      if (env.params.input) {
          // return env.params.input.getGuiNames();
          // но нет, надо взять те что не internal..
          let gn = env.params.input.getGuiNames();
          let acc = [];
          for (let nn of gn)
            if (!env.params.input.getParamOption(nn,"internal"))
              acc.push( nn );
          return acc ; /// так-то было бы удобно если бы эти gui-names были тоже просто параметром
     }
    ` {
      js code=`
        env.ns.parent.on("remove",() => {
        //console.log("getparamnames removes..");
        //debugger;
        });

      env.ns.parent.on("parentChanged",() => {
        //console.log("getparamnames parent changed..");
        //debugger;
      });
      env.ns.parent.on("parent_change",() => {
        //console.log("getparamnames parent changed..");
        //debugger;
      });
      `;
    };

    // а кстати классно было бы cmd="(** file_uploads)->recompute"
    connection object=@..->object event_name="gui-added" cmd="@getparamnames->recompute";

    // todo - вставить сюда рекурсию для детей и для фич.. или хотя бы для фич.. можно управляемую @idea

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
      link to=@../..->param_path from=".->value" tied_to_parent=true 
        soft_mode=true manual_mode=true;
      dom_event name="change" code=`
        env.params.object.setParam("value",env.params.object.dom.value,true);
      `;
    };
  };
};

register_feature name="render-param-text" {
  pf: param_field {

      link from=@pf->param_path to="@ta->dom_value" tied_to_parent=true;
      link to=@pf->param_path from=".->value" tied_to_parent=true 
        soft_mode=true manual_mode=true;

    button text="Редактировать" {
      dlg: dialog {
        column {
          text text="Content";
          ta: dom tag="textarea" style="width: 70vh; height: 30vh";
          button text="Enter" cmd="@commit->apply";

          commit: func pf=@pf ta=@ta dlg=@dlg code=`
              let v = env.params.ta?.dom?.value;
              debugger;
              env.params.pf.setParam("value", v )
              env.params.dlg.close();
          `;
        }
      }
    }
  }
};

register_feature name="render-param-cmd" {
  button text=@.->name cmd=@.->param_path;
};

register_feature name="render-param-float" {
  column {
    text text=@..->name;

    dom tag="input" {
      link from=@../..->param_path to=".->dom_obj_value" tied_to_parent=true;
      link to=@../..->param_path from=".->value" tied_to_parent=true 
         manual_mode=true
         soft_mode=true; // пустышки не передаем

      dom_event name="change" code=`
        env.params.object.setParam("value",env.params.object.dom.value,true);
      `;
    };
  };
};

register_feature name="render-param-checkbox" {
  checkbox text=@.->name {
    link from=@..->param_path to=".->value" tied_to_parent=true;
    link to=@..->param_path from=".->value" tied_to_parent=true 
      manual_mode=true soft_mode=true;
  }
};

register_feature name="render-param-color" {
  column {
    text text=@..->name;
    //text text=" : ";
    select_color {
      link from=@../..->param_path to=".->value" tied_to_parent=true;
      link to=@../..->param_path from=".->value" tied_to_parent=true 
        manual_mode=true soft_mode=true;
/*
      connection event_name="param_value_changed" object=@.. code=`
        debugger;
      `;
*/      
    };
  };
};

register_feature name="render-param-file" {
  pf: param_field {
    link from=@pf->param_path to="@ff->value" tied_to_parent=true;
    link to=@pf->param_path from="@ff->value" tied_to_parent=true soft_mode=true;
    ff: file;
  };
};

register_feature name="render-param-files" {
  pf: param_field {
    link from=@pf->param_path to="@ff->value" tied_to_parent=true;
    link to=@pf->param_path from="@ff->value" tied_to_parent=true soft_mode=true;
    ff: files;
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
        link to=@../../..->param_path from=".->value" tied_to_parent=true 
          soft_mode=true manual_mode=true;
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
      // console_log text="IF2 value=" input=@if2->value;

      /*
      dom tag="input" style="width:30px;" {
        link from=@../../..->param_path to=".->dom_value" tied_to_parent=true;
      }
      */
    };
  };
};

register_feature name="param_field" {
  dom tag="fieldset" style="border-radius: 5px; padding: 4px;" {
    dom tag="legend" innerText=@..->name;
  };
};

register_feature name="render-param-combovalue"
{
  param_field {

    combobox {
      link from=@../..->param_path to=".->value" tied_to_parent=true;
      link to=@../..->param_path from=".->value" tied_to_parent=true 
        soft_mode=true manual_mode=true;

      compute obj=@../..->obj name=@../..->name code=`
        
        if (env.params.obj && env.params.name) {
          var values = env.params.obj.getParamOption( env.params.name,"values" ) || [];

          if (!env.ns.parent)
            debugger; // чтото странное

          env.ns.parent.setParam("values",values);
          // todo ловить когда эти values меняются.
          // по сути все-таки "параметр" с его ключами
          // должен вести себя как объект, тогда можно к нему залинковаться..
        }
      `;
    };

  };
};

/*
register_feature name="render-param-combovalue"
{
  column {
    text text=@..->name;

    combobox {
      link from=@../..->param_path to=".->value" tied_to_parent=true;
      link to=@../..->param_path from=".->value" tied_to_parent=true 
        soft_mode=true manual_mode=true;

      compute obj=@../..->obj name=@../..->name code=`
        
        if (env.params.obj && env.params.name) {
          var values = env.params.obj.getParamOption( env.params.name,"values" ) || [];

          if (!env.ns.parent)
            debugger; // чтото странное

          env.ns.parent.setParam("values",values);
          // todo ловить когда эти values меняются.
          // по сути все-таки "параметр" с его ключами
          // должен вести себя как объект, тогда можно к нему залинковаться..
        }
      `;
    };

  };
};
*/

register_feature name="render-param-editablecombo"
{
  root: column {
    text text=@..->name;

    editablecombo
      values=(@root->gui | compute_output code=`
          if (!env.params.input) return [];
          return env.params.input.getValues()
      `;)
      {
      link from=@../..->param_path to=".->value" tied_to_parent=true;
      link to=@../..->param_path from=".->value" tied_to_parent=true 
        soft_mode=true manual_mode=true;
    };
  };
};