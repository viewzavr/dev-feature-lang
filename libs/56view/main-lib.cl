// действие - вставляет в указанный объект детей но только в случае если этот объект не настроен из дампа
// так-то можно сделать просто вычисление active для insert_children и не выделываться

// input - куды
// list - чиво
feature "insert_default_children" code=`

  //console.log("insert_default_children welcome screen",env.getPath())

  env.onvalues(["input","list"],(input,list) => {
     // также надо для целевого контейнера ставить force_dump=true
     input.setParam( "force_dump", true ); // это на будущее, шоб он уж точно попадал в дамп
     // а без этого его могут пропустить из дампирования и мы будем думать что там ничего нет
     // а там может быть есть - просто пользователь все решил вычистить (так бывает как выяснилось)

     vzPlayer.getRoot().onvalue("dump_loaded",(dl) => {
        //console.log("see input and list, and dump-loaded is true",input.params.manual_restore_performed)
        if (input.params.manual_restore_performed) {
           //console.log("not doing job - there is data from dump")
        }
        else perform( input, list );
     });
  });

  function perform( input, list ) {
      //console.log("doing job",list,env.getPath());
        for (let edump of list) {
          edump.manual = true;
          edump.params.manual_features = Object.keys( edump.features ).filter( (f) => f != "base_url_tracing");
          //console.log("next child",edump,env.getPath());
          var p = env.vz.createSyncFromDump( edump,null,input,edump.$name,true );
          p.then( (child_env) => {
             child_env.manuallyInserted = true;
             //console.log("created child. dump is",child_env.dump(),env.getPath());
             //console.log("emitting local dump-loaded");
             //vzPlayer.getRoot().emit("dump-loaded");
          });
          
       };    
  }

`;

// это вычисление поля active для обычного insert_children
// также надо для целевого контейнера ставить force_dump=true
feature "is_default" code=`
  env.feature( "param_alias");
  env.addParamAlias( "input", 0 );
  env.onvalues(["input"],(input) => {
     vzPlayer.getRoot().onvalue("dump_loaded",(dl) => {
        //console.log("see input and list, and dump-loaded is true",input.params.manual_restore_performed)
        if (input.params.manual_restore_performed) {
           //console.log("not doing job - there is data from dump")
        }
        else env.setParam("output",true);
     });
  });

`;

/*
recv @/ "dump-loaded" -> send @insert_children active=true
||
recv @.. "restoring" -> stop;
*/

/*
feature "user_template" {
  q: {
    x-modify input=@/ {
      x-on "dump-loaded" {
        i-call-js ""
        i-insert-children
      }
    }
    insert_children input=@q->input list=@q->list active=false manual=true;
  };
}
*/

// вход - scene3d, camera, scene2d (надписи)
// можно переделать будет на раздельное питание
feature "show_3d_scene" {
  scene_3d_view: 
    view3d style="width:100%; height:100%;" {
    
    // если вытащить его в хвост фичи (замкнуть view3d) то оно перестает видеть scene_3d_View почему-то
    r1: render3d
          bgcolor=[0.1,0.2,0.3]
          target=@scene_3d_view
          input=@scene_3d_view->scene3d // кстати идея так-то сделать аналог и для 2д - до-бирать детей отсель
          camera=@scene_3d_view->camera
          //{{ console_log_params "UUU" }}
      {
          //camera3d pos=[-400,350,350] center=[0,0,0];

          orbit_control;
      };
   };      
   
};

// рисует боковушку - параметры визпроцессов...
// input - список процессов
feature "show_sources_params"
{
  sv: row {
    svlist: column {
      repeater input=@sv->input {
        mm: 
         row {
        //dom tag="fieldset" style="border-radius: 5px; padding: 2px; margin: 2px;" {
          collapsible text=(@mm->input | get_param "title" default="no title") 
            style="min-width:250px;" padding="2px"
            style_h = "max-height:80vh;"
            body_features={ set_params style_h="max-height: inherit; overflow-y: auto;"}          
            expanded=(@mm->input_index == 0)
          {
             insert_children input=@.. list=(@mm->input | get_param "gui");
             // вот мы вставили гуи
          };

          cbv: checkbox value=(@mm->input | geta "visible");
          x-modify input=@mm->input {
            x-set-params visible=@cbv->value? __manual=true;
            x-on "show-settings" {
              lambda @extra_settings_panel code="(panel,obj,settings) => {
                 //console.log('got x-on show-settings',obj,settings)
                 // todo это поведение панели уже..
                 // да и вообще надо замаршрузизировать да и все будет.. в панель прям
                 // а там типа событие или тоже команда
                 if (panel.params.list == settings)
                   panel.setParam('list',[]);
                 else  
                   panel.setParam('list',settings);
                 
              };
              ";
            };
          };
        }; // fieldset
      }; // repeater

      //@repa->output | render-guis;
      //render-params @rrviews;

    }; // svlist  


    extra_settings_panel_outer: row gap="2px" {
      extra_settings_panel: 
      column // style="position:absolute; top: 1em; right: 1em;" 
      {
         insert_children input=@.. list=@extra_settings_panel->list?;
      };
      button "&lt;" style_h="height:1.5em;" visible=(eval @extra_settings_panel->list? code="(list) => list && list.length>0") 
      {
         setter target="@extra_settings_panel->list" value=[];
      };
    }; // extra_settings_panel_outer

    }; // row    
};

// подфункция реакции на чекбокс view_settings_dialog
// идея вынести это в метод вьюшки. типа вкл-выкл процесс.
feature "toggle_visprocess_view_assoc2" {
i-call-js 
  code="(cobj,val) => { // cobj объект чекбокса, val значение
    let view = env.params.view; // вид the_view
    //let view = cobj.params.view;
    console.log({view,cobj,val});
    view.params.sources ||= [];
    view.params.sources_str ||= '';
    if (val) { // надо включить
      let curind = view.params.sources.indexOf( env.params.process );
      if (curind < 0) {
        let add = '@' + env.params.process.getPathRelative( view.params.project );
        console.log('adding',add);
        let filtered = view.params.sources_str.split(',').filter( (v) => v.length>0)
        let nv = filtered.concat([add]).join(',');
        console.log('nv',nv)
        
        view.setParam( 'sources_str', nv, true);
      }
        // видимо придется как-то к кодам каким-то прибегнуть..
        // или к порядковым номерам, или к путям.. (массив objref тут так-то)
    }
    else
    {
        // надо выключить
      let curind = view.params.sources.indexOf( env.params.process );
      //debugger;
      if (curind >= 0) {
        //obj.params.sources.splice( curind,1 );
        //obj.signalParam( 'sources' );
        let arr = view.params.sources_str.split(',').map( x => x.trim());
        arr = [...new Set(arr)]; // унекальнозть
        let p = '@' + env.params.process.getPathRelative( view.params.project );
        let curind_in_str = arr.indexOf(p);
        if (curind_in_str >= 0) {
          arr.splice( curind_in_str,1 );
          view.setParam( 'sources_str', arr.join(','), true)
        };
      }
    };
  };";
};