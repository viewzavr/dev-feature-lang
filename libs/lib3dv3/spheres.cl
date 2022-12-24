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


/////////////////////////////////////

feature "cylinders" {
  s: node3d 
    ~points_df_input 
    {{ x-param-slider name="radius" min=0.0 max=100 step=0.1 }}
    nx=16 positions=[] radiuses=[] colors=[] radius=1
    color=[1,1,1]
    {
        //mesh positions=[0,0,0, 1,1,1, 0,1,0 ];

    m: mesh positions=(@mdata.output.0)
             indices=(@mdata.output.1)
             colors=(@mdata.output.2)
             color=@s->color
             ~editable-addons // временно
             ;
    
    mdata: m_eval @makeCylinders @s.radius @s.radiuses @s.nx @s.positions @s.colors

    //console-log "makeCylinders=" @makeCylinders

    //mdata: m_eval (m-partial @s.radius @s.radiuses @s.nx @s.positions @s.colors @makeCylinders)

// see https://bitbucket.org/pavelvasev/scheme2/src/tip/scheme2go/libs/suffixes/trimesher/meshcreator.cs?at=default&fileviewer=file-view-default
      // aka 

    let makeCylinders = [[[ 
////////////////////////////////////////////////////////////////////////////////

    // http://rosettacode.org/wiki/Vector_products#JavaScript
    function crossProduct(a, b) {
      return [a[1]*b[2] - a[2]*b[1],
              a[2]*b[0] - a[0]*b[2],
              a[0]*b[1] - a[1]*b[0]];
    }
    
    function diff(p1,p2) {
      return [ p1[0]-p2[0], p1[1]-p2[1],p1[2]-p2[2] ];
    }

    function vDiff(p1,p2) {
      return [ p1[0]-p2[0], p1[1]-p2[1],p1[2]-p2[2] ];
    }

    function vAdd(p1,p2) {
      return [ p1[0]+p2[0], p1[1]+p2[1],p1[2]+p2[2] ];
    }
    
    function dotProduct(a,b) {
      return a[0]*b[0] + a[1]*b[1] + a[2]*b[2];
    }    

    // http://evanw.github.io/lightgl.js/docs/vector.html
    function vNorm(a) {
      var l = vLen( a );
      if (l > 0.00001)
        return vMulScal( a, 1.0 / l );
      return a;
    }
    function vNormSelf(a) {
      var l = vLen( a );
      if (l < 0.000001) return;
      a[0] /= l;
      a[1] /= l;
      a[2] /= l;
      return a;
    }

    function vLen(a) {
      return Math.sqrt(dotProduct(a,a));
    }

    function vMul(a,b) {
      return [ a[0]*b[0], a[1]*b[1], a[2]*b[2] ];
    }

    function vMulScal(a,b) {
      return [ a[0]*b, a[1]*b, a[2]*b ];
    }
    
    function vMulScalar(a,b) {
      return [ a[0]*b, a[1]*b, a[2]*b ];
    }    

    function vBasis( p1, p2 ) {
      var v1 = diff( p2, p1 ); 
      vNormSelf( v1 );
      var v2;
      if (Math.abs(v1[0]) < 0.0000001)
        v2 = [ 0, -v1[2], v1[1] ];
      else
        v2 = [ -v1[1], v1[0], 0 ];
      vNormSelf( v2 );

      var v3 = crossProduct( v1, v2 );
      return [ v1, v2, v3 ];
    }

    // use this? https://github.com/toji/gl-matrix/blob/master/src/gl-matrix/vec3.js

    function vLerp (a, b, t) {
      var ax = a[0],
          ay = a[1],
          az = a[2];
      var out = [0,0,0];
      out[0] = ax + t * (b[0] - ax);
      out[1] = ay + t * (b[1] - ay);
      out[2] = az + t * (b[2] - az);
      return out;
    };

  function makeCylinders( radius, radiuses, nx, positions, colors, endRatio ) {
        var circle = [];
        var delta = 2.0 * Math.PI / nx;

        // cache
        for (var i=0; i<=nx; i++) {
          var alpha = i*delta;
          u1 = Math.cos(alpha);
          w1 = Math.sin(alpha);
          circle.push( [ u1,w1 ] );
        }

        var inds = [];
        var poss = [];
        var cols = [];

        // vertices
        var conesCount = positions.length / 6;
        // debugger;

        var vinring = nx+1;
        var conn = false ///connect;

        for (var q=0; q<conesCount; q++) {
          var s1 = 2*3*q;
          var s2 = s1+3;
          var p1 = [ positions[s1], positions[s1+1], positions[s1+2] ];
          var p2 = [ positions[s2], positions[s2+1], positions[s2+2] ];

          // Преобразуем p2 к доле endRatio
          if (endRatio)
            p2 = vLerp( p1, p2, endRatio );

          var basis = vBasis( p1, p2 );

          var color = null;
          if (Array.isArray(colors) && colors.length >= conesCount) {
            var y1 = 3*q;
            color = [ colors[ y1 ],colors[ y1+1 ], colors[ y1+2 ] ]
          }

          var startIndex = poss.length / 3;

          let r = radius;
          if (Array.isArray(radiuses) && radiuses.length > q) r = radiuses[q]

          for (var i=0; i<=nx; i++) {
            //coord[i, 0] = p1 + u1*v2 + w1*v3;
            //coord[i, 1] = p2 + u2*v2 + w2*v3;

            var u1 = circle[i][0]*r;
            var w1 = circle[i][1]*r;
            var dd = vAdd( vMulScal( basis[1], u1 ), vMulScal( basis[2], w1 ) );
            var nv1 = vAdd( p1, dd );
            var nv2 = vAdd( p2, dd );
            poss.push( nv1[0] ); poss.push( nv1[1] ); poss.push( nv1[2] );
            poss.push( nv2[0] ); poss.push( nv2[1] ); poss.push( nv2[2] );

            if (color) {
              cols.push( color[0] ); cols.push( color[1] ); cols.push( color[2] );
              cols.push( color[0] ); cols.push( color[1] ); cols.push( color[2] );
            }
          }
          
          // indices
          var vNext = poss.length / 3;
          for (var i=0; i<nx; i++) {
             var j = 2*i;
             inds.push( startIndex + j );
             inds.push( startIndex + j+1 );
             inds.push( startIndex + j+3 );

             inds.push( startIndex + j );
             inds.push( startIndex + j+3 );
             inds.push( startIndex + j+2 );

             if (conn && q<conesCount-1) {
               inds.push( startIndex + j+1 );
               inds.push( vNext + j );
               inds.push( vNext + j+2 );

               inds.push( startIndex + j+1 );
               inds.push( vNext + j+2 );
               inds.push( startIndex + j+3 );
             }
          }
        }

        

        return [ poss, inds, cols ];
      }

      makeCylinders

    ]]]
      
  };
};