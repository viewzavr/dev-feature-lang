load files=`
dom.js 
layout.js 
screen.js
style.js
dom-event.js
gui-elements.cl
gui-events.cl
dialog/dialog.js
`;

register_feature name="two_side_columns" {
  row justify-content="space-between"
      align-items="flex-start"
      style="width: 100%" class="vz-mouse-transparent-layout";
  // вот я тут опираюсь на хрень vz-mouse-transparent-layout которая определена непойми где...
  // непроговоренные ожидания.. хоть бы module-specifier указал бы как-то..
};

register_feature name="rotate_screens" {
  func screens=(find-objects pattern="** screen") code=`
	  var cur = vzPlayer.getParam("active_screen");
	  var idx = env.params.screens.indexOf(cur);
	  idx = (idx + 1) % (env.params.screens.length);
	  vzPlayer.setParam("active_screen", env.params.screens[idx],true);
    `;
};


    /*
    { 
	  find_screens:  find-objects pattern="** screen";
    };
    */