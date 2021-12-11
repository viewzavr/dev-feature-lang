
/* вход: input - путь к объекту.. или сам объект наверное..
     ну пусть будет путь
*/

register_feature name="render-params" {
  column gap="0.1em" {
    link to=".->object" from=@..->input;
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
      if (env.params.input)
          return env.params.input.getGuiNames();
    `;

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
    link from=@..->param_path to="..->dom_value";
    dom_event name="change" code=`
      object.setParam("output",env.params.object.dom.value,true);
    `;
  };
};

register_feature name="render-param-float" {
  dom tag="input" {
    link from=@..->param_path to="..->dom_value";
    link to=@..->param_path from="..->output";
    dom_event name="change" code=`
      object.setParam("output",env.params.object.dom.value,true);
    `;
  };
};

register_feature name="render-param-file" {
  file {
    link from=@..->param_path to=".->value";
    link to=@..->param_path from=".->value";
  };
};

register_feature name="render-param-slider" {
  slider {
    link from=@..->param_path to="..->value";
    //link from=@..->param_path->min to="..->min";
    js code=`
    `;
  }
};

register_feature name="render-param-combovalue"
{
  combobox {
    link from=@..->param_path to=".->value";
    link to=@..->param_path from=".->value";
    //link from=@..->param_path" to="..->min";
    js code=`
       //env.ns.parent.onvalue("obj",(obj) => {
    `;
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