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
		render-params @cf plashka;
		// avp filters={ params-hide list="title"; params-priority list="add-current";}
	}
	gui3={
		render-params-list object=@avp;
	}
	{
		cf: camera-fly 
		      input_position=(@avp->current_view | geta "camera" | geta "pos")
		      input_look_at=(@avp->current_view | geta "camera" | geta "center")
		    {
		    	 if (@avp->visible) then={
			    	 x-modify input=(@avp->current_view | geta "camera") {
			    	 	 x-set-params pos=@cf->output_position center=@cf->output_look_at;
			    	 }
			     };	 
		    };
	}
  ;
	
};

feature "df_editor" {
};


//  current_position, current_look_at - текущее положение камеры, используется для добавления
//  add-current - команда на добавление текущей позиции в список
//  trajectory - текстовая запись траектории
//  output = массив с траекторией
feature "trajectory_editor" {
};

// input - массив с траекторией
feature "camera_computer" {
};


// редактор траектории камеры
// параметры - 
//  current_position, current_look_at - текущее положение камеры, используется для добавления
//  add-current - команда на добавление текущей позиции в список
//  trajectory - текстовая запись траектории
//  output_position, output_look_at - выходное
feature "camera-fly" {
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
        tenv.setParam( "time", tenv.params.trajectory_time_len + 100);

    	}` @avpc);

    x-add-cmd 
      name="reset" 
      code=(m-apply `(tenv) => {
        tenv.setParam( "trajectory", "", true );
        //tenv.call
    	}` @avpc);    	

    x-param-slider name="time" max=@avpc->trajectory_time_len;
    x-param-text name="trajectory";
    
    x-param-string name="input_position";
    x-param-string name="input_look_at";

    x-param-string name="output_position";
    x-param-string name="output_look_at";
	}}
	trajectory="# Формат строк: временной интревал задержки, x,y,z, look-at-x,look-at-y, look-at-z"
	time=0
	trajectory_time_len=(m_eval (max_time) @avpc->trajectory_arr)
	trajectory_arr=(m_eval @avpc->trajectory_to_arr @avpc->trajectory)

	current_result=(m_eval @avpc->compute_current @avpc->trajectory_arr @avpc->time)
	output_position=(m_eval "(arr) => arr.slice(1,1+3)" @avpc->current_result)
	output_look_at=(m_eval "(arr) => arr.slice(4,4+3)" @avpc->current_result)

	{{ console_log_params }}
	// возвращает по строке массив с программой
	trajectory_to_arr=(m_js `(str) => {
		 let acc = [];
		 
		 str.split("\n").forEach( s => {
       s = s.split("#")[0];
       if (s.length == 0) return;
       s = s.split(/[\s,]+/);
       if (s.length < 7) return;
       acc.push( s.map(parseFloat) );
		 	});
		 return acc;
	}`)

  compute_current=(m_js `(res,time) => {
  	let t = 0;
  	//debugger
    for (var i=0; i<res.length-1; i++) {
      if (time >= t && time <= t+res[i+1][0]) {
        var w = (time - t) / res[i+1][0];
        return interp_arr( res[i], res[i+1], w );
      }
      t += res[i][0];
    }
    return res[ res.length -1 ];

		function interp_arr( arr1, arr2, w ) {
			console.log(arr1,arr2,w)
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

	{
		//m_eval "" @avpc->trajectory_arr @avpc->time;
	}
  ;
	
};

feature "max_time" {
  m_js `(arr) => {
  	if (!arr) return 0;
  	let t = 0;
    for (var i=0; i<arr.length-1; i++) {
    	t += arr[i][0];
    }
    return t;
  }`;
};
