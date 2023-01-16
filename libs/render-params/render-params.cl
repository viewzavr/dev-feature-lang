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
  rep: repeater opened=true { |obj|
    das1: column {
            btn: button 
              text=(@obj | m_eval "(obj) => obj.params.gui_title || obj.params.title || obj.ns.name")
              cmd=@pcol->trigger_visible
              {{ insert_features input=@btn list=@rep->button_features? }};

            pcol: column visible=false 
            style="padding-left:10px; margin-bottom: 5px; border: 1px solid grey; border-top: 0px !important;"
            {
              render-params object=@obj;
              insert_children input=@pcol list=@rep.extra? @obj;
            };
          
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
          for (let nn of gn) {
            if (env.params.input.getParamOption(nn,"internal"))
              continue;
            //if (env.params.input.getParamOption(nn,"visible") == false)
            //  continue;  
            acc.push( nn );
          }

          // экспериментально.. хотя так-то часто надо..    
          acc = acc.sort( (a,b) => {
            let x = env.params.input.getParamOption(a,"priority") || 100;
            let y = env.params.input.getParamOption(b,"priority") || 100;
            if (x<y) return -1;
            if (x>y) return 1;
            return 0;
          } );
          
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

// filters={ params-hide list="title"; params-priority list="add-current";}
feature "params-priority" {
  pp: eval @pp->list 
        code="(params_list) => {
           //console.log('pppp',arr,list)
           let arr = env.params.input;
           if (!arr) return;
           if (!params_list) return;
           return arr.sort( (a,b,index) => params_list.indexOf(a) >= 0 ? -1 : (a<b) )
         }";
};

// filters={ params-hide list="title"; params-priority list="add-current";}
feature "params-hide" {
  pp: eval @pp->list 
        code="(params_list) => {
           let arr = env.params.input;
           if (!arr) return;
           if (!params_list) return;
           return arr.filter( (a) => params_list.indexOf(a) < 0 )
         }";
};

register_feature name="render-params" {
  rp: column gap="0.1em" object=@.->input? input=@.->0?
  {

    link to=".->object" from=@..->object_path? tied_to_parent=true soft_mode=true; // тут надо maybe что там объект и тогда норм будет..

    // а кстати классно было бы cmd="(** file_uploads)->recompute"
    // connection object=@..->object event_name="gui-added" cmd="@getparamnames->recompute";

    insert_children @extra_filters list=@rp->filters?

    ///console-log "repa=" @rep

    read @rp->object? | get-params-names | extra_filters: pipe
    | rep: repeater { |name|
      column {
        render-one-param obj=@rp->object name=@name
      }
    }

    // todo - вставить сюда рекурсию для детей и для фич.. или хотя бы для фич.. можно управляемую @idea

  };
};

// вход: obj объект, name имя параметра

