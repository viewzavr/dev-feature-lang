// табличка соответсвий вьюшек и процессов

/////////////////// монтаж

find-objects-bf features="render_project_right_col" recursive=false 
|
insert_children { manage_visual_table; };

////////////////////////////

// вход - project - визпроект
feature "manage_visual_table" {
	vp: project=@..->project
    	button "Настройка соответствий" {
          view_settings_dialog project=@vp->project;
      };
};

// подфункция реакции на чекбокс view_settings_dialog
feature "toggle_visprocess_view_assoc" {
i-call-js 
  code="(cobj,val) => { // вот какого ежа тут js, где наш i-код?
    let obj = cobj.params.input;
    console.log({obj,cobj,val});
    obj.params.sources ||= [];
    if (val) {
      let curind = obj.params.sources.indexOf( env.params.src );
      if (curind < 0)
        obj.setParam( 'sources', obj.params.sources.concat([env.params.src]));
        // видимо придется как-то к кодам каким-то прибегнуть..
        // или к порядковым номерам, или к путям.. (массив objref тут так-то)
    }
    else
    {
      let curind = obj.params.sources.indexOf( env.params.src );
      if (curind >= 0) {
        //obj.params.sources.splice( curind,1 );
        //obj.signalParam( 'sources' );
        let nv = obj.params.sources.slice();
        nv.splice( curind,1 );
        obj.setParam( 'sources', nv);
      }
    };
  };";  
};

feature "view_settings_dialog" {
    d: dialog {
     dom style_1=(eval (@rend->project | get_param "views" | arr_length) 
           code="(len) => 'display: grid; grid-template-columns: repeat('+(1+len)+', 1fr);'") 
     {
        text "/";
        dom_group {
          repeater input=(@rend->project | get_param "views") 
          {
            rr: text (@rr->input | get_param "title"); 
          };
        };
        dom_group { // dom_group2
          repeater input= (@rend->project | get_param "processes") {
            q: dom_group {
              text (@q->input | get_param "title");
              repeater input=(@rend->project | get_param "views") 
              {
                i: checkbox value=(@i->input | get_param "sources" | arr_contains @q->input)
                  {{ x-on "user-changed" {toggle_visprocess_view_assoc src=@q->input;} }}
                ;
              };
            };
          }; // repeater2
        }; // dom_group2 
      }; // dom grid  

    }; // dlg
};
