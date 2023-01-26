load "set-params"

feature "css-style" {
  dom tag="style" dom_obj_type="text/css" dom_obj_textContent=@.->0;
};

register_feature name="button" {
	tb: dom tag="button" innerHTML=@.->text text=@.->0?
	~func 
	{{
		reaction (dom_event_cell @tb "click") (method @tb "apply")
		reaction (dom_event_cell @tb "click") (event @tb "click")
		//dom_event name="click" cmd="@tb->apply";
		//on_dom_event @tb "click" (m_lambda "(obj) => { obj.emit('click'); }" @tb);
	}};
};


register_feature name="text" {
	dom tag="span" innerHTML=@.->text? text=@.->0? {};
};

//
feature "file" {
	d: dom tag="input" dom_type="file" style="max-width:180px;" {
		reaction (dom-event-cell @d "change") {: event_data obj=@d |
			let files = event_data.target.files;
		  
		  obj.emit("user_change",files[0]);
		  obj.setParam("output",files[0],true);

			:}		
	}
}

feature "files" {
	d: dom tag="input" dom_type="file" dom_attr_multiple=true {
		reaction (dom-event-cell @d "change") {: event_data obj=@d |
			let files = event_data.target.files;
			let arr = [];
		  for (let i=0; i<files.length; i++)
		  	arr.push( files[i] );
		  
		  obj.emit("user_change",arr);
		  obj.setParam("output_value",arr,true);

			:}		
	}
}

///////////////////////////////////////////////////// checkbox
/* входы
     text - надпись
     value - значение true/false
   выходы
     value - значение true/false

   кстати вот вопрос, у меня везде value есть входное и выходное значение
   а не следует ли сделать их разными?.. если да то почему, если нет то почему?  
*/
register_feature name="checkbox" {
	cbr: dom tag="label" //value=true 
	    dom_style_whiteSpace="nowrap" // это важно чтобы чекбоксы не разрывались
	  {
		 cb: dom tag="input" dom_type="checkbox" dom_obj_checked=@..->value? {
			reaction (dom_event_cell @cb "change") {: event_data obj=@cbr |
				let v = event_data.target.checked;
				obj.setParam('output_value',v);
				obj.emit("user-changed",v)
				obj.emit("user_change",v)
				:}
			
		};
		text text=@..->text?;
	};
};

/*
register_feature name="checkbox-c" {
	dom tag="label" //value=true 
	    dom_style_whiteSpace="nowrap" // это важно чтобы чекбоксы не разрывались
	  {
		dom tag="input" dom_type="checkbox" dom_obj_checked=@..->value? {
			dom_event name="change" code=`
				var v = env.params.object.dom.checked;
				env.params.object.ns.parent.emit("user-changed",v);
			`;
		};
		text text=@..->text?;
	};
};
*/
///////////////////////////////////////////////////// input_float
/* входы
     value - начальное значение
   выходы
     value - выбираемое значение
*/
register_feature name="input_float" {
	d: dom tag="input" dom_obj_value=@.->value? {
		reaction (dom_event_cell @d "change") {: event_data obj=@d|
			  var v = parseFloat( event_data.target.value );
			  obj.emit("user_change",v);
		:}		
	};
};

////////////////////////////// input_string
register_feature name="input_string" {
	d:dom tag="input" dom_obj_value=@.->value? {
		reaction (dom_event_cell @d "change") {: event_data obj=@d|
			  var v = event_data.target.value;
			  obj.emit("user_change",v);
			  obj.setParam("output_value",v)
		:}
	};
};

///////////////////////////////////////////////////// input_vector
/* входы
     value - начальное значение
   выходы
     value - выбираемое значение
*/
register_feature name="input_vector" {
	dom tag="input" dom_obj_value=(m_eval "(v) => {
		  if (Array.isArray(v)) v=v.join(' ');
		  return v.toString();
		}" @dv->value?) {
		dom_event name="change" code=`
		    let s = env.params.object.dom.value.split( /[,\s]+/ );
		    let v = s.map( parseFloat );
				//var v = parseFloat( env.params.object.dom.value );
				env.params.object.setParam("value",v);;
			`;
	};
};

