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

/* вход: input - путь к объекту.. или сам объект наверное..
         ну пусть будет путь
         либо 
         object - прямо  объект
*/

register_feature name="render-params" {
  column gap="0.1em" {
    link to="..->object" from=@..->input; // тут надо maybe что там объект и тогда норм будет..
    repeater model=@getparamnames->output {
      column {
        text text=@..->modelData;
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
    link from=@..->param_path to=".->dom_value" tied_to_parent=true;
    link to=@..->param_path from=".->output" tied_to_parent=true;
    dom_event name="change" code=`
      object.setParam("output",env.params.object.dom.value,true);
    `;
  };
};

register_feature name="render-param-color" {
  dom tag="input" dom_type="color" {
    // передаем в дом
    // было:
    // link from=@..->param_path to=".->dom_value" tied_to_parent=true;

    // все-таки напрашивается в link вставить code. и на его базе можно делать экстракторы как у Дениса
    // или например даже создать ссылку на внешний метод обработки какой-то (в каком-то объекте cmd)

    // стало:
    link from=@..->param_path to=".->param_value" tied_to_parent=true;
    link from="@e1->output" to="..->dom_value";
    //e1: transform from=@..->param_path to="..->dom_value" code=`
    e1: compute inp=@..->param_value code=`
      /// работа с цветом    
      // c число от 0 до 255
      function componentToHex(c) {
          if (typeof(c) === "undefined") {
            debugger;
          }
          var hex = c.toString(16);
          return hex.length == 1 ? "0" + hex : hex;
      }

      // r g b от 0 до 255
      function rgbToHex(r, g, b) {
          return "#" + componentToHex(r) + componentToHex(g) + componentToHex(b);
      }  

      // triarr массив из трех чисел 0..1
      function tri2hex( triarr ) {
         return rgbToHex( Math.floor(triarr[0]*255),Math.floor(triarr[1]*255),Math.floor(triarr[2]*255) )
      }

      //if (env.params.inp)
      if (Array.isArray(env.params.inp)) {
          let h=tri2hex( env.params.inp );
          console.log("CC: computed dom elem color,",h)
          env.setParam("output", h)
      }
      //    return tri2hex( env.params.inp );
      //else
      //    return "#ffffff";
    `;

    
    // ловим событие от dom
    js code=`
      env.ns.parent.hex2tri = (hex) => {
        var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        return result ? [
            parseInt(result[1], 16) / 255.0,
            parseInt(result[2], 16) / 255.0,
            parseInt(result[3], 16) / 255.0
        ] : [1,1,1];
      }
    `;
    d1: dom_event name="change" code=`
      var c = env.ns.parent.hex2tri(env.params.object.dom.value);
      console.log("CC: setting param output to ",c);
      object.setParam("output",c,true);
    `;
    dom_event name="input" code=@d1->code;

    link to=@..->param_path from=".->output" tied_to_parent=true;
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
    link to=@..->param_path from=".->value" tied_to_parent=true;
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