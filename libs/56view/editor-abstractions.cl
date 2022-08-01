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

// гуи по управлению содержимым объекта
// 0 - объект
// find - строчка по которой искать управляемые объекты
// add - шаблон нового объекта

feature "manage-content" {

 	mc: column root=@mc->0 

     plashka {

     dom tag="h3" style="margin:0px; color: white; " innerText=@mc->title;

     //@ba | x-modify-list list=@mc->add_bt_modifiers;

     objects_list:
     find-objects-bf (@mc->items | geta 0 | geta "find") 
                     root=@mc->root
                     recursive=false
                     include_root=false 
                    | sort_by_priority;

     column {                    
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
   			button (@rep->input | geta "title") 
                  style='min-width:220px;
    background: #70ddff;
    border-radius: 5px;
    border: 1px solid black;
    margin: 2px;
                '
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

    }; // column of elements
    
     if (@mc->items | geta 0 | geta "add" default=null) then={
          ba: button_add_object_t
               add_to=@mc->root
               add_template=(@mc->items | geta 0 | geta "add")
               ;
     };
   	
    }; // main col
};

// **********************************

feature "manage-content2" {

     mc: column root=@mc->0 vp=@mc->root

     plashka {

     dom tag="h3" style="margin:0px; color: white; " innerText=@mc->title;

     //@ba | x-modify-list list=@mc->add_bt_modifiers;

     objects_list:
     find-objects-bf features=@mc->find
                     root=@mc->root
                     recursive=false
                     include_root=false 
                    | sort_by_priority | console_log_input;

     column {                    
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
               button (@rep->input | geta "title") 
                  style='min-width:220px;
    background: #70ddff;
    border-radius: 5px;
    border: 1px solid black;
    margin: 2px;
                '
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

    }; // column of elements
    
     if (@mc->add) then={
          ba: button_add_object_t
               add_to=@mc->root
               add_template=(@mc->add)
               ;
     };
     
    }; // main col
};

feature "show-inner-objects" {

     mc: column root=@mc->0 vp=@mc->root
     {{

     objects_list:
     find-objects-bf features=@mc->find
                     root=@mc->root
                     recursive=false
                     include_root=false 
                    | sort_by_priority | console_log_input;
     }}                    
     {
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
               button (@rep->input | geta "title") 
                  style='min-width:220px;
    background: #70ddff;
    border-radius: 5px;
    border: 1px solid black;
    margin: 2px;
                '
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
     
    }; // main col
};