register_feature name="render-one-param" {
  dg: dom_group {{

      //x-on "param_obj_changed"  cmd="@x->apply";
      //x-on "param_name_changed" cmd="@x->apply";
      //x: func {{ delay_execution }} cmd="@dm->apply";

      connect (param @dg "obj") (method @dm "apply")
      connect (param @dg "name") (method @dm "apply")
      //connect (timeout 1) (method @dm "apply")
      method @dm "apply" | put-value null

      // ну хорошо, а зачем? вроде типы у нас не шибко меняются..
      // выяснилось что слайдер читает gui-структуру.. и сообразно не перестраивается.
      // конечно если это бы все хранилось в отдельной vz-объектоной структуре то было бы лучше
      //read @dg->obj | get-cell (join "gui-changed-" @dg->name) | c-on @x->apply;
      connect (event @dg->obj (join "gui-changed-" @dg->name)) (method @dm "apply")

      // старое
      //@dg->obj | get-cell (join "gui-changed-" @dg->name) | c-on "(pname, x) => x ? x() : null" @x->apply;
      

    }}
    {
      
      dm: recreator list={
        row {
          render-one-param-p obj=@dg->obj name=@dg->name;
          //text "<a href='#'>@</a>";
        };
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

        if (obj.getParamOption(name,"visible") == false)
          env.setParam("visible",false);

        tr2 = obj.trackParamOption( name,"visible",(v) => {
          env.setParam("visible",v);
        })

    })

    env.on("remove",() => {
      if (tr) tr(); 
      if (tr2) tr2();
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
  cos: column {
    text text=@..->name;
    dt: dom tag="input" dom_obj_readOnly=(get_param_option @cos->obj @cos->name "readonly") {
      link from=@../..->param_path to=".->dom_value" tied_to_parent=true;
      //link to=@../..->param_path from=".->value" tied_to_parent=true 
      //  soft_mode=true manual_mode=true;
      reaction (dom_event_cell @dt "change") {: event_data obj=@cos->obj name=@cos->name |
        obj.setParam(name, event_data.target.value, true )
        :}
      
    };
  };
};

feature name="render-param-vector" {
  cos: column
  {
    text text=@..->name;

    input_vector_c
      dom_obj_readOnly=(get_param_option @cos->obj @cos->name "readonly")
      value=(read-param @cos->param_path)
      
      {{ x-on 'user-changed' {
              m_lambda "(obj,name,obj2,val) => {
                obj.setParam(name, val, true);
              }" @cos->obj @cos->name;
         } }};
   };         
};

/*
feature name="render-param-string" {
  cos: column {
    text text=@..->name;
    dom tag="input" dom_obj_readOnly=(get_param_option @cos->obj @cos->name "readonly")
    {
      link from=@../..->param_path to=".->dom_value" tied_to_parent=true;
      link to=@../..->param_path from=".->value" tied_to_parent=true 
        soft_mode=true manual_mode=true;
      dom_event name="change" code=`
        env.params.object.setParam("value",env.params.object.dom.value,true);
      `;
    };
  };
};
*/

register_feature name="render-param-array" {
  pf: param_field {

      link from=@pf->param_path to="@pf->value" tied_to_parent=true;
      link to=@pf->param_path from=".->value" tied_to_parent=true 
        soft_mode=true manual_mode=true;

    button text="Редактировать" {
      dlg: dialog {
        column {
          //text text="Введите массив"; // todo hints

          text style="max-width:70vh;"
               ((get_param_option @pf->obj @pf->name "hint") or "Введите массив");

          ta: dom tag="textarea" style="width: 70vh; height: 30vh;" 
                dom_obj_value=(m_eval "(txt) => txt.join ? txt.join(' ') : txt.toString()" @pf->value)
                  ;
          button text="ВВОД" cmd=@commit->apply;

          commit: func pf=@pf ta=@ta dlg=@dlg code=`
              let v = env.params.ta?.dom?.value;
              let arr = v.split(/[ ,]+/).map(parseFloat);
              env.params.pf.setParam("value", arr, true );
              env.params.dlg.close();
          `;
        }
      }
    }
  }
};


register_feature name="render-param-text" {
  pf: param_field {

      link from=@pf->param_path to="@ta->dom_obj_value" tied_to_parent=true;
      link to=@pf->param_path from=".->value" tied_to_parent=true 
        soft_mode=true manual_mode=true;

    button text="Редактировать" {
      dlg: dialog {
        column {
          //text text="Введите текст"; // todo hints
          text style="max-width:70vh;"
               ((get_param_option @pf->obj @pf->name "hint") or "Введите массив");

          ta: dom tag="textarea" style="width: 70vh; height: 30vh;" 
                  ;
          button text="ВВОД" cmd=@commit->apply;

          //text style="max-width:70vh;"
          //     (get_param_option @pf->obj @pf->name "hint");

          commit: m_lambda `(pf,ta,dlg) => {
                let v = ta.dom?.value;
                pf.setParam("value", v, true )
                dlg.close();
            };
          ` @pf @ta @dlg check_params=true;
        }
      }
    }
  }
};

register_feature name="render-param-cmd" {
  button text=@.->name cmd=@.->param_path;
};

register_feature name="render-param-float" {
  dc: column {
    text text=@..->name;

    d: dom tag="input" {
      link from=@../..->param_path to=".->dom_obj_value" tied_to_parent=true;
      link to=@../..->param_path from=".->value" tied_to_parent=true 
         manual_mode=true
         soft_mode=true; // пустышки не передаем

      reaction (dom_event_cell @d "change") {: event_data obj=@d |
         obj.setParam("value", parseFloat( event_data.target.value ), true )
      :}

    }
  }
}

register_feature name="render-param-checkbox" {
  cb: checkbox text=@.->name {
    link from=@..->param_path to=".->value" tied_to_parent=true;
    link to=@..->param_path from=".->user_value" tied_to_parent=true 
      manual_mode=true soft_mode=true;

    connect (event @cb "user_change") (param @cb->obj @cb->name manual=true)

  }
};

register_feature name="render-param-color" {
  co: column {
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
    link to=@pf->param_path from="@ff->output" tied_to_parent=true soft_mode=true;
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
    // link from=@str->param_path to="@tx->text" tied_to_parent=true;
    tx: text style="max-width:220px" text=(read-param @str->param_path default="-");
  };
};

register_feature name="render-param-slider" {
  rps: column {
    text text=@..->name;
    row {
      /* перестало работать
      list (get-cell-by-path @rps.param_path manual=true) (get-cell input=@sl "value") (get-cell input=@if2 "value")
        | bind-cells initial_value=(get-cell-by-path @rps.param_path | get-value);
      */  

/* зацикливает
      // передаем имеющееся
      reaction existing=true (get-cell-by-path @rps.param_path) (get-cell input=@sl "value")
      reaction existing=true (get-cell-by-path @rps.param_path) (get-cell input=@if2 "value")

      // не передаем имеющееся. но зато когда передаем - ставим флаг manual
      reaction (get-cell input=@sl "value") (get-cell-by-path @rps.param_path manual=true) 
      reaction (get-cell input=@if2 "value") (get-cell-by-path @rps.param_path manual=true) 
*/      

      let param_ch = (get-cell-by-path @rps.param_path)
          param_ch_m = (get-cell-by-path @rps.param_path manual=true)
          slider_ch = (get-cell input=@sl "value")
          editor_ch = (get-cell input=@if2 "value")

/*
      reaction @param_ch existing=true {: val slider_ch=@slider_ch editor_ch=@editor_ch |
         if (slider_ch && slider_ch.get() != val)
             slider_ch.set(val)
         if (editor_ch && editor_ch.get() != val)    
             editor_ch.set(val)
      :}
      
      reaction @slider_ch {: val param_ch_m=@param_ch_m |
         if (param_ch_m && param_ch_m.get() != val)
             param_ch_m.set( val,true )
      :}

      // codea reaction (list ....) и там позиционно пусть тупо всех шлет, undefined кроме значения которое пришло
      reaction @editor_ch {: val param_ch_m=@param_ch_m |
         if (param_ch_m && param_ch_m.get() != val)
             param_ch_m.set( val,true )
      :}
*/      

      read @param_ch | get-value | pass_if_changed | put-value-to (list @slider_ch @editor_ch)
      read @slider_ch | get-new-value | pass_if_changed | put-value-to @param_ch_m
      read @editor_ch | get-new-value | pass_if_changed | put-value-to @param_ch_m


      sl: slider manual=false 
      {
        compute obj=@rps->obj name=@rps->name gui=@rps->gui code=`
          var sl = env.ns.parent;
          if (env.params.gui) {
            sl.setParam("min", env.params.gui.min );
            //console.log("render-params: setting slider max",env.params.gui.max,"for",env.params.name,env.getPath() )
            sl.setParam("max", env.params.gui.max );
            sl.setParam("step", env.params.gui.step );
            

            if (env.params.obj) {
              
              if (env.params.obj.getParamOption( env.params.name,"sliding") == false)
                sl.setParam("sliding",false );
              else sl.setParam("sliding",true );
            };
            
            //console.log("calling refresh_slider_pos",env.params.gui)
            //sl.callCmd("refresh_slider_pos");
          }
        `;
      };
      if2: input_float style="width:30px;";
    };
  };
};

register_feature name="param_field" {
  dom tag="fieldset" style="border-radius: 5px; padding: 4px;" {
    dom tag="legend" innerText=@..->name;
  };
};

// F-PARAM-CUSTOM
register_feature name="render-param-custom"
{
  pf: dom_group {
    oo: insert_children input=@.. list=(get_param_option @pf->obj @pf->name "editor");

    x-modify input=@oo->output {
      x-set-params object=@pf->obj name=@pf->name;
    };
  };
};

register_feature name="render-param-combovalue"
{
  param_field {

    combobox style_h="max-width: 160px;" {
      link from=@../..->param_path to=".->value" tied_to_parent=true;
      link to=@../..->param_path from=".->value" tied_to_parent=true 
        soft_mode=true manual_mode=true;

      compute obj=@../..->obj name=@../..->name code=`
        
        if (env.params.obj && env.params.name) {
          var values = env.params.obj.getParamOption( env.params.name,"values" ) || [];

          if (values?.bind) {
            values=values();
          }

          if (!env.ns.parent)
            debugger; // чтото странное

          env.ns.parent.setParam("values",values);
          // todo ловить когда эти values меняются.
          // по сути все-таки "параметр" с его ключами
          // должен вести себя как объект, тогда можно к нему залинковаться..

          var titles = env.params.obj.getParamOption( env.params.name,"titles" );
          if (titles?.bind) titles=titles();

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