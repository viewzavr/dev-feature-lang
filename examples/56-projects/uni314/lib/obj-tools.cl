feature "obj-vis-file" {
	it: visual_process title='obj' 
		scene3d=@mesh->scene3d 
		gui={

			render-params @it filters={ params-hide list="title"; };

			insert_children input=@.. list=@mesh->gui;
			
			//text "positions"
		}
		{{ x-param-file name="file" }}
		visible=@mesh->visible
		{
  			loadobj: load_file file=@it->file | parse_obj;
	  		mesh: mesh-vp 
	  		  input=@loadobj->output?
	  		  color=@it->color?
	  		  visible=@it->visible;
 	  };
};