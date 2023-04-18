coview-category title="ЗАЛ" id="zal" ~primary-cat ~toplevel-cat

group {
  coview-record title="Геометрия зала" type="zal-geom"
  coview-record title="Радиация" type="zal-rad"
  coview-record title="Путь обхода" type="zal-path"
  coview-record title="Настройка слоя" type="zal-conf"
} | assign-params (dict cat_id="zal")


feature "zal-geom" {
  p: visual_process title="Геометрия зала" 
  {
      param-info "geometry_text" out=true in=true ""
      gui {
        gui-tab "main" {
          gui-slot @p "geometry_text" gui={ |in out| gui-text @in @out }
        }
      }
      let geom = (read @p.geometry_text | compalang)
      insert_children list=@geom input=@zal      

      zal: node3d ~layer-object title="Геометрия зала" 
      { // среда для моделирования, world -- update а ведь нет, теперь это сцена

        // история про зеркальность по одной из оси..
        // попробовать на уровне слоя..
        
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
            color=[0,0,1] radius=2
        



          let measuring_points_recs = (find-objects-bf "MeasuringPoint" root=@zal depth=1)   
          let vertices_recs = (find-objects-bf "Vertex" root=@zal depth=1)

          dasdata: object title="Данные"
            measuring_points=(df-create length=@measuring_points_recs.length
                 | df-set 
                 X=(read @measuring_points_recs | map_geta 0) 
                 Y=10
                 Z=(read @measuring_points_recs | map_geta 1)
                 VALUE=(read @measuring_points_recs | map_geta 2)
                 RADIUS=(read @measuring_points_recs | map_geta 2 | map_geta {: x | return 10*Math.max( 1, Math.sqrt(x) ) :})
                 TITLE=(read @measuring_points_recs | map_geta {: rec | return "mp "+rec.params[0] + " "+rec.params[1] + " " + rec.params[2] :})
                 | df-mul X=10 Z=10
              )
            vertices=(df-create length=@measuring_points_recs.length
                 | df-set 
                 X=(read @measuring_points_recs | map_geta 0) 
                 Y=10
                 Z=(read @measuring_points_recs | map_geta 1)
                 RADIUS=10
                 TITLE=(read @measuring_points_recs | map_geta {: rec | return "vertex "+rec.params[0] + " "+rec.params[1] :})
                 | df-mul X=10 Z=10
              )
            {
              param-info "measuring_points" out=true
              param-info "vertices" out=true
            }

          measuring_points: cv-spheres title="MeasuringPoints"
            input=@dasdata.measuring_points
            color=[1,0,0] radius=1 opacity=0.2
            {
              cv_df_filter_bynum input=@dasdata.measuring_points
            }            

          vertices_points: cv-spheres title="Vertex"
            input=@dasdata.vertices
            color=[0,0,1] radius=1 opacity=0.2  
            {
              cv_df_filter_bynum input=@dasdata.measuring_points
            }

          ObstaclesLayer title="Obstacles"  

        }      

  }
}

feature "zal-rad" {
  p: visual_process title="Радиация" 
  {
      param-info "radiation_text" out=true in=true ""
      gui {
        gui-tab "main" {
          gui-slot @p "radiation_text" gui={ |in out| gui-text @in @out }
        }
      }
      let rad = (read @p.radiation_text | text2arr)
    //ето радиация
      radpts: cv-points title="Радиация"
         positions=(generate_grid_positions_pt rangex=@g.rangex rangey=@g.rangey stepx=@g.stepx stepy=@g.stepy) 
         colors=(arr_to_colors input=(@rad or []) base_color=[1,0,0])
         radius=0.15      

  }
}

feature "zal-path" {
  p: visual_process title="Путь обхода" 
  {
      param-info "trajectory_text" out=true in=true ""
      gui {
        gui-tab "main" {
          gui-slot @p "trajectory_text" gui={ |in out| gui-text @in @out }
        }
      }

     let trajectory=(read @p.trajectory_text | parse_trajectory)

     traj_optimal: cv-points title="Траектория - вершины" 
              input=@trajectory radius=15 color=[0,1,0]

     traj_optimal_t: cv-cylinders title="Траектория" 
              input=@trajectory radius=2 color=[0,0.5,0]                  

  }
}

