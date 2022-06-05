find-objects-bf features="render_project_right_col" recursive=false 
|
insert_children { rotate_ramera_z; };

feature "rotate_ramera_z" {
	ma: 
	    project=@..->project
	    curview=@..->active_view

	collapsible "Поворот камеры" {
		column plashka {
			render-params @astracam;

			astracam: 
				 angle=0 radius=1
				 {{ x-param-slider name="radius" min=0.01 max=10 step=0.01 }}
				 {{ x-param-slider name="angle" min=-180 max=180 step=0.1 }}
				 campos=(m_eval "(a,r) => {
				 	 let ar = Math.PI*2*a/360.0;
		       let x = Math.cos(ar)*r;
		       let y = Math.sin(ar)*r;
		       return [x,y,r/5]
				 	}" @astracam->angle @astracam->radius)
				 	;

				x-modify 
				input=(@ma->curview| geta "camera")
				{
					x-set-params pos=@astracam->campos center=[0,0,0];
				};

		};
	};

};