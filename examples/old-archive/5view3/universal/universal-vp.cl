feature "axes-view" {
	view: 
	visual_process title="Оси координат"
	gui=@ab->gui
	scene3d=@ab->output
	exporting_3d
	visible=true
	size=20
	{
	  ab: axes-box size=@view->size visible=@view->visible;
    };
};
