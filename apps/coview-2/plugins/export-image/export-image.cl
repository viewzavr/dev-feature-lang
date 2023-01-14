find-objects-bf features="render_project_right_col" recursive=false 
    |
    insert_children { manage_export block_priority=10 };

////////////////////////////

// вход - project - визпроект
feature "manage_export" {
	vp: collapsible "Экспорт картинки"
      project=@..->project
      active_view_tab=@..->active_view_tab
      render_project=@..->render_project
    	{
        column ~plashka {
          button "Картинка" cmd=@ee->image class="important_button"

          cb: checkbox value=false text="Высокое разрешение";
          if (@cb->value) then={
            render-params @hr;
          };
        };

        ee: image-exporter input=(@vp->render_project | geta "screenshot_dom" default=null);
        hr: make-hi-res enabled=@cb->value;
      };  

};

load "./html2canvas.js";

// input - дом элемент с картинкою
feature "image-exporter" {
  q:  object

  {{
/*
     https://discourse.threejs.org/t/what-is-the-alternative-to-take-high-resolution-picture-rather-than-take-canvas-screenshot/3209/19
     https://discourse.threejs.org/t/rendering-only-portion-of-a-scene-stitching-it-back-together-for-real-high-resolution-exports/34861/4
        // html2canvas( dom_input, {width:4096,height:2048,windowWidth:4096,windowHeight:2048 } ).then( canvas => {
         // html2canvas( dom_input, {width:8192,height:4096,windowWidth:8192,windowHeight:4096 } ).then( canvas => { 
*/
    x-add-cmd2 "image" (m_lambda `(dom_input) => {
      /*
      html2canvas( dom_input ).then( canvas => {
         var img = canvas.toDataURL("image/png");
            var wnd = window.open( "about:blank", '_blank');
            wnd.document.write('<body style="margin:0px;"><img src="'+img+'"/></body>');
      });
      */

      html2canvas( dom_input ).then( canvas => {
         canvas.toBlob( blob => {
          saveBlob(blob,'coview.png')
          });            
      });


      function saveBlob(blob, fileName) {
        var a = document.createElement("a");
        document.body.appendChild(a);
        a.style = "display: none";

        var url = window.URL.createObjectURL(blob);
        a.href = url;
        a.download = fileName;
        a.click();
        window.URL.revokeObjectURL(url);
      };

      }` @q->input);
  }};

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
   dom_group

   {{ x-param-checkbox name="enabled" }}
   {{ x-param-float name="width" }}
   {{ x-param-float name="height" }}
   enabled=false
   width=4192
   height=4192

   {
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
   dom_group

   enabled=true
   {{ x-param-string name="width" }}
   {{ x-param-string name="height" }}
   {{ x-param-option name="rescan_children" option="visible" value=false }}
   width=4096
   height=''
   
   {
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