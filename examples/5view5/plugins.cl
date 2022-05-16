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
	vp: project=@..->project
	collapsible "Визуальные процессы" {

	    @vp->project | geta "top_processes" | repeater
	    {
	       edit_visprocess;
	    };


	};
};

feature "edit_visprocess" {
	qq: collapsible text=(@qq->input | geta "title")  {
		insert_siblings list=(@qq->input | get_param name="gui");
	};
};