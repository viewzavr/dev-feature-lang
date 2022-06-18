the-project {
	lava-group title="БЛОК"
	  files=(text2array "
ParticleData_Fluid_0_1750.vtk
ParticleData_Fluid_0_1751.vtk
ParticleData_Fluid_0_1752.vtk
");

	lava-group title="ЛАВА"
	  files=(text2array "
ParticleData_Fluid_0_1750.vtk
ParticleData_Fluid_0_1751.vtk
ParticleData_Fluid_0_1752.vtk
");

	vis-obj file="etna-1.obj" {{
		x-effect-pos x=-20 y=20;
		x-effect-rotate x=90;
	}};
};


======
3 поход
data.csv

***** styles.cl ******
FILE_vtkpoints.color=[1,1,0]

FILE_obj: obj-vis {{
	x-effect-pos x=-20 y=20;
	x-effect-rotate x=90;
}}


------------------ main.cl

load "56view";

project: the-project {
	lava-group title="БЛОК"
	  files=(load-csv "data.csv" column="A");

	lava-group title="ЛАВА"
	  files=(load-csv (resolve_url "some/data.csv") column="B");

	lava-group title="ЛАВА 2"
	  files=(load-txt "my-files.txt");	  

	vis-obj file="etna-1.obj" {{
		x-effect-pos x=-20 y=20;
		x-effect-rotate x=90;
	}};
};

screen1: screen auto-activate  {
  render_project @project active_view_index=0;
};