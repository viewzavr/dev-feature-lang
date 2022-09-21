register_feature name="clicked" {
   dom_event name="click";
};

register_feature name="doubleclicked" {
   dom_event name="dblclick";
};

register_feature name="pointermove" {
   dom_event name="pointermove";
};


////////////// хитмув
//
register_feature name="hitmove" {

   st: obj {

   dom_event name="pointerdown" {
      func st=@st code=`
        let tenv=env.params.st;
        tenv.setParam("dragging",true);
        tenv.setParam("drag_start_screen_x",args[0].screenX );
        tenv.setParam("drag_start_screen_y",args[0].screenY );
           let x = args[0].screenX;
           let y = args[0].screenY;
           let dx = x - tenv.params.drag_start_screen_x;
           let dy = y - tenv.params.drag_start_screen_y;
        tenv.host.dom.setPointerCapture( args[0].pointerId );
        tenv.emit("start",{x,y,dx,dy});
      `;
   };

   dom_event name="pointermove" {
      func st=@st code=`
        let tenv=env.params.st;
        if (tenv.params.dragging) {
           let x = args[0].screenX;
           let y = args[0].screenY;
           let dx = x - tenv.params.drag_start_screen_x;
           let dy = y - tenv.params.drag_start_screen_y;
           tenv.emit("moving",{x,y,dx,dy});
        }
      `;
   };

   dom_event name="pointerup" {
      func st=@st code=`
        let tenv=env.params.st;
        tenv.setParam("dragging",false);
           let x = args[0].screenX;
           let y = args[0].screenY;
           let dx = x - tenv.params.drag_start_screen_x;
           let dy = y - tenv.params.drag_start_screen_y;        
        tenv.emit("finish",{x,y,dx,dy});
      `;
   };

   };
};

/*
  rt: rect {{ 
    pointerdownmove onbegin 
     onmove={
        rt.setParam ... ? что тут?
     }
  }}
*/