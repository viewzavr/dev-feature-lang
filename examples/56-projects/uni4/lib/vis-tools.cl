
// организует отображение группы визуальных процессов
// с точки зрения gui и scene2d, scene3d
// также содержит возможность добавлять новый объект в группу

// find - ключ поиска
// add - {}-запись новых объектов
feature "vis-group" 
{
	vp: visual_process
	title="Изображение группы"
	show_settings_vp=@vp
	find="visual_process"
	add=null

	gui={
		column style="padding-left:0em;" {

		  column {
			  insert_children input=@.. list=@vp->gui0?;
		  };
		  
		  /*
			cp: column plashka visible=( > (@cp | get_children_arr | geta "length") 1) 
			{
			  render-params @vp filters={ params-hide list=["title","visible"]; }; 
		  };
		  */

	    manage-content @vp 
	       vp=@vp->show_settings_vp
	       title="" 
	       items=(m_eval `(t,t2) => { return [{title:"Скалярные слои", find:t, add:t2}]}` 
	       	      @vp->find @vp->add)
	       ;

	    manage-addons @vp;

    };
	}
	generated_processes=(find-objects-bf root=@vp features="visual-process" include_root=false recursive=false)
    scene2d=(@vp->generated_processes | map_geta "scene2d" default=null)
    scene3d=@vp->output
    ~node3d 
    ~editable-addons
    // авось прокатит
    {
    };

};