coview-record title="Визуализация зала" type="zal" cat_id="process"

feature "zal" {
    p: visual_process title="Визуализация зала" {

      gui {
        gui-tab "main" {
          //m: slider
          // gui-slot @p "count" gui={ |in out| gui-slider @in @out }
          //gui-slot @p "radius" gui={ |in out| gui-slider @in @out }
        }
      }

      // добавим управление как карта
      insert_children list={ addon-map-control } input=(read @p | get_parent)

      f_select: cv-select-files
      //f_text: load-text input=@f_select.first_file
      //let geom = (read @f_text.output | compalang)
      let geom = (read @f_select.output | find-file "^data\.txt$"| load-file | compalang)
      let rad = (read @f_select.output | find-file "rad.*\.csv$"| load-file | text2arr)
      let trajectories=(@f_select.output | find-file ".*\.out$" | load-file | xtract_trajs)

      insert_children list=@geom input=@zal

      console-log "zal is" @zal

      zal: node3d ~layer-object title="Геометрия зала" { // среда для моделирования, world -- update а ведь нет, теперь это сцена

        
          g: grid // ну это рисование сетки
            rangex=((find-objects-bf "RangeX" root=@zal | geta 0 | geta 1) or 0)
            rangey=((find-objects-bf "RangeY" root=@zal | geta 0 | geta 1) or 0)
            stepx=((find-objects-bf "GridStep" root=@zal | geta 0 | geta 0) or 1)
            stepy=((find-objects-bf "GridStep" root=@zal | geta 0 | geta 1) or 1)
            //gridstep=(find-objects-bf "GridStep" root=@zal | geta 0 | m-eval {: obj | obj ? [obj.params[0], obj.params[1]] : [100,100] :} )
            opacity=0.3
            visible=false

          //console-log "@g.rangex=" @g.rangex

          //grid rangex=@g.rangex rangey=@g.rangey gridstep=m-eval [[[ (arr=@g.gridstep) => [ arr[0]*100, arr[1]*100 ] ]]]
          // надо сделать их тупо независимыми
          g2: grid rangex=@g.rangex rangey=@g.rangey //gridstep=(m-eval {: arr | [ arr[0]*100, arr[1]*100 ] :} @g.gridstep)
            stepx=(@g.stepx * 100) stepy=(@g.stepy * 100)
            color=[0,1,0] radius=2

          traj_optimal: cv-cylinders positions=(read @trajectories.0 | make-strip) radius=10 color=[0,1,1]

        //ето радиация
          radpts: cv-points title="Расчёты поля"
             positions=(generate_grid_positions_pt rangex=@g.rangex rangey=@g.rangey stepx=@g.stepx stepy=@g.stepy) 
             colors=(arr_to_colors input=(@rad or []) base_color=[1,0,0])
             radius=0.15

          
          //m-eval {: obj=@traj_optimal.output |  let r = 10; obj.scale.set( r,r,r ) :}

          //console-log "QQQQ=" @pz.input.trajectories.0

             //console-log "A1=" @radpts.positions "A2=" @radpts.colors "a3=" @pz.input.rad

          measuring_points: cv-spheres title="MeasuringPoints"
            positions=(find-objects-bf "MeasuringPoint" root=@zal | map { |x| list (10 * @x.0) 0 (10 * @x.1) } | arr_flat)
            //positions=(find-objects-bf "MeasuringPoint" root=@zal | map-geta "pos" | arr_flat) 
            color=[1,0,0] radius=30 opacity=0.2

          vertex: cv-spheres title="Vertex"
            positions=(find-objects-bf "Vertex" root=@zal | map { |x| list (0 + (10 * @x.0)) 0 (10 * @x.1) } | arr_flat)
            color=[0,0,1] radius=30 opacity=0.2   

          ObstaclesLayer title="Obstacles"  

        }       

    }  
}

///////////////// для парсинга out-файла


