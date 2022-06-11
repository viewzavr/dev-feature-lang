
find-objects-bf features="render_project_right_col" recursive=false 
|
insert_children { manage_export; };

////////////////////////////

// вход - project - визпроект
feature "manage_export" {
	vp: project=@..->project
      active_view_tab=@..->active_view_tab
    	collapsible "Экспорт" {
        column plashka {
          button "Картинка" cmd=@ee->image;

          cb: checkbox value=false text="Высокое разрешение";
          if (@cb->value) then={
            render-params @hr;
          };
        };

        ee: image-exporter input=(@vp->active_view_tab | geta "screenshot_dom");
        hr: make-hi-res enabled=@cb->value;
      };  

};

load "./animation/html2canvas.js";

// input - дом элемент с картинкою
feature "image-exporter" {
  q: 

  {{
/*
     https://discourse.threejs.org/t/what-is-the-alternative-to-take-high-resolution-picture-rather-than-take-canvas-screenshot/3209/19
     https://discourse.threejs.org/t/rendering-only-portion-of-a-scene-stitching-it-back-together-for-real-high-resolution-exports/34861/4
        // html2canvas( dom_input, {width:4096,height:2048,windowWidth:4096,windowHeight:2048 } ).then( canvas => {
         // html2canvas( dom_input, {width:8192,height:4096,windowWidth:8192,windowHeight:4096 } ).then( canvas => { 
*/
    x-add-cmd2 "image" (m_lambda `(dom_input) => {
      html2canvas( dom_input ).then( canvas => {
         var img = canvas.toDataURL("image/png");
            var wnd = window.open( "about:blank", '_blank');
            wnd.document.write('<body style="margin:0px;"><img src="'+img+'"/></body>');
      });
      }` @q->input);
  }};

};

feature "css-style" {
  dom tag="style" dom_obj_type="text/css" dom_obj_textContent=@.->0;
};

feature "hi-res-style" {
  css-style "body { overflow: auto; }
    .view56_visual_tab {
       width: 4096px !important;
       height: 2048px !important;
    }
  ";
};

/*
feature "make-hi-res" {
 k: 
   {{ x-param-checkbox name="enabled" }}
   {{ x-param-float name="width" }}
   {{ x-param-float name="height" }}
   enabled=false
   width=4192
   height=4192

   dom_group {
    if (@k->enabled) then={
      css-style "body { overflow: auto; }
        .view56_visual_tab {
           width: 4096px !important;
           height: 2048px !important;
        }
      ";    
    };
   };
};
*/

feature "make-hi-res" {
 k: 
   enabled=true
   {{ x-param-string name="width" }}
   {{ x-param-string name="height" }}
   {{ x-param-option name="rescan_children" option="visible" value=false }}
   width=4096
   height=''
   dom_group {
    if (@k->enabled) then={
       css-style (m_eval "(w,h) => {
         w = parseFloat(w);
         if (h == '') h = w * window.innerHeight / window.innerWidth; else h = parseFloat(h);
         return `
             body { overflow: auto; }
            .view56_visual_tab {
               width: ${w}px !important;
               height: ${h}px !important;
            }`}" @k->width @k->height)
          ;
    };
   };
};