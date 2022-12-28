/*
uni-maker code={ |art|
	object 
	  possible=
	  artefact={ |gen|
	  	 ....
	  }
	  visual-process={ |view|

	  }
}
*/
 
/* или вот так:
uni-maker code={ |art| }
 object
	 title="Это вот то"
	 possible=....
	 artefact={ .... } // это делалка артефакта
	 visual={ ...... } // это делалка визуализации
	 operator={ ..... } // это делалка оператора преобразования
	 automatic=true
}
*/

/* вот это и лучше и хуже. лучше тем что можно менять артефакт.
  хуже что по артефакту не сохранить на этапе possible промежуточных данных
  но кстати можно:
artefact-maker
 title="Это вот то"
 possible={ |art| ... }
 data={ |art possible| .... } // это делалка артефакта
 visual={ |art possible view| ...... } // это делалка визуализации
 operator={ |art possible| ..... } // это делалка оператора преобразования
 automatic={ |art| .... }

 но тут везде art таскается и это тупо.
*/

artmaker
 code={ |art|
	 x: object 
	  possible=@x.txt_file?
	  txt_file=(find-files @art.output? "data.*\.(txt)$" | geta 0 default=null)
	  make={ |gen|
	  	 zal-data input= @x.txt_file
	  }
	  //{{ console-log "zal possible=" @x.possible (m-eval @x.getPath) }}

  }

feature "zal-data" { 
	x: data-artefact title="Зал" 
	    output=(load-file @x.input | compalang)
}

vismaker 
  code={ |art|
	  object 
	    title="Виз2"
	 	possible=(read @art | is-feature-applied name="zal-data")
	  	make={ |view|
	  		paint-zal input=@art
	  	}
  }

feature "paint-zal" {
	pz: visual_process 
	    {{ x-art-ref name="input" crit="zal-data" }}
	  	//output=@p.output
	  	title="Зал"
	  	gui3={ 
	  	  render-params @pz
	  	}
	  	scene3d={ |view|
	  	  object output=@node.output

	  	  node: node3d 
	  	    input=(find-objects-bf "node3d" root=@zal | map-geta "output")
	  	  {
	  	  	//points title="Точке" positions=[[[ Array(100*3).fill(0).map( Math.random ) ]]]
	  	  	//zal-paint
	  	  }

	  	  zal: object { // среда для моделирования, world
	  	  	
	  	  	g: grid 
	  	  	  rangex=(find-objects-bf "RangeX" | geta 0 | geta 1)
	  	  	  rangey=(find-objects-bf "RangeY" | geta 0 | geta 1)
	  	  	  //gridstep=(find-objects-bf "GridStep" | geta 0 | geta [0,1] )
	  	  	  gridstep=(find-objects-bf "GridStep" | geta 0 | m-eval {: obj | obj ? [obj.params[0], obj.params[1]] : [100,100] :} )
	  	  	  opacity=0.3

	  	  	//grid rangex=@g.rangex rangey=@g.rangey gridstep=m-eval [[[ (arr=@g.gridstep) => [ arr[0]*100, arr[1]*100 ] ]]]
	  	  	// надо сделать их тупо независимыми
	  	  	grid rangex=@g.rangex rangey=@g.rangey gridstep=(m-eval {: arr | [ arr[0]*100, arr[1]*100 ] :} @g.gridstep)
	  	  	  color=[0,1,0] radius=2

	  	  }

	  	  m-eval {: obj=@node.output |
	  	  	let r = 0.01
	  	  	obj.scale.set( r,r,-r )
	  	  	//console.log("setting scale to",obj.scale)
	  	  	//obj.rotation.z = 90 * Math.PI/180;
			//obj.rotation.x = -90 * Math.PI/180;
	  	  :}
	  	 
	  	  //console-log "art is" @pz.input "it's output is" @pz.input.output
	  	  //@pz.input.output | create target=@node
	  	  read @zal | insert_children list=@pz.input.output
	  	}
}

feature "MeasuringPoint" {
	x: object {
		 node3d {
		   spheres positions=(list @x->0 0 @x->1) color=[1,0,0] radius=100	 	
		 }
	}
}

// это видимо где надо провести замеры
feature "Vertex" {
	//x: spheres positions=(list @x->0 0 @x->1) radius=100
	x: object {
		 node3d {
		   spheres positions=(list @x->0 0 @x->1) color=[1,1,1] radius=100	 	
		 }
	}	
}

feature "DrawObstacled"
feature "Speed"
feature "RandomPathsCount"

feature "ObstacleCircle" {
	x: object {
		 node3d {
		   cylinders nx=100 positions=(list @x->0 0 @x->1 @x->0 500 @x->1) color=[1,1,1] radius=@x->2	 	
		 }
	}
}

feature "ObstaclePolyStart" {
	x: object nodes=(find-objects-bf "ObstaclePolyPoint" root=@x)
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
		 		/*
		 		nodes.forEach(node => {
		 			arr.push( node.params[0], 0, node.params[1] )
		 		})*/
		 		return arr
		 	:})
		 }
	   }	
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

feature "grid" {
	x: //object {
		lines color=[0, 0.5, 0]
		  positions=(m-eval {: x,y,dx,dy |
		  let acc=[];
          for (let i=0; i<=x; i+=dx) {
            acc.push( i, 0, 0 );
            acc.push( i, 0, y );
          };
          for (let i=0; i<=y; i+=dy) {
            acc.push( 0, 0, i );
            acc.push( x, 0, i );
          };
          return acc
		:} @x.rangex @x.rangey @x.gridstep.0 @x.gridstep.1 )
	//}
}

feature "RangeX" { object }
feature "RangeY" { object }
feature "GridStep" { object }

/////////////////////////////////////

/*

feature "zal" {
	z: object 
	      vertices=[]
		  measuring_points=[] // {x:..., y: ...}
		  measuring_points=(find-objects-bf crit="MeasuringPoint")
		  obstacle_polys=[]
		  obstacle_circles=[]
		  gridx=10
		  gridy=10
		  stepx=1
		  stepy=1
  	  {
	  }
}

feature "zal-paint" {
	p: node3d {
		spheres positions=(to_coords @p.input.measuring_points) color=[1,0,0] radius=100
		spheres positions=(to_coords @p.input.vertices) color=[1,1,1] radius=100
	}
}

// arr: [x,y,x,y,..] => [x,y,z,x,y,z,...]
feature "to_coords" {
	k: output=(m_eval [[[arr => {
		let res = [];
		for (let i=0; i<arr.length; i++)
		  res.push( arr[i].x, 0, arr[i].y )
		return res;  
	}]]] @k.0)
}
*/