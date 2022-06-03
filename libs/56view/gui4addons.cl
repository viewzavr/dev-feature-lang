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

/////////////////////////////////////////////////////////////

// визуальное управление добавками (фичьями)
// операции: добавить, удалить, ммм... поменять тип?
// input, channel

feature "manage_addons" {
  ma: dom_group input=@.->0?
  {
  	/*
   button "Добавки" //cmd="@addons_dialog->show"
   {
     //setter target="@addons_dialog->container" value=( @ma->input | geta "addons_container");
     setter target="@addons_dialog->input" value=@ma->input;
     call target="@addons_dialog" name="show";
   };
   */
   collapsible "Добавки" expanded=( (@aa->input? | geta "addons_container" | get_children_arr | geta "length") > 0)
   {
   	 addons_area input=@ma->input;
   };
  };
};

feature "addons_area" {
  aa: column {
	ba: button_add_object add_to=(@aa->input? | geta "addons_container")
	                      add_type="effect3d_blank"
	                      text="+"
	                      ;

  	show_addons input=(@aa->input? | geta "addons_container" | get_children_arr | sort_by_priority);
  };
};	

addons_dialog: dialog style="position:absolute; width: 80vw; bottom: 0px; top: initial;"
  //visible=false
  input=(@objects_list2->output | geta @cbsel->index?)
{
	   column {
	   
	   objects_list2: find-objects-bf "editable-addons";
	   //combobox
	   row {
	       cbsel: combobox style="margin: 5px;" //dom_size=5 
	         values=(@objects_list2->output | arr_map code="(elem) => elem.$vz_unique_id")
	         titles=(@objects_list2->output | map_param "title")
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
                          add_type="effect3d_blank";

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
