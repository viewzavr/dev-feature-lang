// "Универсальный" вид аля Паравью

find-objects-bf features="the_view_types" recursive=false 
|
insert_children {
  value="the_view_recursive" title="Общий экран (рекурсивный)"; 
};

/*
feature "walk_objects" {
  k: output=(m_eval "(root_obj,subitms_param) => {
      function walk()
    }" @k->0 @k->1);
}
*/

// 0 корневой объект 1 имя параметра с "детьми" depth глубина
feature "walk_objects" {
   k: 
     output=(concat @my_result->output @my_items_result->output)
     depth=0
     {
      my_result: m_eval 
         "(obj,title,depth) => 
         { return {id:obj.$vz_unique_id,
                   title:'-'.repeat(depth)+title,
                   obj: obj} }" 
         @k->0 (@k->0 | geta "title") @k->depth;
      my_items: data (@k->0 | geta @k->1 default=[]);
      
      my_items_result:
        @my_items->output | repeater {
          w: walk_objects @w->input @k->1 depth=(@k->depth + 1);
        } 
        | map_geta "output" default=null | geta "flat" | arr_compact;
     }
};

feature "the_view_recursive"
{
  tv: the-view 
    show_view={
      show_visual_tab_recursive input=@tv;
    }
    gui={ 
      render-params @tv;

      cb: combobox values=(@tv->list_of_areas | map_geta "id") 
                   titles=(@tv->list_of_areas | map_geta "title")
                   index=0 dom_size=5
      ;

      selected_object: data (@tv->list_of_areas | geta @cb->index default=null | geta "obj");

      //render-params @curobj;

     co: column plashka style_r="position:relative; overflow: auto;"  
      {
        column {
          //text "Параметры";
          //text ()
          insert_children input=@.. list=(@selected_object->output | geta "gui" default=null);
        };

        button "x" style="position:absolute; top:0px; right:0px;" 
        {
          lambda @selected_object->output code=`(obj) => { obj.removedManually = true; obj.remove(); }`;
        };

     };

    }
    //primary_container=(find-objects-bf features="recursive_area" recursive=false root=@tv {{ console_log_params "PCO"}})
    primary_container=(@tv | get_children_arr | arr_filter_by_features features="recursive_area" | geta 0 default=null)
    list_of_areas=(walk_objects @tv->primary_container "subitems")
    {{ insert_children input=@tv manual=true active=(is_default @tv) list={
         area_3d;
      };
    }}
   ;
};

// по сути то экран..
feature "recursive_area" 
{
  it:  
       title="Область"
       project=@..->project
       view=@..
       visible=true
       {{ x-param-string name="title" }}
       {{ x-param-checkbox name="visible" }}
       {{ x-param-slider name="weight" min=0.1 max=5 step=0.1; }}
       weight=1
       ;
};

feature "area_container" {
  it: recursive_area
        subitems=(@it | get_children_arr | arr_filter_by_features features="recursive_area")
        {{
           //x-param-slider name="ratio";
        }}
        gui={
          render-params @it;
          button_add_object "Добавить область" add_to=@it add_type="area_content";  
        }
        ;
};

feature "area_container_horiz" {
   it: area_container title="Горизонтальный"
   show={
      show_area_container_horiz input=@it;
   }
};

feature "area_container_vert" {
   it: area_container title="Вертикальный"
   show={
      show_area_container_vert input=@it;
   }
};

feature "area_content" {
  it:  recursive_area 
       title="Пустой"
       sibling_types=["area_content","area_3d"] 
       sibling_titles=["Пустой","3d"]

       subitems=[]
       sources_str=""
       sources=(find-objects-by-pathes input=@it->sources_str root=@it->project)

       // это нам надо чтобы - посылать визпроцессам сигналы какие вьюшки их смотрят
       // а это надо чтобы те могли камеру получить
       {{ @it->sources | get-cell "view-attached" | set-cell-value @it }}

       visible_sources = (@it->sources | filter_geta "visible")
       show={
          show_area_empty input=@it;
       }
       gui={
           //text 333;
        
           object_change_type text="Укажите тип:"
              input=@it
              types=@it->sibling_types
              titles=@it->sibling_titles;

           param_field name="Разделить" {
             button "Горизонтально" cmd=@it->split-horiz;
             button "Вертикально" cmd=@it->split-vert;
           };
        
       }

       {{ x-param-option name="sources_str" option="manual" value=true }}

       {{ x-add-cmd2 "split-horiz" (split-screen @it 'area_container_horiz') }}
       {{ x-add-cmd2 "split-vert" (split-screen @it 'area_container_vert') }}

};

