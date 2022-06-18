feature "vtk-series" {
		vp: visual_process
		  title="Серия VTK"
		  scene2d=(list @cur->scene2d @vis->scene2d)
		  scene3d=(list @vis->scene3d)
		  gui={
		  	column style="padding-left: 1em;" {
		  	  show_sources_params input=(list @cur @vis);
		    };
		  }
		  gui3={
		  	render-params @vp;
		  }
		  {{ x-on "cocreated" {
		  		setter target="@vis->initial_input_link" value=(+ (@load | geta "getPath") "->output");
		  	} }}
		  {

		  	cur: select-file-by-n 
		  	    input=@vp->files 
		  	    title="Выбор N";

		  	load: load-vtk-file input=@cur->output;

			vis: vis-many title="Колонки данных VTK" find="vtk-vis-1" add="vtk-vis-1" 
				points_loaded=(@load->output | geta "length")
				{{ x-param-label-small name="points_loaded" }}
				gui0={ render-params plashka @vis filters={ params-hide list=["title","visible"]; }; }
				visible=@vp->visible
		  	{
	  	  		vtk-vis-1 
	  			      input=@load->output
	  			      title=@.->selected_column
	  			      selected_column="visco_coefs"
	  			      show_source=false
	  			;
		  	};
				insert_children input=@vis->addons_container active=(is_default @vis) list={
						effect3d-delta dz=5;
				};
		  	
		  };
};


feature "obj-array" {
		vp: visual_process
		  title="OBJ файлы"
		  scene2d=(list @cur->scene2d @visobj->scene2d)
		  scene3d=(list @visobj->scene3d)
		  gui={
		  	column style="padding-left: 1em;" {
		  	  show_sources_params input=(list @visobj);
		    };
		  }
		  gui3={
		  	render-params @vp;
		  }
		  {{ x-on "cocreated" {
		  		setter target="@vis->initial_input_link" value=(+ (@load | geta "getPath") "->output");
		  	} }}
		  {

		  	visobj: vis-many title="OBJ-файлы" find="obj-vp" add="obj-vp" 
		  	{
		  	  repeater input=@vp->files { 
		  	    i: obj-vp
  							  file=(@i->input | geta 1)
  							  title=(@i->input | geta 0);
		  	  };
		  	};
		  	
		  };
};

// todo притащить сюда obj-vp