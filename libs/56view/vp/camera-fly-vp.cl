/*
  по камере - надо отдельный наборщик а отделно вычислитель
  чтоббы между ними воткнуть безье
  можно было.
  ну и рисователь - и того и сего
  плюс идея перейти на df - там у нас и парсер будет и.

  * перейти на df - done
    - arr хранится в df
    - парсинг df-средствами

  * drag drop точек
    https://stackoverflow.com/questions/49318245/threejs-drag-points

*/

feature "camera-fly-vp" {
	avp: visual_process
	title="Полет камеры"
	scene3d={ node3d output=@scene->output }
	project=@..
	//trajectory=""
	
	gui={
		render-params @avp;
		render-params @te plashka; // редактор траекторий
		render-params @cc plashka; // вычислитель положения
		render-params @liness plashka; // рисователь линии
		// avp filters={ params-hide list="title"; params-priority list="add-current";}
	}
	gui3={
		//render-params-list object=@avp;
		render-params @avp;
	}
	{{ x-param-objref-3 name="camera" values=(@avp->project | geta "cameras") }}
	{
		scene: node3d {
			liness: linestrips input=@te->output color=[0,1,0] visible=false;
			//get_param_option @liness/lines-env

			/*
			text3d input=(@te->output | df_set TEXT="->TIME_DELTA") 
			       size=1.05 visible=@liness->visible;
			*/       
		};

		te: trajectory_editor 
		      {{ x-set-params 
		      	    input_position=@avp.camera.pos
		            input_look_at=@avp.camera.center
		      }}
		      trajectory=@avp->trajectory?
		      ;
		cc: camera_computer_splines input=@te->output 
		      {{ x-set-params time=@te->recommended_time?; }}; // обновляем положение когда аппендят новую точку к траектории

    let traj_not_empty=((@te.output? | geta "length" default=0) > 0);
    //console-log "@traj_not_empty=" @traj_not_empty "oo=" @te.output?;

		    if (@avp->visible and @traj_not_empty) then={
			   	 x-modify input=@avp->camera {
			   	 	 x-set-params pos=@cc->output_position center=@cc->output_look_at;
			   	 };
			  };

	}
  ;
	
};

// редактор текста а на выходе dataframe
// в тексте должны быть и колонки
feature "df_editor" {
	dfe: {{ x-param-text name="input" }}
	  output=(@dfe->input | parse_csv);
};

//  input_position, input_look_at - текущее положение камеры, используется для добавления
//  add-current - команда на добавление текущей позиции в список
//  trajectory - текстовая запись траектории
//  output = df с траекторией
feature "trajectory_editor" {
  
	avpc: df56
	{{

	  //x-param-option name="add-current" option="priority" value=10;
	  
    x-add-cmd 
      name="add-current" 
      code=(m-apply `(tenv) => {
      	let cp = tenv.params.input_position;
      	if (cp.split) cp = cp.split(/[\s,]+/);
      	let cla = tenv.params.input_look_at;
      	if (cla.split) cla = cla.split(/[\s,]+/);
      	if (cp.length < 3 || cla.length < 3) return;
      	
      	var str = "100," + cp.map( v => v.toString() ).join(",") + "," + cla.map( v => v.toString() ).join(",");

				if (tenv.params.trajectory) str = tenv.params.trajectory + "\\n" + str;

        tenv.setParam( "trajectory", str, true );

        // шоб не прыгало
        //tenv.emit( "user_added_new",tenv.params.trajectory_time_len + 100)
        if (isFinite(tenv.params.trajectory_time_len))
        {
        	console.log('setting new recommended time',tenv.params.trajectory_time_len + 100)
        	tenv.setParam( "recommended_time", tenv.params.trajectory_time_len + 100);
        } else
          console.error('camera-fly-vp: tenv.params.trajectory_time_len is nan',tenv.params.trajectory_time_len)

    	}` @avpc);

    x-add-cmd 
      name="start_new" 
      code=(m_lambda `(tenv) => {
        tenv.setParam( "trajectory",'', true );
            tenv.callCmd("add-current");
    	}` @avpc);
    x-param-option name="start_new" option="priority"	value=10; // подальше убрать ее

    x-param-text name="trajectory";
    x-param-option name="trajectory" option="hint" value="Введите матрицу траектории движения камеры. Каждая строка это числа TIME_DELTA,X,Y,Z,LOOKAT_X,LOOKAT_Y,LOOKAT_Z";
    
    x-param-vector name="input_position";
    x-param-vector name="input_look_at";

	}}
	//default_trajectory="TIME_DELTA,X,Y,Z,LOOKAT_X,LOOKAT_Y,LOOKAT_Z"
	//trajectory=@.->default_trajectory
	trajectory = ""
	
	trajectory_time_len=(m_eval (max_time) @avpc->output)
	output=(
		     ("TIME_DELTA,X,Y,Z,LOOKAT_X,LOOKAT_Y,LOOKAT_Z\n" + @avpc->trajectory?)
		     | parse_csv)
	;
};

