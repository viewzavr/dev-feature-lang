// поиск одного объекта
// параметры
//   input - путь к объекту
//   root - от какого объекта отсчитывается путь
//   output - результат-объект или null
/*
feature "find-one-object" {
  e: output=? {{ 
  	  x-param-objref name="input" root=@e->root;
  	 }}
}
*/

feature "find-one-object" code=`
  env.onvalues_any(["input","root"],(i,r) => {
     stop_process();
     if (i && i[0] == "@") i = i.slice(1); // приведем к порядку - ссылки у нас внутрях без @ идут.
     start_process( i,r );
  })

  env.feature("delayed");
  let refind = { stop: ()=>{} };

  function start_process( path, root,retry=100 ) {
  	if (retry < 0) {
  		console.error("find-one-object: retry finished, obj not found",env.getPath(),"path",path,"root",root);
  		env.setParam("output",null);
  		return;
  	}
  	refind.stop();
  	if (!path) {
  		env.setParam("output",null);
  		return;
    };
    root ||= env.findRoot();

    var target_obj  = env.vz.find_by_path( root,path ); 
    if (target_obj) {
    	env.setParam("output",target_obj);
    }
    else {
    	// ну надо поиски начинать
    	refind = env.timeout( () => start_process( path, root,retry-1 ), 5 );
    	env.setParam("output",null);
    }
  }
  
  function stop_process() {
  	refind.stop();
  }
`;

// поиск массива объектов по путям
// вход - input - строка с путями объектов (разделитель ,)
//      - root - от какого объекта отсчитываются пути
// выход - output - массив найденных объектов. там где не найдено там null.
feature "find-objects-by-pathes" {
	ee: input=@.->0 
	    output=@m->output
	{
		eval @ee->input code="(p) => p.split(',').map(s => s.trim())"
		|
		r: repeater {
			find-one-object root=@ee->root;
		}
		|
		m: map_geta "output"		
		;
	};
};

// поиск массива объектов по критериям
// input - строка с критериями см ниже
//       - root - от какого объекта отсчитываются пути
// выход - output - массив найденных объектов. 
/*
   input это массив строк (разделитель ,) где каждая строка критерий
   [@путь] [фича1 фича2]

   будет поиск по всем критериям и их объединение
   если указан только путь то это один объект
   если указаны только фичи то это поиск объектов с всеми этими фичами
   если указан путь и фичи то это поиск в поддереве по пути ообъектов с фичами
*/

feature "find-objects-by-crit" {
	ee: input=@.->0 
	    output=@m->output
	    root=@/
	{
		eval @ee->input code="(p) => p.split(',').map(s => s.trim())"
		|
		r: repeater {
			q: {
				splitted: eval @q->input code="(str) => str.split(/\s+/)";
				//console_log "splitted test" @splitted->output (@splitted->output | geta 0);
				i: if ( (@splitted->output | geta 0 0) == "@") then={
					  //console_log "then inside --";
					  // then первый аргумент путь
						// вариант @путь-до-корня фича1 фича 2
						rt: find-one-object root=@ee->root input=(@splitted->output | geta 0);
						//bf: find-objects-bf root=@rt->output features=(@splitted->output | geta (i-call-js code="env.params.input.slice(1)"))
						//bf: find-objects-bf root=@rt->output features=(@splitted->output | geta (i-call "slice" 1))

						if ((@splitted->output | geta "length") > 1)
						then={ // есть фичи
							  //console_log "path and features found!";
							  bf: find-objects-bf root=@rt->output 
							         features=(@splitted->output | geta "slice" 1)
							         ;
							  link to="@q->output" from="@bf->output";
						}
						else={ // нету фичи в этом критерии
							link to="@q->output" from="@rt->output";
					  };
				  }
				  else={
				  	//console_log "else --";
	  				// else тупо фичи
						bf: find-objects-bf root=@ee->root features=@q->input;
						link to="@q->output" from="@bf->output";
				  };
			} // q
		} // рипитер
		//| console_log_input "after repeater"
		| // в итоге репитер выдает нам массив объектов в параметром .output
		map_geta "output" // где output это может быть объект или массив объектов или пустота
		//| console_log_input "after output fields join"
		| // получили серию значений возможно некоторые из них массивы - схлопнем
		geta "flat"
		|
		m: arr_compact;
	};
};

//if (eval @q->input code="(str) => str[0] == '@'")