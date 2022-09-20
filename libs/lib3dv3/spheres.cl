feature "spheres" {
	s: node3d 
    ~points_df_input 
	  {{ x-param-slider name="radius" min=0.0 max=100 step=0.1 }}
	  nx=16 ny=24 positions=[] radiuses=[] colors=[] radius=1
	  color=[1,1,1]
	  mesh=@m
	  {
        //mesh positions=[0,0,0, 1,1,1, 0,1,0 ];

		m: mesh positions=(@mdata->output | geta 0)
		         indices=(@mdata->output | geta 3)
		         colors=(@mdata->output | geta 4)
		         color=@s->color
		         ~editable-addons // временно
		         ;

		// result: [ positions, normals, uvs, indices, colors ]
		mdata: spheres_compute
		  positions=@s->positions radiuses=@s->radiuses 
		  colors=@s->colors radius=@s->radius
		  nx=@s->nx ny=@s->ny;
	};
};

// входные параметры
// nx ny positions radiuses colors radius
feature "spheres_compute" {
  s: m_eval nx=6 ny=5 positions=[] radiuses=[] colors=[] radius=1
		`(latitudeBands,longitudeBands,spheres_positions,spheres_radiuses,spheres_colors, rr) => {

			return make();

    function make() 
    {
        
        var positions = [];
        var normals = [];
        var uvs = [];
        var indices = [];
        var colors = [];

        if (!spheres_positions) return;

        if (spheres_positions.length > 5000*3) {
          console.log("Spheres: degrading nx,ny to 4 because too many spheres",spheres_positions);
          latitudeBands = 4;
          longitudeBands = 4;
        }

        if (Array.isArray(spheres_colors))
          if (spheres_colors.length != spheres_positions.length) {
          	if (spheres_colors.length > 0) {
          		console.error("spheres.cl: spheres_colors.length != spheres_positions.length, skipping use.")
          	}
            spheres_colors = undefined;
          }

        let radfunc = () => rr;
        if (spheres_radiuses && spheres_radiuses.length > 0)
          radfunc = (i) => spheres_radiuses[i]*rr;
        
        ///////////////////////////////////
        // make etalon
        var etalon = [];
        for (var latNumber = 0; latNumber <= latitudeBands; latNumber++) {
            var theta = latNumber * Math.PI / latitudeBands;
            var sinTheta = Math.sin(theta);
            var cosTheta = Math.cos(theta);

            for (var longNumber = 0; longNumber <= longitudeBands; longNumber++) {
                var phi = longNumber * 2 * Math.PI / longitudeBands;
                var sinPhi = Math.sin(phi);
                var cosPhi = Math.cos(phi);

                var x = cosPhi * sinTheta;
                var y = cosTheta;
                var z = sinPhi * sinTheta;
                //var u = 1- (longNumber / longitudeBands);
                //var v = latNumber / latitudeBands;
                //etalon.push([x,y,z,u,v]);
                etalon.push([x,y,z]);
            }
        }
        var etalon_length = etalon.length;

        var etalon_indices = [];
        for (var latNumber = 0; latNumber < latitudeBands; latNumber++) {
            for (var longNumber = 0; longNumber < longitudeBands; longNumber++) {
                var first = (latNumber * (longitudeBands + 1)) + longNumber;
                var second = first + longitudeBands + 1;
                etalon_indices.push(first + 1);
                etalon_indices.push(second + 1);
                etalon_indices.push(second);
                etalon_indices.push(first + 1);
                etalon_indices.push(second);
                etalon_indices.push(first);
            }
        }
        var etalon_indices_length = etalon_indices.length;
        
        /////////////////////////////////////////////
        /// replicate

        for (var i=0, qq=0; i<spheres_positions.length; i+=3,qq++) {
          var xx = spheres_positions[i+0];
          var yy = spheres_positions[i+1];
          var zz = spheres_positions[i+2];
          
          //var radius2 = spheres.radiuses && spheres.radiuses.length > qq ? spheres.radiuses[qq] : spheres.radius;
          //var radius2 = spheres_radiuses && spheres_radiuses.length > qq ? spheres_radiuses[qq] : rr;
          // console.log(spheres.radiuses && spheres.radiuses.length,radius2,qq);
          let radius2 = radfunc( qq );

          var istart = positions.length /3;

          for (var e=0; e<etalon_length; e++) {
            var ee = etalon[e];

                normals.push(ee[0]);
                normals.push(ee[1]);
                normals.push(ee[2]);
                //uvs.push(ee[3]);
                //uvs.push(ee[4]);
                
                positions.push(radius2 * ee[0]+xx);
                positions.push(radius2 * ee[1]+yy);
                positions.push(radius2 * ee[2]+zz);

             if (spheres_colors) {
                  colors.push( spheres_colors[3*i/3] ); 
                  colors.push( spheres_colors[3*i/3+1] ); 
                  colors.push( spheres_colors[3*i/3+2] ); 
                  //if ($driver.colors == 4)
                    //colors.push( spheres_colors[4*i/3+3] );
             }
          }

          for (var u=0; u<etalon_indices_length; u++) 
            indices.push( etalon_indices[u] + istart );
        
        } // for var i

        //console.log([ positions, normals, uvs, indices, colors ]);
        // console.log("spheres complete ******************* spheres.positions.length=",spheres.positions.length, " generated positions.length=",positions.length);
        return [ positions, normals, uvs, indices, colors ];
    }			
  }` @s->nx @s->ny @s->positions @s->radiuses @s->colors @s->radius;
};