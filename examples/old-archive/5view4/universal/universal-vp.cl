feature "axes-view" {
	aaview: visual_process title="Оси координат"
	gui=@ab->gui
	scene3d=@ab->output
	visible=true
	size=20
	{
	  ab: axes-box size=@aaview->size visible=@aaview->visible;
    };
};