feature "MeasuringPoint" {
  x: object //pos=(list (10 * @x->0) 10 (10 * @x->1)) {
//     node: node3d {
//       spheres positions=(list @x->0 0 @x->1) color=[1,0,0] radius=30 opacity=0.2
       //m-eval {: obj=@node.output | let r = 10; obj.scale.set( r,r,r ) :}   
//     }
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
       //m-eval {: obj=@node.output | let r = 10; obj.scale.set( r,r,r ) :}

       //m-eval {: obj=@n.output | obj.position.set( 30,0,0 ) :}
     //}
  } 
}

feature "DrawObstacled"
feature "Speed"
feature "RandomPathsCount"
feature "RangeDose"
feature "RandSeed"

/*
feature "ObstacleCircle" {
  x: node3d {
       cyl: cylinders nx=100 positions=(list @x->0 0 @x->1 @x->0 500 @x->1) color=[1,1,1] radius=@x->2   
     }
}*/

feature "ObstacleCircle" {
  x: object positions=(list @x->0 0 @x->1 @x->0 500 @x->1) color=[1,1,1] radius=@x->2   
}

feature "ObstacleCircleLayer" {
  x: cv-mesh {{ let nodes=(find-objects-bf "ObstacleCircle" root=(read @x | get_parent)) }}
      positions = (read @nodes | map_geta "positions" | arr_concat)
}

// слой геометрии - соединяет всех
// но вообще.. не помешало бы умение.. просто выделить всех.. или.. навесить модификатор на группу..
feature "ObstaclesLayer" {
  x: cv-mesh {{ let nodes=(find-objects-bf "ObstaclePolyStart" root=(read @x | get_parent)) }}
      positions = (read @nodes | map_geta "positions" | arr_concat)
}

feature "ObstaclePolyStart" {
  x: object {{ let nodes=(find-objects-bf "ObstaclePolyPoint" root=@x) }}
      positions=(m-eval {: nodes=@nodes |
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

feature "RangeX" { object }
feature "RangeY" { object }
feature "GridStep" { object }

//////////////////////////

// параметры: rangex, rangey, stepx, stepy
feature "grid" {
  x: cylinders color=[0, 0.5, 0]
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
    :} @x.rangex @x.rangey @x.stepx @x.stepy )
}

// параметры rangex rangey dx dy
// output - массив координат
feature "generate_grid_positions_pt" {
  x: object output=(m-eval {: x=@x.rangex y=@x.rangey dx=@x.stepx dy=@x.stepy |
          let acc=[];
          
          for (let i=0; i<=x; i+=dx)          
          for (let j=0; j<=y; j+=dy) 
          {
            acc.push( i, 0, j );
          };
          return acc
  :})
}

///////////////////////////////
jsfunc "text2arr" {: str |
      let r = str.split(/[\s,;]+/);
      if (r.length > 0 && r[ r.length-1].length == 0) r.pop();
      r = r.map( parseFloat )
      //if (isNaN(r[ r.length-1])) r.pop(); // последнее лишнее
      return r
:}

jsfunc "xtract_trajs" {: str |
      let res = []
      let lines = str.split("\n");
      //console.log("looking trajs, str",lines)
      for (let i=0; i<lines.length; i++) {
        if (lines[i].match(/from first vertex to last vertex/)) {
           // стало быть внутри набор
          let j = i;
          //console.log( "found traj set", lines[j] );

          i++;
          //debugger
          
          for (; i<lines.length; i++) 
            if (lines[i].match(/From \(\d+, \d+\) to \(\d+, \d+\), cost/)) {
              let traj = [];
              let add;
              //console.log( "found traj", lines[j],lines[i])
              i++
              for (; i<lines.length; i++) {
                add = lines[i].match(/vertex \((\d+), (\d+)\)/)
                if (!add) { i--; break }
                //console.log("adding",add)
                traj.push( 10*parseFloat(add[1]), 0, 10*parseFloat(add[2]) )
              }
              traj.title = lines[j];
              res.push( traj )
              
              //console.log(traj)
            }
            else break;

        }
      }

      //console.log("res=",res)
      return res // набор траекторий
  :}