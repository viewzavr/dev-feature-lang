
// input - куды
// list - чиво
feature "insert_default_children" code=`

  console.log("insert_default_children welcome screen",env.getPath())

  let manual_restore = false;

  env.onvalue("input",(inp) => {
    console.log("input detected, waiting it's manual-restore event",env.getPath(),"input=",inp.getPath())
    inp.once("manual-restore",() => {
      console.log("input manual-restore event detected",env.getPath())
      manual_restore = true;
      // это летит когда объект вызывают restore from dump типа из конфига...
    })
  });

  let performed = false;

  vzPlayer.getRoot().once("dump-loaded",() => {
    console.log("i see window dump loaded event",env.getPath());
    if (manual_restore) {
      // ниче не делаем
      console.log("i see manual restore performed, doing nothing",env.getPath());
    }
    else {
      // ну таки да - надо действовать
      console.log("i see manual restore not performed, waiting for input and list",env.params.list,env.params.input, env.getPath(), env);
      env.onvalues( ["input","list"], (input,list) => {
        console.log("doing job",list,env.getPath());
        for (let edump of list) {
          edump.manual = true;
          edump.params.manual_features = Object.keys( edump.features ).filter( (f) => f != "base_url_tracing");
          console.log("next child",edump,env.getPath());
          var p = env.vz.createSyncFromDump( edump,null,input,edump.$name,true );
          p.then( (child_env) => {
             child_env.manuallyInserted = true;
             console.log("created child. dump is",child_env.dump(),env.getPath());
             console.log("emitting local dump-loaded");
             vzPlayer.getRoot().emit("dump-loaded");
          });
          
       };
       });      
        //let edump = { children: env.params.list || [], manual: true }
        //console.log("i see manual restore not performed, doing job",edump);
        //env.vz.createSyncFromDump( edump,env.params.input,null,null,true );
    }
  })

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
    view3d style="width:100px;";
    {
      r1: render3d 
          bgcolor=[0.1,0.2,0.3]
          target=@scene_3d_view //{{ skip_deleted_children }}
          input=@scene_3d_view->scene3d // кстати идея так-то сделать аналог и для 2д - до-бирать детей отсель
          camera=@scene_3d_view->camera
      {
          //camera3d pos=[-400,350,350] center=[0,0,0];

          orbit_control;
      };

      extra_screen_things: 
      column style="padding-left:2em; min-width: 80vw; 
         position:absolute; bottom: 1em; left: 1em;" {
         dom_group 
           input=(@scene_3d_view->scene2d);
      };

    };
};

// рисует боковушку - параметры визпроцессов...
feature "show_sources_params"
{
  sv: row {
    svlist: column {
      repeater input=(@sv->input | geta "sources") {
        mm: 
         row {
        //dom tag="fieldset" style="border-radius: 5px; padding: 2px; margin: 2px;" {
          collapsible text=(@mm->input | get_param "title" default="no title") 
            style="min-width:250px;" padding="2px"
            style_h = "max-height:80vh;"
            body_features={ set_params style_h="max-height: inherit; overflow-y: auto;"}          
          {
             insert_children input=@.. list=(@mm->input | get_param "gui");
             // вот мы вставили гуи
          };

          cbv: checkbox value=(@mm->input | get_param "visible");
          x-modify input=@mm->input {
            x-set-params visible=@cbv->value ;
            x-on "show-settings" {
              lambda @extra_settings_panel code="(panel,obj,settings) => {
                 // console.log('got x-on show-settings',obj,settings)
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
         insert_children input=@.. list=@extra_settings_panel->list;
      };
      button "&lt;" style_h="height:1.5em;" visible=(eval @extra_settings_panel->list code="(list) => list && list.length>0") 
      {
         setter target="@extra_settings_panel->list" value=[];
      };
    }; // extra_settings_panel_outer

    }; // row    
};