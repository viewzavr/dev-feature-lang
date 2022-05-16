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

// вход - project - визпроект
feature "manage_visual_processes" {
	vp:
	collapsible "Визуальные процессы" {
		text 555;

	    @vp->project | geta "processes" | repeater
	    {
	       edit_visprocess;
	       button text=(@i->input | geta "title") 
	             value=(@qq->tv | geta "sources" | arr_contains @i->input)
	          {{ x-on "user-changed" {
	              toggle_visprocess_view_assoc2 process=@i->input view=@qq->tv;
	          } }};
	    };


	};
};

feature "edit_visprocess" {
	qq: collapsible text=(@i->input | geta "title")  {
		insert_siblings list=(@qq->input | get_param name="gui");
	};
};