// выход - событие user-changed
register_feature name="input_vector_c" {
	dv: dom tag="input" dom_obj_value=(m_eval "(v) => {
		  if (Array.isArray(v)) v=v.join(' ');
		  return v ? v.toString() : null;
		}" @dv->value?) {
		dom_event name="change" code=`
		    let s = env.params.object.dom.value.split( /[,\s]+/ );
		    let v = s.map( parseFloat );
				//var v = parseFloat( env.params.object.dom.value );
				// console.log('emitting to',v )
				env.params.object.emit("user-changed",v);
				env.params.object.emit("user_change",v);
			`;
	};
};

// todo приделать кнопку ВВОД или типа того.. щас как-то оно не интуитивно
// todo приделать length или limit параметр и чтобы оно приводило к этому значению такой длины
feature "input_vector_c2" {
	dv: dom tag="textarea" rows=3 
	  dom_obj_rows=@.->rows
	  dom_obj_value=(m_eval {: v=@dv->value? |
		  if (Array.isArray(v)) v=v.join('\n');
		  return v ? v.toString() : null;
		:}) 
		{
	  reaction (dom_event_cell @dv "change") {: event_data obj=@dv |
	  	  let s = event_data.target.value.split( /[,\s]+/ );
		    let v = s.map( parseFloat );
				obj.emit("user-changed",v);
				obj.emit("user_change",v);
	  	:}
   	}
}

// ввод/отображение небольшого набора строк
feature "input_strings" {
	dv: dom tag="textarea" rows=3 
	  dom_obj_rows=@.->rows
		{
		reaction (param @dv "value") {: v tgt=(param @dv "dom_obj_value") |
		  //console.log("reaction!")
			if (Array.isArray(v)) v=v.join('\n');
		  let s = v ? v.toString() : null;
		  tgt.set(s)
		:}

	  reaction (dom_event_cell @dv "change") {: event_data obj=@dv |
	  	  let s = event_data.target.value.split( /[\n]/ );
		    let v = s;
				obj.emit("user_change",v);
				obj.setParam("output_value",v)
	  	:}
   	}
}

///////////////////////////////////////////////////// radio_button
/* входы
     text - надпись
     group_id - идентификатор группы
   выходы
     cmd - вызывается когда кликнули
*/
register_feature name="radio_button" {
	dom tag="label" 
	 //{{ dom-event-cell "click" | c-on @d->cmd }}
	{
		dom tag="input" dom_type="radio" dom_name=@..->group_id;
		text text=@..->text;
		dom_event object=@.. name="click" cmd=@..->cmd;
	};
};

///////////////////////////////////////////////////// slider
register_feature name="slider" {
	the_slider: dom tag="input" dom_type="range" 
	    min=0 max=100 step=1 value=0
	    manual=true
	    sliding=true 
	    {{
	    	 //add_cmd name="refresh_slider_pos" cmd="@r->apply; ";
	    	 // так то круто было бы в строчке cmd сделать несколько команд через ;
	    	 // но в целом тут уже напрашивается тупо императивный код для нашей машины...
	    	 // т.е. пусть @r->apply это вызов функции, все норм; но пусть будут и другие фукции..
	    	 // аля лисп. возможно. но и как-то это на процессный пересчет бы завернуть тоже...
	    	 // имеется ввиду вещи вида alfa=(beta | gamma | teta)

         add_cmd name="refresh_slider_pos" 
                 code="
                 //console.log('refreshing slider', env.host.params.value,env.host.dom.max);
                 env.host.dom.value = env.host.params.value;
                 // не канает потому что там и так сохраняется в кеше это значение
                 env.host.setParam('dom_obj_value', env.host.params.value)
                 ";

         // если мы садимся на max параметр то до dom еще не докатывается получается        
         on "param_dom_max_changed" cmd="..->refresh_slider_pos";
	    }}
	{
		/*
		 link from="..->min"   to="..->dom_min";
		 link from="..->max"   to="..->dom_max";
		 link from="..->step"  to="..->dom_step";
		 link from="..->value" to="..->dom_value";
		*/ 
		 setter value=@..->min target="..->dom_min" ~auto_apply;
		 setter value=@..->max target="..->dom_max" ~auto_apply;
		 setter value=@..->step target="..->dom_step" ~auto_apply;
		 r: setter value=@..->value target="..->dom_obj_value" ~auto_apply;

		 if (@the_slider->sliding) then={
			 @the_slider | dom_event_cell "input" | c_on `(event_data,valcell) => {
			 		let k = event_data;
			 		valcell.set( parseFloat( k.target.value ) )
			 }` (@the_slider | get_cell "value" manual=@the_slider->manual);
		 };

		 read @the_slider | dom_event_cell "change" | c_on `(event_data,valcell) => {
		 		let k = event_data;

		 		valcell.set( parseFloat( k.target.value ) )
		 }` (@the_slider | get_cell "value" manual=@the_slider->manual);

/* было

		 dom_event name="input" code=`
		  let object = env.params.object;
		  //console.log("slider input",object.params.dom.value)
		 	if (object.params.sliding) {
		 		  let v = parseFloat( object.params.dom.value );
		 		  //console.log("slider sets manual param 'value'",v)
		 		  object.setParam("value", v, object.params.manual );
		  }		  
		 `;

		 dom_event name="change" code=`
		   let object = env.params.object;
		   //console.log("slider change",object.params.dom.value) 
		 	  object.setParam("value", parseFloat( object.params.dom.value ), object.params.manual );
		 `;
*/		 

  };
};

