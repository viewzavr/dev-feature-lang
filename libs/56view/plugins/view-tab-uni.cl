// "Универсальный" ряд

find-objects-bf features="the_view_types" recursive=false 
|
insert_children { value="the_view_uni" title="Слева на право (uni)"; };

feature "the_view_uni"
{
  tv: the-view 
    show_view={ show_visual_tab_uni input=@tv; }
    scene3d=(@tv->visible_sources | map_geta "scene3d" | arr_compact)
    scene2d=(@tv->visible_sources | map_geta "scene2d")

    gui={ 

        render-params @tv; 

/*
        button "Настроить области" {
            areas_settings_dialog 
              project=@tv->project 
              areas=@tv->areas
              cameras=@tv->cameras;
        };
        */


        render_layers_inner 
         title="Области" 
         root=@tv
         items=[ {"title":"Области", "find":"area","add":"area","add_to":"@areas_block->."}, 
                 {"title":"Камеры", "find":"camera3dt","add":"camera3dt","add_to":"@cameras_block->."}
               ];
      }
      areas=(find-objects-bf features="area" root=@areas_block)
      cameras=(find-objects-bf features="camera3d" root=@cameras_block)
      cameras_ptr=@cameras //(@cameras | get_children_arr)
      areas_ptr=@areas
    {
      //cam: camera3d pos=[-400,350,350] center=[0,0,0];
      //cams: @tv->visible_sources | repeater { camera3d pos=[-400,350,350] center=[0,0,0] };
      cameras_block: {
        camera3dt title="камера 1";
        camera3dt title="камера 2";
        camera3dt title="камера 3";
        camera3dt title="камера 4";
        camera3dt title="камера 5";
        camera3dt title="камера 6";
      };
      areas_block: project=@tv->project view=@tv{
        area title="область 1";
        area title="область 2";
        area title="область 3";
        area title="область 4";
      };
    };
};

feature "camera3dt" {
  ccc: camera3d title="Камера" sibling_titles=["Камера"] sibling_types=["camera3dt"]
    gui={ render-params @ccc }
  ;
};

feature "area" 
{
  it: sibling_types=["area"] 
       sibling_titles=["Область"]
       title="Область"
       project=@..->project
       view=@..->view
       sources=(find-objects-by-pathes input=@it->sources_str root=@it->project)
       visible_sources = (@it->sources | filter_geta "visible")

       {{ x-param-option name="sources_str" option="manual" value=true }}

       {{ x-param-objref-2 name="camera" values=(@it->view | geta "cameras")}}
       {{ console_log_params "AAREA"}}
       //camera=(find-one-object input=@it->camera_path)
       gui={
            qq: it=@it;
            text "Включить:";

            column {

              @it->project | geta "processes" | repeater //target_parent=@qoco 
              {
                 i: checkbox text=(@i->input | geta "title") 
                       value=(@qq->it | geta "sources" | arr_contains @i->input)
                    {{ x-on "user-changed" {
                        toggle_visprocess_view_assoc2 process=@i->input view=@qq->it;
                    } }};
              };

            };

            render-params-list object=@it list=["camera"];

/*
            combobox values=(@it->view | geta "cameras" | map_geta (m_apply "(cam) => cam.getPath()"))
                     titles=(@it->view | geta "cameras" | map_geta "title")
                     value=@it->camera_path?
                     {{ x-on "user_changed_value" 
                          code=(m_apply "(area,b,c,val) => {
                            area.setParam('camera_path',val,true);
                            }" @it)
                     }}
                     ;
*/                     

       }

       ;

};

feature "show_visual_tab_uni" {
   svr: dom_group
      screenshot_dom = @rrviews->dom
   {

    show_sources_params input=(@svr->input | geta "sources");

    rrviews: row style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2;
        justify-content: center;"
    {
      repa: repeater input=(@svr->input | geta "areas") {
        area_rect: dom style="flex: 1 1 0;" {
            process_rect: show_3d_scene
              scene3d=(@area_rect->input | geta "visible_sources" | map_geta "scene3d")
              camera=(@area_rect->input | geta "camera")
              style="width:100%; height:100%;"
              {{ console_log_params "CACACA"}}
              ;

            extra_screen_things: 
              column style="padding-left:2em; min-width: 80%; position:absolute; bottom: 1em; left: 1em;" {
                 dom_group input=(@area_rect->input | geta "visible_sources" | map_geta "scene2d");
              };  
              
          }; // area-rect  
        }; // repeater of areas

      }; // global row rrviews

   }; // domgroup

}; // show vis tab


// вход: project, areas, cameras
feature "areas_settings_dialog" {
    d: dialog {{console_log_params "DDD" }} {
     dom style_1=(eval (@d->areas | arr_length) 
           code="(len) => 'display: grid; grid-template-columns: repeat('+(1+len)+', 1fr);'") 
     {
        text "/";
        dom_group {
          repeater input=(@d->areas) 
          {
            rr: column {
              text (@rr->input | get_param "title"); 
            };  
          };
        };
        dom_group { // dom_group2
          repeater input= (@d->project | get_param "processes") {
            q: dom_group {
              text (@q->input | get_param "title");
              repeater input=(@d->areas) 
              {
                i: checkbox value=(@i->input | get_param "sources" | arr_contains @q->input)
                  {{ x-on "user-changed" {toggle_visprocess_view_assoc2 view=@i->input process=@q->input;} }}
                ;
              };
            };
          }; // repeater2
        }; // dom_group2 

        text "камеры:" style="margin-top: 10px;";
        dom_group {
          repeater input=(@d->areas) 
          {
            rr: column style="margin-top: 10px;" {
              combobox values=(@d->cameras | map_geta "title");
              //render-param-list 
            };  
          };
        }; // dom group 3
      }; // dom grid  

    }; // dlg
};