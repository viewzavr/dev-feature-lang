feature "axes-view" {
	aaview: visual_process title="Оси координат"
	gui={
		column plashka {
			insert_children input=@.. list=@ab->gui;
		};
	}	
	scene3d=@ab->output
	visible=true
	size=20
	{
	  ab: axes-box size=@aaview->size visible=@aaview->visible;
    };
};

feature "text3d_one_vp" {
	vp: visual-process editable-addons title="Текст"
	  gui={ render-params @vp
	  	       filters={ params-hide list="title"; }; 
	    manage-addons @vp; }
	  text3d_one
	  ;
};

feature "text3d_vp" {
	vp: visual-process editable-addons title="Текст"
	  gui={ render-params @vp
	  	       filters={ params-hide list="title"; }; 
	    manage-addons @vp; }
	  text3d
	  ;
};

feature "points_vp" {
	vp: visual-process editable-addons title="Точки"
	  gui={ render-params @vp
	  	       filters={ params-hide list="title"; }; 
	    manage-addons @vp; }
	  points;
};

feature "linestrips_vp" {
	vp: visual-process editable-addons title="Отрезки"
	  gui={ render-params @vp
	  	       filters={ params-hide list="title"; }; 
	    manage-addons @vp; }
	  linestrips;
};

// вопрос как передать addons в меш..
feature "spheres_vp" {
	vp: visual-process editable-addons title="Сферы"
	  gui={
	  	render-params @vp
	  	       filters={ params-hide list="title"; };
	  	 render-params @vp->mesh
	  	       filters={ params-hide list="visible"; };
	    manage-addons @vp->mesh; }
	  spheres;
};