///////////////////////////////////////////////////// slider
register_feature name="slider2" {
	the_slider: dom tag="input" dom_type="range" 
	    min=0 max=100 step=1 value=0
	    manual=true
	    sliding=true 
	    dom_min=@the_slider.min
	    dom_max=@the_slider.max
	    dom_step=@the_slider.step
	    dom_obj_value=@the_slider.value
	{
		reaction (param @the_slider "dom_max") {: the_slider=@the_slider | 
			  the_slider.dom.value = the_slider.params.value 
			  the_slider.setParam('dom_obj_value', the_slider.params.value)
			  :}

		 if @the_slider->sliding then={		 	  
			 read @the_slider | dom_event_cell "input" | reaction {: k tgt=(event @the_slider "user_change") |
			   tgt.set( parseFloat( k.target.value ) )
			 :}
		 }

		 read @the_slider | dom_event_cell "change" | reaction {: k tgt=(event @the_slider "user_change") |
			   tgt.set( parseFloat( k.target.value ) )
		 :}
  }
}


///////////////////////////////////////////////////// select_color

// вход, выход: value - значение в форме массива [r,g,b] (от 0 до 1)

register_feature name="select_color" {
  sc: dom tag="input" dom_type="color" {

    // value передаем в dom
    setter target="..->dom_value" value=@val2dom->output ~auto_apply;
    //link from="@val2dom->output" to="..->dom_value";
    val2dom: compute inp=@..->value code=`
      /// работа с цветом    
      // c число от 0 до 255
      function componentToHex(c) {
          if (typeof(c) === "undefined") {
            debugger;
          }
          var hex = c.toString(16);
          return hex.length == 1 ? "0" + hex : hex;
      }

      // r g b от 0 до 255
      function rgbToHex(r, g, b) {
          return "#" + componentToHex(r) + componentToHex(g) + componentToHex(b);
      }  

      // triarr массив из трех чисел 0..1
      function tri2hex( triarr ) {
         return rgbToHex( Math.floor(triarr[0]*255),Math.floor(triarr[1]*255),Math.floor(triarr[2]*255) )
      }
      
      if (Array.isArray(env.params.inp)) {
          let h=tri2hex( env.params.inp );
          env.setParam("output", h)
      }
      
    `;

    
    // ловим событие от dom
    js code=`
      env.ns.parent.hex2tri = (hex) => {
        var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        return result ? [
            parseInt(result[1], 16) / 255.0,
            parseInt(result[2], 16) / 255.0,
            parseInt(result[3], 16) / 255.0
        ] : [1,1,1];
      }
    `;

    
    reaction (race_channels (dom_event_cell @sc "change") (dom_event_cell @sc "input")) {: event_data obj=@sc |
    	event_data = event_data[0] || event_data[1]
    	var c = obj.hex2tri( event_data.target.value );
      obj.setParam("value",c,true);
      //console.log('emitting',c)
      obj.emit("user_change",c);
    :}
  }
}

