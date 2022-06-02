register_feature name="collapsible2" {
  cola: 
  column text=@.->0 //button_type=["button"]
  {
    shadow_dom {
      //btn: manual_features=@cola->button_type text=@../..->text cmd="@pcol->trigger_visible";
      btn: row {
        button text=@../..->text cmd="@pcol->trigger_visible";
        checkbox ;
      };  

      pcol: 
      column visible=@cola->expanded {{ use_dom_children from=@../..; }};
      // сохраняет состояние развернутости колонки в collapsible-е
      // без этого сохранения не получится т.к. содержимое колонки 
      // не проходит dump по причине что shadow_dom вычеркнул себя из списка детей.
      // возможно это стоит и полечить.
      link from="@pcol->visible" to="@cola->expanded" manual_mode=true;

      insert_features input=@btn  list=@cola->button_features;
      insert_features input=@pcol list=@cola->body_features;

    };

  };
};


feature "render_layers_inner2" {

rl_root: 
    column text=@.->title
    style="min-width:250px" 
    style_h = "max-height:80vh;"
    {
     s: switch_selector_row {{ hilite_selected }} 
         items=(@rl_root->items | arr_map code="(v) => v.title")
         plashka style_qq="margin-bottom:0px !important;"
         visible=((@s->items | geta "length") > 1);

     link to="@ba->add_to" from=(@rl_root->items | get @s->index | get "add_to");
     ba: button_add_object 
                       add_type=(@rl_root->items | get @s->index | get "add");

     objects_list:
     find-objects-bf (@rl_root->items | get @s->index | get "find") 
                     root=@rl_root->root
                     recursive=false
     | sort_by_priority;
     ;

     @objects_list->output | repeater {
       co: collapsible (@co->input | geta "title") expanded=true 
       {
         object_change_type input=@co->input
            types=(@co->input  | geta  "sibling_types" )            
            titles=(@co->input | geta "sibling_titles")
         ;

         column {
          insert_children input=@.. list=(@co->input | get_param name="gui");
         };

         button "x" style="position:absolute; top:0px; right:0px;" 
         {
           lambda @co->input code=`(obj) => { obj.removedManually = true; obj.remove(); }`;
         };
       }
     }


  };   

};

////////////////////////

feature "show_addons"
{
  svlist: repeater {
        amm: column {
         row {
         	acbv: checkbox value=(@amm->input | get_param "visible");

         	object_change_type text="" input=@amm->input
            	types=(@amm->input  | geta  "sibling_types" )            
            	titles=(@amm->input | geta "sibling_titles")
            	;
            
            x-modify input=@amm->input {
              x-set-params visible=@acbv->value ;
            };

            button "x" //style="position:absolute; top:0px; right:0px;" 
	        {
	          lambda @amm->input code=`(obj) => { obj.removedManually = true; obj.remove(); }`;
	        };

         };
         insert_children input=@.. list=(@amm->input | get_param "gui");
        }; 

    }; // svlist  

};


feature "show_addons0"
{
  sv: row {
    svlist: row {
      repeater input=@sv->input {
        mm: 
         row {
        //dom tag="fieldset" style="border-radius: 5px; padding: 2px; margin: 2px;" {
          collapsible text=(@mm->input | get_param "title" default="no title") 
            style="min-width:250px;" padding="2px"
            style_h = "max-height:80vh;"
            body_features={ set_params style_h="max-height: inherit; overflow-y: auto;"}          
            expanded=(@mm->input_index == 0)
          {
             insert_children input=@.. list=(@mm->input | get_param "gui");
             // вот мы вставили гуи
          };

          cbv: checkbox value=(@mm->input | get_param "visible");
          x-modify input=@mm->input {
            x-set-params visible=@cbv->value ;
            x-on "show-settings" {
              lambda @extra_settings_panel code="(panel,obj,settings) => {
                 //console.log('got x-on show-settings',obj,settings)
                 // todo это поведение панели уже..
                 // да и вообще надо замаршрузизировать да и все будет.. в панель прям
                 // а там типа событие или тоже команда
                 if (panel.params.list == settings)
                   panel.setParam('list',[]);
                 else  
                   panel.setParam('list',settings);
                 
              };
              ";
            };
          };
        }; // fieldset
      }; // repeater

      //@repa->output | render-guis;
      //render-params @rrviews;

    }; // svlist  


    extra_settings_panel_outer: row gap="2px" {
      extra_settings_panel: 
      column // style="position:absolute; top: 1em; right: 1em;" 
      {
         insert_children input=@.. list=@extra_settings_panel->list?;
      };
      button "&lt;" style_h="height:1.5em;" visible=(eval @extra_settings_panel->list? code="(list) => list && list.length>0") 
      {
         setter target="@extra_settings_panel->list" value=[];
      };
    }; // extra_settings_panel_outer

    }; // row    
};

/////////////////////////////////////////////////////////////

// визуальное управление добавками (фичьями)
// операции: добавить, удалить, ммм... поменять тип?
// input, channel

feature "manage_addons" {
  ma: dom_group 
  {
   button "Добавки" //cmd="@addons_dialog->show"
   {
     //setter target="@addons_dialog->container" value=( @ma->input | geta "addons_container");
     setter target="@addons_dialog->input" value=@ma->input;
     call target="@addons_dialog" name="show";
   };
  };  
};

addons_dialog: dialog style="position:absolute; width: 80vw; bottom: 0px; top: initial;"
  //visible=false
  input=(@objects_list->output | geta @cbsel->index)
{
	   column {
	   
	   objects_list: find-objects-bf "editable-addons";
	   //combobox
	   row {
	       cbsel: combobox style="margin: 5px;" //dom_size=5 
	         values=(@objects_list->output | arr_map code="(elem) => elem.$vz_unique_id")
	         titles=(@objects_list->output | map_param "title")
	         ;	   

	       //text "добавки";
	       ba: button_add_object add_to=(@addons_dialog->input? | geta "addons_container")
	                             add_type="effect3d_additive"
	                             text="Добавить добавку"
	                             ;

       };
       //show_addons input=@addons_dialog->input? container=(@addons_dialog->input? | geta "addons_container" | get_children_arr);
       row {
       	 render-params @addons_dialog->input;
       	 
         show_addons input=(@addons_dialog->input? | geta "addons_container" | get_children_arr | sort_by_priority);
        };
       };
  
};

feature "manage_addons2" {
  ma: collapsible "Добавки" {
    ba: button_add_object add_to=@ma->container
                          add_type="effect3d_additive";

    show_addons input=(@ma->container | get_children_arr);

    /*
    render_layers_inner2 "Добавки"
         root=@ma->container
         items=[ {"title":"Эффекты отображения", "find":"geffect3d","add":"effect3d_blank","add_to":"@ma->container"}]
         ;
    */
  };
};


feature "manage_addons3" {
  dg: dom_group {
   button "Добавки" {
     //lambda @view @view->gui2 code="(obj,g2) => { obj.emit('show-settings',g2) }";
   };

    extra_settings_panel_outer2: row gap="2px" {
      extra_settings_panel2: 
      column // style="position:absolute; top: 1em; right: 1em;" 
      {
         insert_children input=@.. list=@extra_settings_panel2->list?;
      };
      button "&lt;" style_h="height:1.5em;" visible=(eval @extra_settings_panel->list? code="(list) => list && list.length>0") 
      {
         setter target="@extra_settings_panel2->list" value=[];
      };
    }; // extra_settings_panel_outer

  }; 
};    
