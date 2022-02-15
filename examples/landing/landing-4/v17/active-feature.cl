register_feature name="active_feature" {
	addon-modifiers={
		set_params active=true;
	}
	addon-elems-modifiers={
		set_params active=@vlayer->active visible=@vlayer->active;
	}
	global={

		register_feature name="collapsible2" {
		  cola:
		  column
		  {
		    shadow_dom {
		      row {
		        btn: button text=@cola->text cmd="@pcol->trigger_visible" flex=1;
		        cba: checkbox value=@cola->active cola=@cola {{
		          onevent name="user-changed" {
		            emit_event object=@cola name="user-changed-active";
		          };
		        }};
		      };

		      pcol:
		      column visible=false {{ use_dom_children from=@cola; }};

		      deploy_features input=@btn  features=@cola->button_features;
		      deploy_features input=@pcol features=@cola->body_features;
		    };

		  };
		};

		register_feature name="element_plashka" {
		    collapsible2 text=@.->inputIndex /*body_features=@>each_body_features*/
		      active=(@.->input | get_param name="active")
		    {{
		      connection event_name="user-changed-active" code=`
		        env.host.params.input.setParam("active",args[0]);
		      `;
		    }}
		};	
	};
};
