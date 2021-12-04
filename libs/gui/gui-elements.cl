register_feature name="button" {
	dom tag="button" innerHTML=@.->text {
		dom_event object=@.. name="click" cmd=@..->cmd;
	};
};

register_feature name="text" {
	dom tag="span" innerHTML=@.->text {
	};
};

register_feature name="file" {
	dom tag="input" dom_type="file" {
		dom_event object=@.. name="change" code=`
		  object.setParam("output",env.params.object.dom.files[0],true)
		`
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
		  if (object.params.values) {
		  	object.setParam("output",object.params.values[ object.dom.selectedIndex ]);
			  object.setParam("value",object.params.values[ object.dom.selectedIndex ]);
		  }
		`;

    ///////////////////////////////////////////////
		// конвертация value<=>index
		val2index: compute value=@..->value values=@..->values code=`
		    console.log("val2index")
			  if (typeof(params.value) != "undefined" && params.values) {
		    	var index = (params.values || []).indexOf( params.value );
        	env.setParam("output",index);
        }
        else
          env.setParam("output",0);
		`;
		index2val: compute index=@..->index values=@..->values code=`
		   console.log("index2val")
		   var val = (params.values || [])[ params.index ];
		   env.setParam("output",val);
		`;
		link to=".->index" from="@val2index->output";
	  link to=".->value" from="@index2val->output";
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
	column index=0 {
		shadow: shadow_dom {
			row gap="0.15em" {
				 /// model=@../../..->titles
				repeater model=@titles_computer->output {
					//radio_button text=@.->modelData cmd=@clicked->apply group_id=@..->guid {
					button text=@.->modelData cmd=@clicked->apply style=@bstyle->output {
						clicked: setter target="../../../..->index" value=@..->modelIndex;

						bstyle: compute_output selected_idx=@../../../..->index my_idx=@..->modelIndex code=`
						  if (env.params.selected_idx == env.params.my_idx)
						    return "transform: scale(1.25);"; //font-weight: bolder;" //  border-bottom: 0px;
						  else
						    return "opacity: 1";
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

