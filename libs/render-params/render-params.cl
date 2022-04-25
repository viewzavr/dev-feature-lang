/*
  вход 
  * objects - массив объектов, параметры которых следует нарисовать
  * input - массив объектов, параметры которых следует нарисовать

  * todo:
  * opened_states - массив что раскрыть а что схлопнуть
  * opened - true/false сразу про всех
*/

// load "misc";

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
    das1: column {
            button text=@btntitle->output cmd="@pcol->trigger_visible" 
             {{ deploy input=@rep->button_features }};

          pcol: column visible=false { /* @../../..->opened */
            render-params object=@das1->modelData;
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

register_feature name="get-params-names" {
  eval code=`() => {

      env.unsub1 ||= () => {};
      env.unsub1();
      env.unsub1 = () => {};

      env.unsub2 ||= env.on("remove",() => {env.unsub1()})

      if (env.params.input) {
          // return env.params.input.getGuiNames();
          // но нет, надо взять те что не internal..
          let gn = env.params.input.getGuiNames();
          // console.log("gn=",gn,env.params.input)                

          let acc = [];
          for (let nn of gn)
            if (!env.params.input.getParamOption(nn,"internal"))
              acc.push( nn );
          
          env.unsub1 = env.params.input.on("gui-added",() => env.recompute() );
          //env.params.input.on("gui-changed",() => env.recompute() );

          return acc ; /// так-то было бы удобно если бы эти gui-names были тоже просто параметром
      }
    }`;
};

register_feature name="render-params-list" {
  rp: column gap="0.1em" {
    @rp->list | repeater {
      column {
        //text text=@..->modelData;
        render-one-param obj=@rp->object name=@..->input;
      }
    };
  };
};

register_feature name="render-params" {
  rp: column gap="0.1em" object=@.->input input=@.->0 {

    link to=".->object" from=@..->object_path tied_to_parent=true soft_mode=true; // тут надо maybe что там объект и тогда норм будет..

    // а кстати классно было бы cmd="(** file_uploads)->recompute"
    // connection object=@..->object event_name="gui-added" cmd="@getparamnames->recompute";

    @rp->object | get-params-names | repeater {
      column {
        //text text=@..->modelData;
        render-one-param obj=@rp->object name=@..->modelData;
      }
    };

    // todo - вставить сюда рекурсию для детей и для фич.. или хотя бы для фич.. можно управляемую @idea

  };
};

// вход: obj объект, name имя параметра

register_feature name="render-one-param" {
  dg: dom_group {{

      on "param_obj_changed"  cmd="@x->apply";
      on "param_name_changed" cmd="@x->apply";
      x: func {{ delay_execution }} cmd="@dm->apply";

      mmm: modify input=@dg->obj {
        on (join "gui-changed-" @dg->name) cmd="@dm->apply"
        {{
           on "connected" cmd="@dm->apply";
        }};
      }

    }}
    {
      
      dm: recreator list={
        render-one-param-p obj=@..->obj name=@..->name;
      };

    };
};

register_feature name="render-one-param-p" code='
  var tr,tr2;
  env.onvalue("obj",(obj) => {

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

    env.on("remove",() => {
      if (tr) tr(); 
      //if (tr2) tr2();
    })
  });
';

/* апи рисования параметров
   вход
     param_path - путь к параметру (объект->имя)
     obj   объект
     name  имя параметра
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

/*
register_feature name="render-param-label" {
  row {
    text text=@..->name;
    text text=" = ";
    text {
      link to=".->text" from=@../..->param_path tied_to_parent=true;
    };
  };
};*/

register_feature name="render-param-label" {
  str: param_field {
    //text text=@..->name;
    //text text="=";
    link from=@str->param_path to="@tx->text" tied_to_parent=true;
    tx: text;
  };
};

register_feature name="render-param-slider" {
  rps: column {
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
            //console.log("render-params: setting slider max",env.params.gui.max,"for",env.params.name,env.getPath() )
            sl.setParam("max", env.params.gui.max );
            sl.setParam("step", env.params.gui.step );
            
            //console.log("calling refresh_slider_pos",env.params.gui)
            //sl.callCmd("refresh_slider_pos");
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

          var titles = env.params.obj.getParamOption( env.params.name,"titles" );
          env.ns.parent.setParam("titles",titles);
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
          if (!env.params.input) return []; // здесь .input это gui получается
          return env.params.input.getValues()
      `;)
      {
      link from=@../..->param_path to=".->value" tied_to_parent=true;
      link to=@../..->param_path from=".->value" tied_to_parent=true 
        soft_mode=true manual_mode=true;
      };
  };
};

register_feature name="render-param-objref"
{
  root: param_field {
     combobox values=@obj_pathes->output value=@obj_path->output
     {
      // мб в будущем 
      // link from=@root->param_path to=".->value" tied_to_parent=true {{ convert_link_value code=`input.getPath()` }};
      obj_path: compute_output in=@root->param_path code=`return (env.params.input?.getPath ? env.params.input.getPath() : env.params.input)`;

      link to=@root->param_path from=".->value" tied_to_parent=true 
           soft_mode=true manual_mode=true;
     };

     button text="rescan" cmd="@obj_pathes->recompute";

     obj_pathes: compute_output gui=@root->gui obj=@root->obj name=@root->name 
     code=`
        let crit_fn = env.params.gui?.crit_fn 
                      || (env.params.obj ? env.params.obj.getParamOption( env.params.name,"crit_fn" ) : null)
                      || function(v) { return true; };

        function traverse(startobj, fn) {
          fn( startobj,name );

          var cc = startobj.ns.getChildren();
          for (let c of cc) 
            traverse( c, fn );
        };

        let root = env.findRoot();
        let objlist = [];
        traverse( root, function( obj ) {
          if (!crit_fn( obj )) return;
          objlist.push( obj.getPath() );
        });

        return objlist;
     `;

  };
};