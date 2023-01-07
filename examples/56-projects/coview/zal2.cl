
coview-record title="Парсер геометрии" type="zal-parse-geom" id="compute"

feature "zal-parse-geom" {
	x: computation 
	input="" {{ x-param-text name="input" }}
	title="Парсер геометрии"
	output=@zal
	gui={ paint-gui @x }
	//gui={ render-params @x }
	{{ x-param-label name="status" }}
	status=(join with=" " "children:" (read @zal | get_children_arr | geta "length") 
		      "<br/>"
		      "rangex:" @zal.rangex
		      "rangey:" @zal.rangey
		      "<br/>"
		      "stepx:" @zal.stepx
		      "stepy:" @zal.stepy
		      )
	{
		//console-log "ZAL " @x "input=" @x.input

		gui { // gui tabs = ...
			gui-tab "main" {
				//me: console-log "gui x=" @x "me=" @me
				gui-text  @x "input"				
				gui-label @x "status"
			}
			gui-tab "test"
		}

		//parameter "input" "" {{ param-type "string" }}

		let dump = (read @x.input | compalang)
		insert_children list=@dump input=@zal
		zal: object
		  	  rangex=((find-objects-bf "RangeX" root=@zal | geta 0 | geta 1) or 0)
	  	  	  rangey=((find-objects-bf "RangeY" root=@zal | geta 0 | geta 1) or 0)
	  	  	  stepx=((find-objects-bf "GridStep" root=@zal | geta 0 | geta 0) or 1)
	  	  	  stepy=((find-objects-bf "GridStep" root=@zal | geta 0 | geta 1) or 1)

		// param @x "output" | put-value @zal
		// assign (param @x "output") @zal
		// мб идеал: assign @x.output @zal

		//set-param output=@zal // ну это было бы логично
		// получается я сейчас не шибко то могу группировать по "темам" коды.. вот output связь снаружи написал
	}
}

/* это бы позволило делать веб-компоненты еще проще..? типа на вход сложная структура, получили, расписались..
   собрали все коды, подставили в нужное место. 
   ток кавычка {{ }} не оч удачна лучше другую.
   или это ток для строчек подходит? вот бы тут аналог erb уже.. 
   котлин кстати каким-тио образом генерит строчки и ничего (хотя тут важно именно погружение в строку..)
   но erb то на чем? на js? надо свой делать. у нас почти и свой, ток блоков не хватает ))))

cofun "zal-status" { |zal|
	format-text `
	  children={{ read @zal | get_children_arr | geta "length" }}
	  types:
	    {{ @zal | get_children_arr | map { |item| get-item-feature @item } | to-report }}
	  rangex={{ @zal.rangex }}
	  rangey={{ @zal.rangey }}
	  stepx={{ @zal.stepx }}
	  stepy={{ @zal.stepy }}
	  `
}
*/


feature "RangeX" { object }
feature "RangeY" { object }
feature "GridStep" { object }

feature "MeasuringPoint" {
	x: object //pos=(list (10 * @x->0) 10 (10 * @x->1)) {
//		 node: node3d {
//		   spheres positions=(list @x->0 0 @x->1) color=[1,0,0] radius=30 opacity=0.2
		   //m-eval {: obj=@node.output |	let r = 10;	obj.scale.set( r,r,r ) :} 	
//		 }
	//}
}

feature "measuringPoint" {
	MeasuringPoint
}

// это видимо где надо провести замеры
feature "Vertex" {
	//x: spheres positions=(list @x->0 0 @x->1) radius=100
	x: object {
		 //node: node3d //position=[10,0,0] // сдвиг..
		 //{
		   //spheres positions=(list @x->0 0 @x->1) color=[1,1,1] radius=30
		   //m-eval {: obj=@node.output |	let r = 10;	obj.scale.set( r,r,r ) :}

		   //m-eval {: obj=@n.output | obj.position.set( 30,0,0 ) :}
		 //}
	}	
}

feature "DrawObstacled"
feature "Speed"
feature "RandomPathsCount"
feature "RangeDose"
feature "RandSeed"


feature "ObstacleCircle" {
	x: object {
		/*
		 node3d {
		   cylinders nx=100 positions=(list @x->0 0 @x->1 @x->0 500 @x->1) color=[1,1,1] radius=@x->2	 	
		 }
		*/ 
	}
}

feature "ObstaclePolyStart" {
	x: object nodes=(find-objects-bf "ObstaclePolyPoint" root=@x)
	/*
	   {
		 node3d {
		 	mesh positions=(m-eval {: nodes=@x.nodes |
		 		let arr = [];
		 		let z = 250
		 		for (let i=0; i<nodes.length; i++) {
		 			let n1 = nodes[i];
		 			let n2 = nodes[ (i+1) % nodes.length];
		 			arr.push( n1.params[0], z, n1.params[1] )
		 			arr.push( n1.params[0], 0, n1.params[1] )
		 			arr.push( n2.params[0], z, n2.params[1] )

		 			arr.push( n1.params[0], 0, n1.params[1] )
		 			arr.push( n2.params[0], 0, n2.params[1] )
		 			arr.push( n2.params[0], z, n2.params[1] )
		 		}
		 		return arr
		 	:})
		 }
	   }
    */
}

feature "ObstaclePolyPoint" {: env |
	//console.log("qq",env.ns.parent)
	let cc = env.ns.parent.ns.getChildren();
	let myindex = cc.indexOf( env );
	let poly = null
	for (let i=myindex-1; i>=0; i--)
	  if (cc[i].is_feature_applied("ObstaclePolyStart")) {
	  	poly = cc[i]
	  	break;
	  }
	//let poly = cc[ cc.length-2 ];
	if (poly && poly.is_feature_applied("ObstaclePolyStart")) 
		poly.ns.appendChild( env, env.ns.name, true ); // переезд
	else {
		console.error("ObstaclePolyPoint cannot find ObstaclePolyStart",env)

	}
:}