// вычислитель положения камеры
// параметры - 
//  input - df с траекторией
//  time - время
//  output_position, output_look_at - выходное
feature "camera_computer" {
	avpco: 
	{{ 
    x-param-slider name="time" max=@avpco->trajectory_time_len;
    x-param-vector name="output_position";
    x-param-string name="output_look_at" ;
    x-param-vector name="output_position" option="readonly" value=true;
    x-param-option name="output_look_at" option="readonly" value=true;
	}}
	time=0
	trajectory_time_len=( (m_eval (max_time) @avpco->input) or 0)
	current_result=(m_eval @avpco->compute_current @avpco->input @avpco->time)
	output_position=(m_eval "(arr) => arr.slice(1,1+3)" @avpco->current_result)
	output_look_at=(m_eval "(arr) => arr.slice(4,4+3)" @avpco->current_result)

  compute_current=(m_js `(res,time) => {
//  	console.log('compute-current called, time is ',res,time)
  	let t = 0;
  	//debugger
  	let col = res["TIME_DELTA"];
    for (var i=1; i<col.length; i++) {
      if (time >= t && time <= t+col[i]) {
        var w = (time - t) / col[i];
        return interp_arr( res.get_rows(i-1), res.get_rows(i), w );
        //res.slice( i ).interp_with( res.slice(i+1 )) );
      }
      t += col[i];
    }
    //return res[ res.length -1 ];
    return res.get_rows( res.length-1 );

		function interp_arr( arr1, arr2, w ) {
			//console.log(arr1,arr2,w)
		  if (!arr1) return []; // ну так вот странно пока
		  if (!arr2) arr2=arr1;
		  if (arr1 === arr2) return arr1;
		  
		  if (typeof(arr1[0]) == "string" || typeof(arr2[0]) == "string") return arr1;
		  
		  const count = arr1.length;
		  var acc = new Float32Array( count ); 
		  for (var i=0; i<count; i++) {
		      acc[i] = arr1[i] + w * (arr2[i] - arr1[i]);
		  }
		  return acc;
		}

  }`)
  ;
	
};

feature "max_time" {
  m_js `(df) => {

  	if (!df) return 0;
  	let t = 0;
  	let col = df["TIME_DELTA"] || [];
  	
    for (var i=1; i<col.length; i++) {
    	t += col[i];
    }
    //console.log("max_time",df,t)
    return t;
  }`;
};


// вычислитель положения камеры сплайнами
// параметры - 
//  input - df с траекторией
//  time - время
//  output_position, output_look_at - выходное
feature "camera_computer_splines" {
	avpco: 
	{{ 
    x-param-slider name="time" max=@avpco->trajectory_time_len;
    x-param-vector name="output_position";
    x-param-vector name="output_look_at" ;
    x-param-option name="output_position" option="readonly" value=true;
    x-param-option name="output_look_at" option="readonly" value=true;
	}}
	time=0
	trajectory_time_len=(m_eval (max_time) @avpco->input)
	current_t=(m_eval @avpco->compute_current_t @avpco->input @avpco->time)

	output_position=(compute_curve input=(df_combine input=@avpco->input columns=["X","Y","Z"]) t=@avpco->current_t )
	output_look_at=(compute_curve input=(df_combine input=@avpco->input columns=["LOOKAT_X","LOOKAT_Y","LOOKAT_Z"]) t=@avpco->current_t )

  // приведение time к отрезку 0..1
  compute_current_t=(m_js `(res,time) => {
  	let t = 0;
  	let col = res["TIME_DELTA"] || [];
  	let w = 0;
  	let ii = -1;
    for (var i=1; i<col.length; i++) {
      if (time >= t && time <= t+col[i]) {
        w = (time - t) / col[i];
        return w / (col.length-1) + (i-1) / (col.length-1);
      }
      t += col[i];
    }
    return 1;
  }`)
  ;
	
};