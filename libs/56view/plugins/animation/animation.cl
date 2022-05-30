// анимация по параметру
// todo = модальность. с ней было лучше.

find-objects-bf features="render_project_right_col" recursive=false 
|
insert_children { manage_animation; };

////////////////////////////

// вход - project - визпроект
feature "manage_animation" {
	vp: project=@..->project
      active_view_tab=@..->active_view_tab
    	collapsible "Анимация" {
        animations_panel objects=(@vp->project | geta "processes") active_view_tab=@vp->active_view_tab;
     	};
};

load "./animation-player.js";
feature "animations_panel" {
   apan: column plashka 
   {{ x-param-checkbox name="record" }}
   {
     render-params @ap;
     render-params @mv;

     mv: movie_recorder input=(@apan->active_view_tab | geta "screenshot_dom");
     ap: animation-player {{ x-on "tick" cmd=@mv->grab-screen {{ console_log_params }} }};
   };
};

load "./html2canvas.js";

// input - дом элемент
feature "movie_recorder" {
  q:
  {{ 
  x-add-cmd name="open-window" code=(i-call-js @q code=`(env) => {
    let recorderWindow = window.open( "about:blank","_blank", "width=1200, height=700" );
    recorderWindow.opener = null;
    recorderWindow.document.location = "https://pavelvasev.github.io/simple_movie_maker/";

    env.setParam("wnd",recorderWindow);
  }`);

  x-add-cmd name="grab-screen" code=(i-call-js @q @q->input code=`(env, dom_input) => {
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
    // http://html2canvas.hertzen.com/

    html2canvas( dom_input ).then( canvas => {
       var img = canvas.toDataURL("image/png"); 
       console.image(img,10);
        let recorderWindow = env.getParam("wnd");
        let subcounter = 0;
        if (recorderWindow)
            recorderWindow.postMessage( {cmd:"append",args:[img],ack:subcounter},"*");
    })

    /*

    //console.log( dom_input )
    //var img = dom_input.toDataURL("image/png");

    console.image(img,10);
    let recorderWindow = env.getParam("wnd");
    let subcounter = 0;
    if (recorderWindow)
        recorderWindow.postMessage( {cmd:"append",args:[img],ack:subcounter},"*");
    */
  }`);

  }}
  ;
};