feature "split-screen" {
  k: output=(m_lambda "(obj,newtype) => {
       //let v='area_container_horiz';
       let v=newtype;
       let origparent = obj.ns.parent;
       let pos = origparent.ns.getChildren().indexOf( obj );
       let newcontainer = obj.vz.createObj();
       
       origparent.ns.appendChild( newcontainer,'container',true,pos );
       //let newcontainer = obj.vz.createObj({parent: origparent});

       Promise.allSettled( newcontainer.manual_feature( v ) ).then( () => {
           newcontainer.manuallyInserted=true;    
           newcontainer.ns.appendChild( obj,'area' ); // переезд в новый контейнер
           let newcontent = obj.vz.createObj({parent: newcontainer}); 

           Promise.allSettled( newcontent.manual_feature( 'area_content' ) ).then( () => {
              
              newcontent.manuallyInserted=true;    
           });
       });
    }" @k->0 @k->1);
};

feature "area_3d" {  
  it: area_content title="3d"
      show_stats=false
      {{ x-param-checkbox name="show_stats" title="Показать FPS"}}
  show={
      show_area_3d input=@it;
  }
  {{ x-param-objref-3 name="camera" values=(@it->project | geta "cameras"); }}

       gui={
            param_field name="Разделить" {
              button "Горизонтально" cmd=@it->split-horiz;
              button "Вертикально" cmd=@it->split-vert;
            };

            render-params-list object=@it list=["visible","camera"];

            text "Включить процессы:";

            column {

              @it->project | geta "processes" | repeater //target_parent=@qoco 
              {
                 i: checkbox text=(@i->input | geta "title") 
                       value=(@it | geta "sources" | arr_contains @i->input)
                    {{ x-on "user-changed" {
                        toggle_visprocess_view_assoc2 process=@i->input view=@it;
                    } }};
              };

            };

            render-params-list object=@it list=["title","weight","show_stats"];
       }
       {
         //def_camera;
       }

       ;

};

///////////////////////// 
///////////////////////// показывалки
///////////////////////// 

feature "show_areas" {
  q: {
    insert_children input=@q->target list=(@q->input | map_geta "show" default=null | arr_flat | arr_compact) 
  };
};

feature "show_area_base" {
  k: style=(m_eval "(r) => `flex: ${r} 1 0; position: relative;`" (@k->input | geta "weight"))
     visible=(@k->input | geta "visible")
  ;

  // ыдея
  //k: style=(subst "flex: ${@k->ratio} 1 0; position: relative;")
};

feature "show_area_container_horiz" {
  area_rect: row show_area_base
  {
     show_areas target=@area_rect input=(@area_rect->input | get_children_arr);
     //insert_children input=@area_rect list=(@area_rect->input | get_children_arr | map_geta "show")
  };
};

feature "show_area_container_vert" {
  area_rect: column show_area_base
  {
     show_areas target=@area_rect input=(@area_rect->input | get_children_arr);
     //insert_children input=@area_rect list=(@area_rect->input | get_children_arr | map_geta "show")
  };
};

feature "show_area_3d" {
  area_rect: dom style_k="border: 1px solid grey;" show_area_base
  {
    process_rect: show_3d_scene
        scene3d=(@area_rect->input | geta "visible_sources" | map_geta "scene3d" default=[])
        camera=(@area_rect->input | geta "camera")
        style="width:100%; height:99%;"
        {{ @area_rect->input | geta "sources" | get-cell "show-view-attached" | set-cell-value @process_rect }}
    ;

    extra_screen_things: 
        column style="padding-left:0em; position:absolute; bottom: 1em; left: 1em;" 
        class='vz-mouse-transparent-layout extra-screen-thing'
        {
             dg: dom_group input=(@area_rect->input | geta "visible_sources" | map_geta "scene2d" default=[])
             {
               if (@area_rect->input | geta "show_stats" default=false) then={
                 show_render_stats renderer=@process_rect->renderer;
               }; 
             }
        };

 }; // area-rect
};

feature "show_area_empty" {
  area_rect: dom style="flex: 1 1 0; position: relative;"
  {
           object_change_type text="Укажите тип:"
              input=@area_rect->input
              types=(@area_rect->input | geta "sibling_types")
              titles=(@area_rect->input | geta "sibling_titles");
  }; // area-rect
};

feature "show_visual_tab_recursive" {
   svr: dom_group
      screenshot_dom = @rrviews->dom
   {

    actions_co: column visible=(@svr->input | geta "actions" default=null) 
    ;
    insert_children input=@actions_co list=(@svr->input | geta "actions" default=null);

    show_sources_params input=(@svr->input | geta "sources");

    rrviews: 
      row style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2;
        justify-content: center;" class="view56_visual_tab"
    {
      show_areas input=(list (@svr->input | geta "primary_container")) target=@rrviews;

    }; // global row rrviews

   }; // domgroup

}; // show vis tab