///////////////////////////////////////////////////// combobox
/*
   входы 
     values - список значений
     value - выбранное значение
     index - номер выбранного значения
     titles - надписи
   выходы
    value - выбранное значение
    output - выбранное значение (дублирует value)
    index  - номер выбранного значения

   пример
    combobox values=["alfa","beta","teta"];

   примечание
    это больная реализация combobox. она опирается на values а в результате
    выдает допом в кач-ве бонуса index.
    это все означает что если есть повторяющиеся values, то индекс будет выдаваться
    первого вхождения в эти values. а не selectedIndex из хтмл. кстати может стоит
    перейти именно к хтмл-поведению в этом смысле и не заниматься пересчетами.
    но в общем пока так.
*/

feature "cb-follow-last" {: env |
	let main = env.host
	main.onvalue("titles",() => {
 	    let index = main.params.titles.length-1
 	    main.setParam("index",index)
  });	
:}

feature "cb-follow-last-on-length-change" {: env |
	let main = env.host
	let prev_len
	main.onvalue("titles",() => {
 	    let len = main.params.titles.length
 	    if (len != prev_len) {
 	    	prev_len = len
 	    	let index = main.params.titles.length-1
 	    	main.setParam("index",index)
 	    }
  });	
:}

feature "combobox" {
	cbroot: dom tag="select" {{

   ///////////////////////////////////////////////
   // мостик из CL в dom

	 m-eval {: main=@cbroot |
	   main.onvalue("index",(i) => {
	   	 setup_index();
	   	 // новооведение
	   	 if (main.params.values)
	   	     main.setParam("value",main.params.values[ i ], main.getParamManualFlag( "value"));
	   });
	   main.onvalues_any(["values","titles"],() => {
	     setup_values();
	   });	   
	   main.onvalue("dom",() => {
	     setup_index();
	     setup_values();
	   });
	   main.onvalue("value",recompute_index);

	   // новый интерфейс.. мб удобнее будет на его основе создать новый комбо.. 
	   main.onvalue("records",(recs) => {
       let vals = recs.map( r => r[0] ) 
       let tits = recs.map( r => r[1] ) 
       main.setParam("values",vals)
       main.setParam("titles",tits)
	   })

	   function recompute_index() {
	   	  let index = (main.params.values || []).indexOf( main.params.value );
	   	  //console.log("recompute_index called, values are",main.params.values,main.params.value,index)
	      main.setParam("index",index);
	      setup_index();
	   }
	   function setup_index() {
	   	  if (!main.params.dom) return;
	   	  //console.log("setup-index",main.params.index)
	   	  main.params.dom.selectedIndex = main.params.index;
	   }
	   function setup_values() {
	   	  if (!main.params.dom) return;
	   	  // todo idea может номера тогда?
	   	  let values = main.params.values;
	   	  //console.log("setup values",main)

	   	  if (!values?.map)
	   	  {
	   	  		//console.log("values are empty")
	   	  	  if (main.params.titles) {
	   	  	  	//console.log("using titles",main.params.titles)
	   	  			values = [...Array(main.params.titles.length).keys()];
	   	  	  }
	   	  		else
	   	  		  return;	
	   	  		// если задали ток заголовки то покажем их...
	   	  		// а воообще это больная логика - ну мало ли values у меня какие, хоть дублирующиеся
	   	  		// а нет, тут же требуется чтобы values были различны..
	   	  		// хотя может это чисто наш прибабах, кстати. да это чисто наш
	   	  	  //if (main.params.titles) {} else 
	   	  	  // return;
	   	  };
	   	  var t = "";

	   	  let titles = main.params.titles || [];

	   	  values.map( (v,index) => {
	   	  	 var title = titles[index] || v;
	         var s = `<option value="${v}">${title}</option>\n`;
	         t = t+s;
	   	  })
	   	  main.params.dom.innerHTML = t;

	   	  // после этого комбобокс дом сбивается, и надо его перенастроить
	   	  // единственное проблема - может оказаться что value еще неподходящий (еще не прислали, потом пришлют)
	   	  
	   	  // поэтому тут мы отрабатываем случай если value подходящий
	   	  let index = (values || []).indexOf( main.params.value );
	   	  //console.log("cb interma, ",main.params.value,main.params.values ,index)

	   	  if (index >= 0)
	   	  	main.params.dom.selectedIndex = index;
	   	  else {
	   	  	if (main.params.index >= 0) {
	   	  		main.signalParam("index");
	   	  	  //main.params.dom.selectedIndex = main.params.index;
	   	  	}
	   	  	// но вообще это все стремная сложная тупорогая модель, надо другую  
	   	  }

	   }
    :}

    ///////////////////////////////////////////////
    // мостик из dom в cl
    read @cbroot | dom_event_cell "change" | reaction {: event_data object=@cbroot |
      //console.log("dom onchange",object.dom.selectedIndex )
      object.setParam("index",object.dom.selectedIndex); // ???????
      object.setParam("output_index",object.dom.selectedIndex);

		  if (object.params.values) {
		  	//object.setParam("output",object.params.values[ object.dom.selectedIndex ]);
		  	//console.log('setting value to',object.params.values[ object.dom.selectedIndex ],'current is', object.params.value)
			  object.setParam("value",object.params.values[ object.dom.selectedIndex ], true);
			  object.emit("user_changed_value", object.params.value );
			  object.emit("user_change", object.params.value );
			  // получается если значения не заданы то про индекс мы и не расскажем
		  }
		:};
	  
	}};
};

