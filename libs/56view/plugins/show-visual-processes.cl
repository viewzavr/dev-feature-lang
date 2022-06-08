// первый плагин. поведение - при активации вида открывать параметры первого визуального процеса.

// визуальные процессы проекта

// монтаж
/*
insert_children @render_project_right_col_modifiers {
	x-insert-children list={manage_visual_processes};
}

// а там:
{{ x-modify modifiers=(@render_project_right_col_modifiers | get_children_arr ) }}
*/

find-objects-bf features="render_project_right_col" recursive=false 
|
insert_children { manage_visual_processes; };

////////////////////////////

// вход - project - визпроект
feature "manage_visual_processes" {
	vp: project=@..->project
      active_view = @..->active_view
    	collapsible "Визуальные процессы" {
        render_process_hierarchy objects=(@vp->project | geta "processes")
           active_view=@vp->active_view
        ;
                  
        //render_process_hierarchy objects=(@vp->project | geta "top_processes");
     	};
};

feature "render_process_hierarchy" {

    rh: objects=[] // список объектов верхних процессов

    column //text=@.->title?
    style="min-width:250px;" plashka
    style_h = "max-height:80vh;"
    
    {

    	// button "Добавить";
     //link to="@ba->add_to" from=(@rl_root->items | get @s->index | get "add_to");
     //ba: button_add_object 
     //      add_type=(@rl_root->items | get @s->index | get "add");
     // вообще вопрос нужна ли такая кнопка или другая такая кнопка с добавкой по типу.
     // потому что мб добавка дбыть методом плагина - добавлять конкретно что надо.
     // а не с выбором типа      

     /// верхний и след уровни...

/*
     objects_list0: (eval @rh->objects code="(objects) => {
     	  return objects.map( o => {
     	  	 return { id: o.$vz_unique_id, title: o.params.title } 
     	  } )
     }");
     */

     objects_list: (@rh->objects | repeater target_parent=@~ { 
     	 q: repeater_output=(concat @l1 @l2?) {
     		  l1: id=(@q->input | geta "$vz_unique_id")
     	        title=(@q->input | geta "title")
     	        obj=@q->input
     	         ;

     	    l2: (@q->input | geta "subprocesses" default=[] | repeater target_parent=@~ {
       	          qq: id=(@qq->input | geta "$vz_unique_id")
     	          title=(join "  - " (@qq->input | geta "title"))
     	          obj=@qq->input
     	          ;
     	        });
     	  };
        } | pause_input | map_geta "repeater_output" | geta "flat" | arr_compact);

     cbsel: combobox style="margin: 5px;" dom_size=10
       values=(@objects_list | map_geta "id")
       titles=(@objects_list | map_geta "title")
       ;

    /// параметры объекта

     selected_object: (@objects_list | geta @cbsel->index? default=null | geta "obj");

     co: column plashka style_r="position:relative; overflow: auto;"  
            input=@selected_object?
      {
        column {
          insert_children input=@.. list=(@co->input? | geta "gui3");
        };
        button "Клонировать" {
          m_apply "(obj,curview,cbsel) => {
             let n = obj.clone();
             n.then(nobj => {
              curview.append_process( nobj );
              console.log('cloned to',nobj);
              cbsel.setParam( 'index', cbsel.params.values.length-1 );
             })
          }" @co->input? @rh->active_view @cbsel;
        };

        button "x" style="position:absolute; top:0px; right:0px;" 
        {
          lambda @co->input? code=`(obj) => { obj.removedManually = true; obj.remove(); }`;
        };

     };


  };

};