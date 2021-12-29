load files=`
dom.js 
layout.js 
screen.js
style.js
dom-event.js
gui-elements.cl
`;

register_feature name="rotate_screens" {
	{
	find_screens:  find-objects pattern="** screen";
	add_cmd name="apply" screens=@find_screens->output code=`
	  
	  var cur = vzPlayer.getParam("active_screen");
	  var idx = env.params.screens.indexOf(cur);
	  idx = idx + 1 % (env.params.screens.length);
	  vzPlayer.setParam("active_screen", env.params.screens[idx]);
`;
    }
}