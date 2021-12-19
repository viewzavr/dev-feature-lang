
/* вход: input - путь к объекту.. или сам объект наверное..
         ну пусть будет путь
*/

register_feature name="render-params" {
  column gap="0.1em" {
    link to="..->object" from=@..->input; // тут надо maybe что там объект и тогда норм будет..
    repeater model=@getparamnames->output {
      column {
//      render_one_param obj=@objfind->output name=name=@..->modelData;
//        render-one-param obj=@..->object name=@.->modelData;
        text text=@..->modelData;
        render-one-param obj=@../..->object name=@..->modelData;
      }
    };

//    objfind: path2obj input=@..->input;
    getparamnames: compute_output input=@..->object code=`
      // console.log("GPN: object=",env.params.input, "GN=",env.params.input ? env.params.input.getGuiNames() : "null")
      if (env.params.input)
          return env.params.input.getGuiNames(); /// так-то было бы удобно если бы эти gui-names были тоже просто параметром
    `;

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
*/

register_feature name="render-param-string" {
  dom tag="input" {
    link from=@..->param_path to="..->dom_value" tied_to_parent=true;
    dom_event name="change" code=`
      object.setParam("output",env.params.object.dom.value,true);
    `;
  };
};

register_feature name="render-param-float" {
  dom tag="input" {
    link from=@..->param_path to="..->dom_value" tied_to_parent=true;
    link to=@..->param_path from="..->output" tied_to_parent=true;
    dom_event name="change" code=`
      object.setParam("output",env.params.object.dom.value,true);
    `;
  };
};

register_feature name="render-param-file" {
  file {
    link from=@..->param_path to=".->value" tied_to_parent=true;
    link to=@..->param_path from=".->value" tied_to_parent=true;
  };
};

register_feature name="render-param-slider" {
  slider {
    link from=@..->param_path to=".->value" tied_to_parent=true;
    link to=@..->param_path from=".->output" tied_to_parent=true;
    //link from=@..->param_path->min to="..->min";
    compute obj=@..->object name=@..->name gui=@..->gui code=`
      var sl = env.ns.parent;
      if (env.params.gui) {
        sl.setParam("min", env.params.gui.min );
        sl.setParam("max", env.params.gui.max );
        sl.setParam("step", env.params.gui.step );
      }
    `;
  }
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