///////////////////////////////////////////////////// editablecombo
/*
   входы 
     values - список значений
     value - выбранное значение
   выходы
    value - выбранное или набранное значение
    output - выбранное значение (дублирует value)

   // туту на будущее - смотреть варианты сигналов.. 

   пример
    editablecombo values=["alfa","beta","teta"];
*/

register_feature name="editablecombo" {
	ecroot: dom tag="input" 
	  dom_type="text"
	  datalist_id=(uniq_id_generator)
	  dom_attr_list=@.->datalist_id
	  dom_obj_value=@.->value
	  {
			dom tag="datalist" 
			   dom_attr_id=@ecroot->datalist_id 
			   innerHTML=(compute_output values=@ecroot->values code="
				  return env.params.values ? env.params.values.map( (str) => `<option value='${str}'>${str}</option>`).join('') : '';
				");
			dom_event name="change" code=`
				let val = env.params.object.dom.value;
				// args[0].value
			  env.params.object.setParam( "value",val );
			`;
    };
};

////////////////////////////////////////////// tabview
/*
 tabview - показывает содержимое в стиле табов
 входы
   children - на вход надо подавать список объектов типа tab у которых выставлен параметр text*
   index - номер активной табы
 выходы
   index - номер активной табы

 пример:
   tabview { 
     tab text="alfa" { button text="content-1"}; 
     tab text="beta" { button text="content-2"}; 
   };
*/   

register_feature name="tabview" {
	dastabs: column index=0 {
		shadow: shadow_dom {
			row gap="0.15em" {
				 /// model=@../../..->titles
				repeater model=@titles_computer->output {
					//radio_button text=@.->modelData cmd=@clicked->apply group_id=@..->guid {
					button text=@.->modelData cmd=@clicked->apply style=@bstyle->output {
						clicked: setter target="../../../..->index" value=@..->modelIndex;

						bstyle: compute_output selected_idx=@dastabs->index my_idx=@..->modelIndex code=`
						  if (env.params.selected_idx == env.params.my_idx)
						    return "transform: scale(1.25);"; //font-weight: bolder;" //  border-bottom: 0px;
						  else
						    return "opacity: 1; transform: scale(1);";
						`;
					};
				};
			};
			tabshere: row;

			// управление переменной index
			js code=`
			  var shadow = env.ns.parent;
			  var tabview = shadow.ns.parent;
			  var tabshere = shadow.ns.childrenTable.tabshere;

			  env.feature("delayed");
			  let update_visible_tab = env.delayed( update_visible_tab2 );

			  function get_tabs() {
			    return tabview.ns.children.filter( (elem) => elem.is_feature_applied("tab") );
			  }

			  tabshere.inputObjectsList = () => get_tabs();
			  tabview.on("childrenChanged",() => {
			    tabshere.callCmd("rescan_children");;
			    update_visible_tab();
			  } ); // dom hack

			  tabview.onvalue("index",update_visible_tab )

			  function update_visible_tab2() {

			  	var index = tabview.params.index;

   	      get_tabs().forEach( (elem,eindex) => {
	        	 elem.setParam("visible", eindex == index);
	        })
			  }
			  /*
			  function hilite_visible_tab() {
			  	var index = tabview.params.index;
   	      get_tabs().forEach( (elem,eindex) => {
	        	 elem.setParam("visible", eindex == index);
	        })
			  }*/
		    
		    tabshere.callCmd("rescan_children");;
  	    update_visible_tab();

			 `;

			 // вычисление заголовков
			 titles_computer: compute code=`
			  var shadow = env.ns.parent;
			  var tabview = shadow.ns.parent;
			  var tabshere = shadow.ns.childrenTable.tabshere;
			  function get_tabs() {
			    return tabview.ns.children.filter( (elem) => elem.is_feature_applied("tab") );
			  }			  

			  let tracking = [];
			  function untrack_all() {
			  	tracking.forEach( f => f() );
			  	tracking = [];
			  }

			  env.feature("delayed");
			  let scan_titles = env.delayed(scan_titles2);
				function scan_titles2() 
			  {
			  	var titles = [];
			  	untrack_all();
	        get_tabs().forEach( (elem,eindex) => {
	        	 titles.push( elem.params.text );

	        	 let t = elem.trackParam("text", scan_titles);
	        	 tracking.push( t );
	        });
	        env.setParam("output",titles);
	        env.setParamOption("output","internal",true);

	        //console.log("titles:",titles);
			  }

			  tabview.on("childrenChanged",scan_titles ); // dom hack
			  scan_titles();
			  		  
			 `;
  	}; // shadow_dom
	 }; // column
};

register_feature name="tab" {
	 dom text=@.->0?;
};

////////////// новые табы

register_feature name="show_one" {
	root: column index=0 {

		js code=`
		  let s = env.ns.parent;
		  
			function refresh() {
				let i = 0;
				let index = s.params.index;
				//console.log('show-one refresh', index)

				for (let c of s.ns.getChildren()) {
					  //if (c.$vz_type == "link") continue;
					  // неправильно это усе.. надо генераторы делать но еще надо и js этот убирать отсель
					  // то ли в субфичи его загонять то ли в eval превращать а его делать тоже особым/в альт дерево загоняемым
					  if (c.is_feature_applied("link") || c.is_feature_applied("repeater") || c.is_feature_applied("js")) continue;
					  // todo тут наоборот надо проверять что оно dom..
					  let v = (i == index) || (c == index);
						c.setParam("visible", v)
						i++;
				}
			}

			s.on("childrenChanged",refresh)
			s.monitor_values(["index"],refresh)
		`;
	 }; // column
};

/*
  switch_selector items=["Рыба","Ела","Мясо"]
*/
register_feature name="switch_selector_column" {
	root: column index=0 generated_items=@rep->output {
		rep: repeater input=@root->items {
			 button text=@.->input 
			 {
			 	 setter target="@root->index" value=@..->modelIndex manual=true;
			 };
		};
	}; // column
};
// это хорошая цель для генератора. она бы тогда просто кнопки выдавала а куда уж вставим..
// впрочем она и сейчас может так работать, репитер примерно так себя ведет

register_feature name="switch_selector" {
	root: repeater input=@root->items index=0 {
			 button text=@.->input {
			 	 setter target="@root->index" value=@..->input_index manual=true;
			 };
		};
};

// но с другой стороны тут еще стили особые появятся, поэтому ладно уж
// switch_selector_row items=['a','b','c']
register_feature name="switch_selector_row" {
	root55: row index=0 gap="0.2em" generated_items=@rep->output items=[]
	{
		rep: repeater input=@root55->items { |input index|
			 bt:button text=@input			 
			 {{ reaction (event @bt "click") {: obj=@root55 index=@index | 
			 	     obj.emit('user_change',index) 
			 	     obj.setParam( "output_index", index, true ); // или output_index?
			 	     obj.setParam( "index", index, true ); // но то устаревшее
			 	  :} 
  	 	 }}
		};
	}; // column
};

feature "hilite_selected" {
  hs: object index=@..->index generated_items=@..->generated_items 
  {
	  geta @hs->index input=@hs->generated_items default=[]
	  | x-modify {
		   x-set_params dom_style_background="rgb(166 209 255 / 65%)" dom_style_border="1px solid";
	  };
	};  
};