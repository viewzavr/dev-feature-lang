/*
   идея "управляемая область, известно чем управляема"
   и вот давайте добавляйте туда, удаляйте, редактируйте то что уже есть

   показывать будет кнопочками и выход на параметры. плюс кнопка добавить отдельно идет.

   альтернативно идея 

   - сделать кнопку "управлять объектами типа Х" 
   и нажимая эту кнопку показывать диалог render_layers_inner

   - управлять объектами и потом отдельно - добавить объект
   - возможность удалять объект.
   
*/

feature "manage-content" {

 	mc: column root=@mc->0 allow_add=true {

     if (@mc->allow_add) then={
          ba: button_add_object
               add_to=@mc->root
               add_type=(@mc->items | geta 0 | get "add")
               ;
     };     

     //@ba | x-modify-list list=@mc->add_bt_modifiers;

     objects_list:
     find-objects-bf (@mc->items | geta 0 | get "find") 
                     root=@mc->root
                     recursive=false
                     include_root=false debug=true
                    | sort_by_priority;

		@objects_list->output | repeater {
   		rep: row 

   		   item_gui = {
   		   	 column plashka {
                    dom tag="h3" innerText=(@rep->input | geta "title")
                      style="margin:0px; color: white;";
 				insert_children input=@.. list=(@rep->input | geta "gui")
   		   	 }
   		   }
   		 {
   			button (@rep->input | geta "title") style='min-width:220px;'
   			{
		       m_lambda "(obj,g2) => { obj.emit('show-settings',g2) }" 
		         @mc->vp @rep->item_gui;
   			};
   			k: checkbox-c value=(@rep->input | geta "visible")
   			   {{ x-on 'user-changed' {
   			   	  m_lambda "(obj,obj2,val) => {
   			   	    //console.log('setting visible to obj',obj,val );
   			   	    obj.setParam('visible', val, true);
   			   	  }" @rep->input;
   			   } }};
   		};
   	};
   	
    };
};