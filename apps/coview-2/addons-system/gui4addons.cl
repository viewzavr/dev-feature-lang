////////////////////////


// input - список аддонов
feature "show_addons"
{
  svlist: repeater {
        amm: column style='border:1px solid #050505; border-radius:5px;
             position: relative' // relative чтобы внутри X позиционировать через absolute
           ~plashka
           expanded=(@amm->input | geta "tab_expanded" default=false)
        {

          dom_group {

            if ( (@amm->input | geta "title" default='') == "-") {

               row 
               
               {
                   oct: object_change_type text="" input=@amm->input
                      types=(@amm->input  | geta  "sibling_types" default=[] )
                      titles=(@amm->input | geta "sibling_titles" default=[] )
                      {{ reaction (event @oct "type-changed") {: obj | obj.setParam('tab_expanded',true):} }}
                      //{{ x-on "type-changed" { m_lambda "(e) => { e.setParam('expanded',true); }" @amm }; }};
               }
                
            }
            else {

               row gap="2px" {
                 	acbv: checkbox value=(@amm->input | geta "visible");
                  button (@amm->input | geta "title")
                  {
                    m_apply "(env) => env.setParam('expanded', !env.params.expanded, true)" @amm;
                  };
                    
                  x-modify input=@amm->input {
                    x-set-params visible=@acbv->value __manual=true
                    ;
                  };

                  dom style='width: 22px;';

               }; // row

           }; // else

         };

         button "x" style="position:absolute; top:5px; right:3px;" 
              {
                lambda @amm->input code=`(obj) => { obj.removedManually = true; obj.remove(); }`;
              };

         insert_children input=@.. list=(@amm->input | get_param "gui") active=@amm->expanded;
        }; 

    }; // svlist  

};

/////////////////////////////////////////////////////////////

// визуальное управление добавками (фичьями)
// операции: добавить, удалить, ммм... поменять тип?
// 0, input - объект

/*
feature "manage_addons" {
  ma: dom_group input=@.->0? title="Модификаторы"
  {

   co: collapsible (join @ma->title (if (@co->addons_count > 0) then={ join " (" @co->addons_count ")" }))
   addons_count=(@ma->input? | geta "addons_container" | get_children_arr | geta "length" default=0)
   //expanded=false
   //expanded=(@co->addons_count > 0)
   expanded=(@ma->input | geta "addons_tab_expanded" default=false)
   //{{ m-on "param_expanded_changed" "(tgt,v) => tgt.setParam('addons_tab_expanded',v)" @ma->input }}
   {
   	 addons_area input=@ma->input;
   };
  };
};
*/

feature "addons_area" {
  aa: column ~plashka {

    column {
      //show_addons input=(@aa->input? | geta "addons_container" | get_children_arr | sort_by_priority);
      show_addons input=(find-objects-bf "addon_object" root=@aa->input include_root=false depth=1 | sort_by_priority)
    }

	ba: button_add_object add_to=@aa->input
	                      add_type="effect3d_blank"
	                      text="+"
  	
  }
}