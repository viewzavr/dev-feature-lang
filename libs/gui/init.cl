load files=`
dom.js 
layout.js 
screen.js
style.js
dom-event.js
gui-elements.cl
gui-events.cl
gui-events-hitmove.cl
`;

register_feature name="rotate_screens" {
  func screens=(find-objects pattern="** screen") code=`
	  var cur = vzPlayer.getParam("active_screen");
	  var idx = env.params.screens.indexOf(cur);
	  idx = idx + 1 % (env.params.screens.length);
	  vzPlayer.setParam("active_screen", env.params.screens[idx],true);
    `;
};


    /*
    { 
	  find_screens:  find-objects pattern="** screen";
    };
    */