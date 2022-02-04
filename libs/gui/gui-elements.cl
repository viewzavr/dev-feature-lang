register_feature name="button" {
	dom tag="button" innerHTML=@.->text func {{
		dom_event name="click" cmd=".->apply";
	}};
};


register_feature name="text" {
	dom tag="span" innerHTML=@.->text {
	};
};

//
register_feature name="file" {
	dom tag="input" dom_type="file" {
		dom_event object=@.. name="change" code=`
		  env.params.object.setParam("value",env.params.object.dom.files[0],true)
		`;
	};
};

/*
register_feature name="color" {
	dom tag="input" dom_type="file" {
		dom_event object=@.. name="change" code=`
		  env.params.object.setParam("value",env.params.object.dom.files[0],true)
		`;
	};
};
*/

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
	dom tag="label" value=true 
	    dom_style_whiteSpace="nowrap" // это важно чтобы чекбоксы не разрывались
	  {
		dom tag="input" dom_type="checkbox" dom_obj_checked=@..->value {
			dom_event name="change" code=`
				var v = env.params.object.dom.checked;
				env.params.object.ns.parent.setParam("value",v);;
			`;
		};
		text text=@..->text;
	};
};

///////////////////////////////////////////////////// input_float
/* входы
     value - начальное значение
   выходы
     value - выбираемое значение
*/
register_feature name="input_float" {
	dom tag="input" dom_obj_value=@.->value {
		dom_event name="change" code=`
				var v = parseFloat( env.params.object.dom.value );
				env.params.object.setParam("value",v);;
			`;
	};
};


///////////////////////////////////////////////////// radio_button
/* входы
     text - надпись
     group_id - идентификатор группы
   выходы
     cmd - вызывается когда кликнули
*/
register_feature name="radio_button" {
	dom tag="label" {
		dom tag="input" dom_type="radio" dom_name=@..->group_id;
		text text=@..->text;
		dom_event object=@.. name="click" cmd=@..->cmd;
	};
};

///////////////////////////////////////////////////// slider
register_feature name="slider" {
	dom tag="input" dom_type="range" 
	    min=0 max=100 step=1 value=0
	    sliding=true 
	{
		/*
		 link from="..->min"   to="..->dom_min";
		 link from="..->max"   to="..->dom_max";
		 link from="..->step"  to="..->dom_step";
		 link from="..->value" to="..->dom_value";
		*/ 
		 setter value=@..->min target="..->dom_min" auto_apply;
		 setter value=@..->max target="..->dom_max" auto_apply;
		 setter value=@..->step target="..->dom_step" auto_apply;
		 setter value=@..->value target="..->dom_value" auto_apply;
		 
		 dom_event name="input" code=`
		  let object = env.params.object;
		 	if (object.params.sliding)
		 		  object.setParam("value", parseFloat( object.params.dom.value ), true );
		 `;
		 dom_event name="change" code=`
		   let object = env.params.object;
		 		  object.setParam("value", parseFloat( object.params.dom.value ), true );
		 `;

  };
};


///////////////////////////////////////////////////// select_color

// вход, выход: value - значение в форме массива [r,g,b] (от 0 до 1)

register_feature name="select_color" {
  dom tag="input" dom_type="color" {

    // value передаем в dom
    setter target="..->dom_value" value=@val2dom->output auto_apply;
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

      //if (env.params.inp)
      if (Array.isArray(env.params.inp)) {
          let h=tri2hex( env.params.inp );
          //console.log("CC: computed dom elem color,",h,"from",env.params.inp)
          env.setParam("output", h)
      }
      //    return tri2hex( env.params.inp );
      //else
      //    return "#ffffff";
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
    d1: dom_event name="change" code=`
      var c = env.ns.parent.hex2tri(env.params.object.dom.value);
      //console.log("CC: setting param output to ",c, env.params.object.getPath() );
      env.params.object.setParam("value",c,true);
    `;
    dom_event name="input" code=@d1->code;
  };
};

///////////////////////////////////////////////////// combobox
/*
   входы 
     values - список значений
     value - выбранное значение
     index - номер выбранного значения
   выходы
    value - выбранное значение
    output - выбранное значение (дублирует value)
    index  - номер выбранного значения

   пример
    combobox values=["alfa","beta","teta"];
*/
register_feature name="combobox" {
	dom tag="select" {

    ///////////////////////////////////////////////
    // мостик из CL в dom
	 js code='
		 var main = env.ns.parent;
	   main.onvalue("index",(i) => {
	   	 setup_index();
	   });
	   main.onvalue("values",() => {
	     setup_values();
	   });
	   main.onvalue("dom",() => {
	     setup_index();
	     setup_values();
	   });
	   function setup_index() {
	   	  if (!main.params.dom) return;
	   	  main.params.dom.selectedIndex = main.params.index;
	   }
	   function setup_values() {
	   	  if (!main.params.dom) return;
	   	  if (!main.params.values?.map) return;
	   	  var t = "";

	   	  main.params.values.map( (v,index) => {
	         var s = `<option value="${v}">${v}</option>\n`;
	         t = t+s;
	   	  })
	   	  main.params.dom.innerHTML = t;
	   }
 ';	

    ///////////////////////////////////////////////
    // мостик из dom в cl
		dom_event name="change" code=`
      console.log("dom onchange")
      let object = env.params.object;
		  if (object.params.values) {
		  	//object.setParam("output",object.params.values[ object.dom.selectedIndex ]);
			  object.setParam("value",object.params.values[ object.dom.selectedIndex ], true);
		  }
		`;

    ///////////////////////////////////////////////
		// конвертация value<=>index
		val2index: compute value=@..->value values=@..->values code=`
		    //console.log("val2index")
			  if (typeof(params.value) != "undefined" && params.values) {
		    	var index = (params.values || []).indexOf( params.value );
        	env.setParam("output",index);
        }
        else
          env.setParam("output",0);
		`;
		index2val: compute index=@..->index values=@..->values code=`
		   //console.log("index2val")
		   var val = (params.values || [])[ params.index ];
		   env.setParam("output",val);
		`;
		link to="..->index" from="@val2index->output";
	  link to="..->value" from="@index2val->output";
	};
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
			  env.params.object.setParam( args[0].value );
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
			tabshere: row {	};

			// управление переменной index
			js code=`
			  var shadow = env.ns.parent;
			  var tabview = shadow.ns.parent;
			  var tabshere = shadow.ns.childrenTable.tabshere;

			  function get_tabs() {
			    return tabview.ns.children.filter( (elem) => elem.is_feature_applied("tab") );
			  }

			  tabshere.inputObjectsList = () => get_tabs();
			  tabview.on("childrenChanged",() => {
			    tabshere.callCmd("rescan_children");;
			    update_visible_tab();
			  } ); // dom hack

			  tabview.onvalue("index",update_visible_tab )

			  function update_visible_tab() {
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

				function scan_titles() 
			  {
			  	var titles = [];
	        get_tabs().forEach( (elem,eindex) => {
	        	 titles.push( elem.params.text );
	        });
	        env.setParam("output",titles);
	        env.setParamOption("output","internal",true);
			  }

			  tabview.on("childrenChanged",scan_titles ); // dom hack
			  scan_titles();
			  		  
			 `;
  	}; // shadow_dom
	 }; // column
};

register_feature name="tab" {
	 dom;
};

