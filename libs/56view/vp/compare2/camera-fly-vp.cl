/*
  по камере - надо отдельный наборщик а отделно вычислитель
  чтоббы между ними воткнуть безье
  можно было.
  ну и рисователь - и того и сего
  плюс идея перейти на df - там у нас и парсер будет и.

  * перейти на df
    - arr хранится в df
    - парсинг df-средствами

*/

feature "camera-fly-vp" {
	avp: visual_process
	title="Полет камеры"
	gui={
		render-params @te plashka;
		render-params @cc plashka;
		// avp filters={ params-hide list="title"; params-priority list="add-current";}
	}
	gui3={
		render-params-list object=@avp;
	}
	{
		te: trajectory_editor 
		      input_position=(@avp->current_view | geta "camera" | geta "pos")
		      input_look_at=(@avp->current_view | geta "camera" | geta "center")
		      ;
		cc: camera_computer input=@te->output 
		      {{ x-set-params time=@te->recommended_time?; }}; // обновляем положение когда аппендят новую точку к траектории

		    if (@avp->visible) then={
			   	 x-modify input=(@avp->current_view | geta "camera") {
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
  
	avpc: 
	{{ 
	  
    x-add-cmd 
      name="add-current" 
      code=(m-apply `(tenv) => {
      	let cp = tenv.params.input_position;
      	if (cp.split) cp = cp.split(/[\s,]+/);
      	let cla = tenv.params.input_look_at;
      	if (cla.split) cla = cla.split(/[\s,]+/);
      	var str = "100," + cp.map( v => v.toString() ).join(",") + "," + cla.map( v => v.toString() ).join(",");

        tenv.setParam( "trajectory", tenv.params.trajectory + "\n" + str, true );
        // шоб не прыгало
        tenv.emit( "user_added_new",tenv.params.trajectory_time_len + 100)
        console.log('setting new recommended time',tenv.params.trajectory_time_len + 100)
        tenv.setParam( "recommended_time", tenv.params.trajectory_time_len + 100);

    	}` @avpc);

    x-add-cmd 
      name="restart" 
      code=(m-apply `(tenv) => {
        tenv.setParam( "trajectory", 
        	  tenv.params.default_trajectory, true );
            tenv.callCmd("add-current");
    	}` @avpc);    	

    x-param-text name="trajectory";
    
    x-param-string name="input_position";
    x-param-string name="input_look_at";

	}}
	default_trajectory="TIME_DELTA,X,Y,Z,LOOKAT_X,LOOKAT_Y,LOOKAT_Z"
	trajectory=@.->default_trajectory
	
	trajectory_time_len=(m_eval (max_time) @avpc->output)
	output=(@avpc->trajectory | parse_csv)
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
    x-param-string name="output_position";
    x-param-string name="output_look_at";
	}}
	time=0
	trajectory_time_len=(m_eval (max_time) @avpco->input)
	current_result=(m_eval @avpco->compute_current @avpco->input @avpco->time)
	output_position=(m_eval "(arr) => arr.slice(1,1+3)" @avpco->current_result)
	output_look_at=(m_eval "(arr) => arr.slice(4,4+3)" @avpco->current_result)

  compute_current=(m_js `(res,time) => {
//  	console.log('compute-current called, time is ',res,time)
  	let t = 0;
  	//debugger
  	let col = res["TIME_DELTA"] || [];
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
    return t;
  }`;
};