feature "zal-conf" {
    p: visual_process title="Настройка слоя" 
    {      
      insert_children list={ 
          addon-map-control // добавим слою управление как карта
          addon-camera-center // центровку камер
          effect3d-scale z=-1 
          } 
          input=(read @p | get_parent)

        /*
        m-eval {: obj=(read @p | get_parent | geta "output") |
          let r = 1.0
          obj.scale.set( r,r,-r )
        :}*/
    }
}


feature "parse_trajectory" {
  x: object output=(
     parse_csv input=("X Z WHAT\n" + @x.input) separator="\s+"
     | df_filter {: df index | return df.WHAT[index] == "a" :}
     |
     df_set Y=0
  )
}

coview-record title="Подписи" type="callouts" cat_id="gr3d"

// input - df который следует показать. X,Y,Z, TITLE
//         либо я еще думал про набор объектов которые следует показать. но вроде как я теперь говорю что данные у нас df универсальные
//         но либо сразу требовать X,Y,Z, X2,Y2,Z2, TITLE ? но их нет во входных данных..
// delta - смещение для палочки в форме [x,y,z]
// todo переделать нутрянку на input=df.. тогда она мб подтянет цвет..
feature "callouts" {
  x: layer_object ~node3d delta=[0,1000,0] title="Подписи" input=null  radius=1000 size=30 {
    
    read @x.input | df_to_lines | repeater { |item|
      node3d {
        lines positions=(list @item.X @item.Y @item.Z (@item.X + @x.delta.0) (@item.Y + @x.delta.1) (@item.Z+@x.delta.2))
         { effect3d-disable-clicks  }
        //read @item | df_set X2={: df i | return df.X[i]+}
        //read @item | df_set X2="->X" Y2="->Y" Z2="->Z" | df-add X2=@x.delta.0 Y2=@x.delta.1 Z2=@x.delta.2 | lines
        let txt=(or @item.TITLE @item.TEXT @item.VALUE ":-]")
        //console-log "txt=" @txt
        //console-log "item=" @item
        ttt: text_sprite_one position=(list (@item.X + @x.delta.0) (@item.Y + @x.delta.1) (@item.Z+@x.delta.2)) 
           //text="privet"
           text=@txt radius=@x.radius size=@x.size
           { effect3d-disable-clicks  }
       
      }
    }
  
    param-info "input" in=true output=true
    gui debug=true {
      gui-tab "main" {
        gui-slot @x "input" gui={ |in out| gui-df @in @out }
        gui-slot @x "delta" gui={ |in out| gui-vector @in @out }
        gui-slot @x "radius" gui={ |in out| gui-float @in @out }
        gui-slot @x "size" gui={ |in out| gui-float @in @out }
      }
    }
  }
}

///////////////////////////////////////////////
///////////////////////////////////////////////
///////////////// для парсинга out-файла

feature "MeasuringPoint" {
  x: object pos=(list (10 * @x->0) 10 (10 * @x->1)) 
        title=(+ "mp " @x.0 " " @x.1 " " @x.2)
}

feature "measuringPoint" {
  MeasuringPoint
}

// это видимо где надо провести замеры
feature "Vertex" {
  x: object {  } 
}

feature "DrawObstacled"
feature "Speed"
feature "RandomPathsCount"
feature "RangeDose"
feature "RandSeed"


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

// todo это как бы как особая форма..
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

// todo странная это вещь - ее надо бы в отдельное утащить ++ разделить (генератор, рисователь)
// параметры: rangex, rangey, stepx, stepy
feature "grid" {
  x: cylinders color=[0, 0, 0.5] //color=[0, 0.5, 0]
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

///////////////////////////////

// это кстати ваще другое, другой грид
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