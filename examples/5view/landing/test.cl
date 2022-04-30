feature "test-view-1" 
{

  view1: visual_process title="Возвращение" gui={
	text "это я";
	render-params input=@params;
	render-params input=@pts;
  }
  scene3d=@scene->output;
  {

  	params: 
  	  count=1000
  	{{
  	  //param_checkbox name="visible";
  	  x-param-slider name="count" max=10000;
  	}};

    scene: node3d {
    	//axes_box size=100;
    	pts: points positions=(eval @params->count code="(count) => {
    		//let count=100;
    		let arr=[];
    		let r=50;
    		for (let i =0; i<count; i++)
    			arr.push( Math.random()*r,Math.random()*r,Math.random()*r)
    		return arr;	
    	}");
    	// positions=(generate3d count=100 point_code="(i) => ....")
	};  	

    // ну вот... как бы это.. а мы бы хотели...
    /*
	insert_children input=@view1->scene2d list={
		text "привет";
	};	
	*/

  };
	

};