load files="gui";

screen auto-activate layout flow="column" padding="1em" {
  dom tag="h1" innerHTML="Привет мир!";
  layout flow="row" gap="0.5em" padding="1em" style="background: grey;" {
  	b1: button text="нажми";
  	b2: button text="на";
  	button text="кнопку!" cmd=@f1->apply;
  };
  file padding="1em";

cb1:  combobox values=["afla.csv","beta.csv","teta.csv"];


  row {
     text text="combo value = ";
     lab0: text text=@cb1->value;
  };
  row {  
     text text="combo index = ";
     lab1: text text=@cb1->index;
  };


  tabview index=@cb1->index {
    	tab text="first" padding="0.2em" {
    		button text="куку";
    	};
    	tab text="second" padding="0.2em" {
    		row gap="0.5em" {
    			button text="крякря";
    			combobox values=["sigma","ulundi"];
    		}
    	};
    	tab text="и ищще" padding="0.2em" {
    		button text="куку-2";
    	};    	
  };
  

/*
  tabview {
  	tab text="первая" {
  		button text="1";
  	};
  	tab text="вторая" {
  		button text="2";
  	};
  };
*/  
  
};

f1: func {
  			func cmd=@setter1a->apply;
  			func cmd=@func2->apply;
  	};
setter1a: func {
  	  setter object=@b2 param="text" value="эту";
  	  setter object=@b1 param="text" value="НАЖМИ";
  	};
func2: func code=`console.log(333)`;

  
/*	  
register_feature name="button" {
	dom tag="button" innerHTML=@.->text dom_type="file" {
		dom_event object=@.. name="click" cmd=@..->cmd;
	}
};

register_feature name="file" {
	dom tag="input" dom_type="file" {
		dom_event object=@.. name="change" code=`
		  console.log("!!!!!!!!!!!!!!!!!! assigning file output to",env.params.object.dom.files[0])
		  env.params.object.setParam("output",env.params.object.dom.files[0],true)
		`
	}
};
*/

/*
register_feature name="file" {
	dom(tag="input")
	dom_events(change=`
	      console.log("!!!!!!!!!!!!!!!!!! assigning file output to",env.dom.files[0])
		  env.setParam("output",env.dom.files[0],true)`
		 `)
	dom_attrs( type="file" );
	
};
*/

/*
register_feature name="file" {
	dom tag="input" dom_type="file" {
		dom_event event="change" cmd=@f2->apply;
		f2: func code=`
		  console.log("!!!!!!!!!!!!!!!!!! assigning file output to",env.ns.parent.dom.files[0])
		  env.ns.parent.setParam("output",env.ns.parent.dom.files[0],true)
		`;
	}
};
*/

/*
register_feature name="file" {
	dom tag="input" dom_type="file" {
		dom_event object=@.. event="changed" cmd={func code=`env.setParam("output",env.dom.files[0],true)`;}
	}
};
*/


//button text="click me" cmd=;

// mycanvas: dom tag="canvas";

  	/*
  	dom tag="button" innerHTML="Нажми";
  	dom tag="button" innerHTML="на";
  	dom tag="button" innerHTML="на кнопку" dom_bind_click="cmd";
  	*/