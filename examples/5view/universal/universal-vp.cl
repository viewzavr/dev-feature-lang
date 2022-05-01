feature "axes-view" {
	view: visual_process title="Оси координат"
	gui=@ab->gui
	scene3d=@ab->output
	visible=true
	{
	 ab: axes-box size=20 visible=@view->visible;
  };
};
