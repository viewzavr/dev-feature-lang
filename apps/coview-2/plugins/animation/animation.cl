// анимация по параметру
// todo = модальность. с ней было лучше.

// ffmpeg -i animated.gif -movflags faststart -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" video.mp4

find-objects-bf features="render_project_right_col" recursive=false 
|
insert_children { manage_animation block_priority=20 };

////////////////////////////

// вход - project - визпроект
feature "manage_animation" {
	vp: collapsible "Анимация"
      project=@..->project
      active_view_tab=@..->active_view_tab
      render_project=@..->render_project
    	{
        animations_panel 
                         active_view_tab=@vp->active_view_tab
                         project=@vp->project
                         render_project=@vp->render_project
                         ;
     	};
};

load "./animation-player.js";
feature "animations_panel" {
   apan: column ~plashka 
         
   {{ x-param-checkbox name="record" }}
   {
     render-params @ap;

     ap: animation-player 
            parameter=(@apan->project | geta "default_animation_parameter")
            //search_root="/"
            //search_root=@apan->project
            //step_allowed=(( (@/->loading_files or [] ) | geta "length") == 0)
            //afiles=@/->loading_files
            ;

     cb: checkbox text="Запись мультика" value=false;

     if (@cb->value) then={
       // вроде как не надо? но очищать как очередь..
       // render-params @mv;
       // console-log "expanded";

       mv: movie_recorder input=@apan.render_project.screenshot_dom;

       read @ap | x-modify { 
         x-on "tick" {
           if (@ap->cycle == 0) then={
              call target=@mv name="make-screen-shot";
              //@mv | get-cmd-cell "open-window" | set-cell-value 1;
           };
         };
         x-on "first-cycle-finish" {
           call target=@mv name="generate-video-file";
         };
       };

       /*
       @mv | get-cell "open-window" | pause_input | invoke 1 2 3;
       @mv | get-cell "invoke" | emit "open-window";
       @mv | get-cell "open-window" | set-cell-value;
       @mv | get-cell "cmd:open-window" | set-cell-value;
       */

       read @mv | get-cmd-cell "open-window" | set-cell-value 1 | get-cell-value | console-log "reply is";

       // call target=@mv name="open-window" auto_apply delay_execution timeout=10;
       // call target=@mv name="open-window" auto_apply;
       // call_cmd target=@mv name="open-window" auto_apply;
     };
   };
};

load "../export-image/html2canvas.js";

// input - дом элемент
// todo - выводить текущий скриншот в маленькое окошечко
// тут подойдет идея на тему произвольных параметров..
feature "movie_recorder"
{
  q: object
  {{
  x-add-cmd name="open-window" code=(m-js q=@q `() => {
    //console.log('open window called');
    let q = env.params.q;
    let erecorderWindow = q.getParam("wnd");
    if (erecorderWindow) {
       if (erecorderWindow.closed) 
       {
         console.log("for some reason window is closed... but we still have handle to it");
         //debugger;
       }
       else {
         erecorderWindow.focus();
         console.log("already opened recorder window");
         return;
       }
    }

    let recorderWindow = window.open( "about:blank","_blank", "width=1200, height=700" );
    if (!recorderWindow) {
      console.error("Не смогла открыть окно записи мультика, браузер не дает")
      return;
    }
    recorderWindow.opener = null;
    recorderWindow.document.location = "https://pavelvasev.github.io/simple_movie_maker/";

    q.setParam("wnd",recorderWindow);

    window.addEventListener("message", receiveMessageAck, false);

    // не шибко то это работает на кросс-орижин
    recorderWindow.addEventListener("beforeunload", onClose, false);

    q.on("remove",unsub);

    function unsub() {
      window.removeEventListener( "message", receiveMessageAck );
      //recorderWindow.removeEventListener( "beforeunload", onClose );
    }

    function onClose() {
      console.log("close handler")
      q.setParam("wnd",null);
      unsub();
    }
      
    function receiveMessageAck(event) {
        var ack = event.data.ack;
        var cmd = event.data.cmd;
        if (event.source === recorderWindow && event.data.cmd == "append") //  && ack == ackSent
          q.setParam("waiting",false);
    }

    return "window is opened";
  }` @q);

  x-add-cmd name="make-screen-shot" code=(i-call-js @q @q->input code=`(env, dom_input) => {
    console.image = function(url, size = 100) {
      var image = new Image();
      image.onload = function() {
        var style = [
          'font-size: 1px;',
          'padding: ' + this.height/100*size + 'px ' + this.width/100*size + 'px;',
          'background: url('+ url +') no-repeat;',
          'background-size: contain;'
         ].join(' ');
         console.log('%c ', style);
      };
      image.src = url;
    };
    // см также https://github.com/adriancooney/console.image

    // http://html2canvas.hertzen.com/
    // примечание: оч медленная библиотека, либо мы ее криво используем (там есть возможность не переосздавать канвас рендеринга..)

    // опция {windowWidth:4000, windowHeight: 3000}
    //console.log( dom_input );
    //debugger
    // несовместима с justify-content и как следствие не выводит текущее окно в окне
    
    html2canvas( dom_input ).then( canvas => {
       var img = canvas.toDataURL("image/png");
       //console.image(img,10);
        let recorderWindow = env.getParam("wnd");
        let subcounter = 0;
        if (recorderWindow) {
            env.setParam("waiting",true);
            recorderWindow.postMessage( {cmd:"append",args:[img],ack:subcounter},"*");
        }
    })
    

/*
    console.log( dom_input )
    var img = dom_input.toDataURL("image/png");

    console.image(img,10);
    let recorderWindow = env.getParam("wnd");
    let subcounter = 0;
    if (recorderWindow)
        recorderWindow.postMessage( {cmd:"append",args:[img],ack:subcounter},"*");
    */
  }`);

  x-add-cmd name="generate-video-file" code=(i-call-js @q @q->input code=`(env, dom_input) => {
        let recorderWindow = env.getParam("wnd");
        if (recorderWindow) {
          recorderWindow.focus();
          recorderWindow.postMessage({cmd:"finish"},"*");
        }
  }`);   

  x-add-cmd name="clear" code=(i-call-js @q @q->input code=`(env, dom_input) => {
        let recorderWindow = env.getParam("wnd");
        if (recorderWindow)
          recorderWindow.postMessage({cmd:"reset"},"*");
  }`);  

  }}
  ;
};