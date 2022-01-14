register_feature name="clicked" {
   dom_event name="click";
};

register_feature name="doubleclicked" {
   dom_event name="dblclick";
};

register_feature name="pointermove" {
   dom_event name="pointermove";
};

/*
register_feature name="pointerdown" {
   dom_event name="pointerdown" {
      func code=`
        // вот тут хотелось бы завести прямо какое-то место в целевом env под наши цели...
        let tenv=env.ns.parent.host;
        tenv.setParam("dragging",true);
        tenv.setParam("drag_start_screen_x",args[0].screenX );
        tenv.setParam("drag_start_screen_y",args[0].screenY );
        tenv.dom.setPointerCapture( args[0].pointerId );
      `;
   };
};

register_feature name="pointerdownmove" {
   dom_event name="pointerdown";
};
*/