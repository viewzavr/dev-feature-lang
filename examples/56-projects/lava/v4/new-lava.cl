// todo раздвоить
// просмотр 1 источника по выбору N
// просмотр всех источников
// а чего просмотр - уже параметр..
// ну а далее уже понять что с синхр N и - как установить цвет блоку

feature "vtk-series" {
		vp: visual_process
		  title="Серия VTK"
		  scene2d=(list @cur->scene2d @vis->scene2d)
		  scene3d=(list @vis->scene3d)
		  output=@vis->scene3d
		  gui={
		  	column style="padding-left: 0em;" {
		  	  //show_sources_params input=(list @cur @vis);
		  	  //insert-children input=@.. list=(list @cur->gui @vis->gui);
		  	  insert-children input=@.. list=@cur->gui;
		  	  insert-children input=@.. list= @vis->gui;
		    };
		  }
		  gui3={
		  	render-params @vp;
		  }
		  {{ x-on "cocreated" {
		  		//setter target="@vis->initial_input_link" value=(+ (@load | geta "getPath") "->output");
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
				show_settings_vp=@vp
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

feature "vtk-vis-file" {
		vis: vis-many title="Колонки данных VTK" 
		    find="vtk-vis-1" 
		    add={ vtk-vis-1 input=@load->output title=@.->selected_column show_source=false; } 
				points_loaded=(@load->output | geta "length")
				{{ x-param-label-small name="points_loaded" }}
				gui0={ render-params plashka @vis filters={ params-hide list=["title","visible"]; }; }
				addons={effect3d-delta dz=5}
		  	{
	  	  		vtk-vis-1 
	  			      input=@load->output
	  			      title=@.->selected_column
	  			      selected_column="visco_coefs"
	  			      show_source=false
	  			;

	  			load: load-vtk-file input=@vis->input;
		  	};
 
};

/*
feature "vtk-vis-file" {
	vp: visual_process
	    gui=@vis->gui
	    scene3d=@vis->scene3d
	    scene2d=@vis->scene2d
  {
		load: load-vtk-file input=@vp->input;

		vis: vtk-vis-1
	  		 input=@load->output
	  		 title=@.->selected_column
	  		 selected_column="visco_coefs"
	  		 show_source=false
	  		 addons={	effect3d-delta dz=5; };
  };
};
*/


feature "obj-array" {
  vp: vis-many title="OBJ-файлы" find="obj-vp" add="obj-vp" 
  {
	  repeater input=@vp->files { 
  	    i: obj-vp
     		  file=(@i->input | geta 1)
  			  title=(@i->input | geta 0);
	   	    
		};
   };
};

/*
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
*/

// todo притащить сюда obj-vp