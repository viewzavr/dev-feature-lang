coview-record title="Сферы" type="spheres_vp_3d" id="basic"


// вопрос как передать addons в меш..
feature "spheres_vp_3d" {
	vp: visual-process 
	 ~editable-addons 
	 title="Сферы"
	 gui={ paint-gui @vp }
	~spheres {
		param-info "input" in=true // df-ка

		//console-log "vvv" @vp.output

		gui {
			gui-tab "main" {
				gui-slot @vp "input" gui={ | in out| gui-df @in @out }
			}
			gui-tab "view" {
	  	render-params @vp
	  	       filters={ params-hide list="title"; };
	  	 render-params @vp->mesh
	  	       filters={ params-hide list="visible"; };
			}
			gui-tab "addons" {
		manage-addons @vp->mesh; 		
			}
		}
	}
};