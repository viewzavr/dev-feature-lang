
// назначение - нарисовать гуи для объекта модели
// вход
//   input - объект, гуи которого следует изобразить

register_feature name="paint_kskv_gui" {
  dg: dom_group {
  	  text text="paint_kskv_gui";
  	  console_log text="paint_kskv_gui called" input=@dg->input;
  	  deploy_many input=(@dg->input | get_param name="gui") {{ console_log_params text="paint_kskv_gui DM" }};
  	  button text="dbg" code=`debugger;`;
  };
};


//////////////////////////

register_feature name="collapsible" {
  cola: 
  column
  {
    shadow_dom {
      btn: button text=@../..->text cmd="@pcol->trigger_visible";

      pcol: 
      column visible=false {{ use_dom_children from=@../..; }};

      deploy_features input=@btn  features=@cola->button_features;
      deploy_features input=@pcol features=@cola->body_features;
    };

  };
};


register_feature name="collapsible_alt" {
  cola_alt: 
  column
  {
    shadow_dom {
      btn: button text=@cola_alt->text cmd="@pcol->trigger_visible";

      pcol: 
      column visible=false {{ use_dom_children from=@cola_alt; }};

      deploy_features input=@btn  features=@cola_alt->button_features;
      deploy_features input=@pcol features=@cola_alt->body_features;
    };

  };
};

// collapsible с active-флажком
register_feature name="collapsible2" {
  cola:
  column
  {
    shadow_dom {
      row {
        btn: button text=@cola->text cmd="@pcol->trigger_visible" flex=1;
        cba: checkbox value=@cola->active cola=@cola {{
          onevent name="user-changed" {
            emit_event object=@cola name="user-changed-active";
          };
        }};
      };

      pcol:
      column visible=false {{ use_dom_children from=@cola; }};

      deploy_features input=@btn  features=@cola->button_features;
      deploy_features input=@pcol features=@cola->body_features;
    };

  };
};

// рисует параметры со схлопнутым видом
// idea - может быть стоит рисовать не параметры, а гуи со схлопнутым видом?
register_feature name="render-guis2" {
  repeater opened=true {
    das1: 
      collapsible 
        text=(compute_output object=@.->input code=`return env.params.object?.params.gui_title || env.params.object?.ns.name;`) 
        body_features={set_params style="padding-left:1em;"}
    {
      render-params object=@das1->input;
    };
  };
};


//////////////////////////////////////////////////////

// рисует 1 слой - в виде плашки и списка объектов слоя, каждый посаженный в collapsible
//       text - надпись
//       layer - описание для вновь-добавляемых слоев
//       pattern - поиск объектов этого слоя 

// вот кстати здесь мы видим плохость в смешении окружений
// target это параметр layers_gui2, но он одновременно становится и параметром collapsible...
// а не факт что это то что нам было нужно. заманчиво конечно не заниматься передачей параметров,
// но с другой стороны явная передача выглядит для дальнейшего восприятия лучше..
// todo поанализировать эти случаи, когда и что и как мы используем и что ожидаем.


register_feature name="layers_gui2" {

  lgui: collapsible 
          target=@.
          //body_features={set_params style="padding:0.2em 0.2em 0.2em 0.4em; gap: 0.2em;";}
  {

    button text="+ Добавить" {
            creator target=@lgui->target input=@lgui->layer
              {{ onevent name="created" code=`args[0].manuallyInserted=true; console.log("created",args[0])` }};
    };
    
    find-objects pattern=@lgui->pattern pattern_root=@lgui->pattern_root
     | repeater {
        coco: collapsible2 text=(@.->input | get_param name="gui_title") 
          body_features=@lgui->each_body_features
          active=(@.->input | get_param name="active")
        {{
          connection event_name="user-changed-active" code=`
            env.host.params.input.setParam("active",args[0]);
          `;
        }}
        {
        	paint_kskv_gui input=@coco->input;
        };
     };

    
 
  };

};


/// косметика
register_feature name="plashka" {
  style="background: rgba(99, 116, 137, 0.36);padding: 5px;";
  body_features={ set_params style="overflow-y: auto; max-height: 90vh; padding:0.2em 0.2em 0.2em 0.4em; gap: 0.2em;" }
  //body_features={ set_params dom_style_overflowY="auto" dom_style_maxHeight="90vh"; }
  each_body_features={
    set_params style="border-left: 8px solid #00000042;
                      border-bottom: 1px solid #00000042;
                      border-radius: 0px;
                      margin-bottom: 5px;
                     ";
  };
};

// назначение: рисует набор слоев в форме набора плашек
// for - для кого рисуем. в этом "кто" будут сканироваться объекты для слоев и туда же будут создаваться новые
// input - список слоев
register_feature name="render-layers" {
  r: repeater {
      co: layers_gui2 
            text=(@co->input | get_param name="title")
            layer=(@co->input | get_param name="new") 
            pattern=(@co->input | get_param name="find") 
            pattern_root=@r->for
            target=@r->for
            plashka;
  };
};