register_feature name="button" {
	dom tag="button" innerHTML=@.->text dom_type="file" {
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
		  console.log("!!!!!!!!!!!!!!!!!! assigning file output to",env.params.object.dom.files[0])
		  object.setParam("output",env.params.object.dom.files[0],true)
		`
	};
};

/*
register_feature name="combobox" {
	dom tag="select" dom_selectedIndex=@val2index->output {
		repeater model=@..->values {
		  dom tag="option" innerHTML=@.->index;
		};
		dom_event name="change" code=`
		  if (object.params.values) {
		  	object.setParam("output",object.params.values[ object.dom.selectedIndex ]);
			  object.setParam("value",object.params.values[ object.dom.selectedIndex ]);
		  }
		  object.setParam("index",object.dom.selectedIndex );
		`;
		val2index: compute_output input=@..->value code=`
		    return object.params.values[v];
		`;
		param_change name="value" code=`
    	object.params.values[v];
		`;
	};
}
*/

// combobox
//  values
//  value,output
//  index 
register_feature name="combobox" {
	dom tag="select" {

    ///////////////////////////////////////////////
    // мостик из cl в dom
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

// index - номер текущей табы
register_feature name="tabview" {
	tabview: column {
		row {
			repeater model=@tabview->titles {
				button text=@.->modelData cmd=@clicked->trigger {
					clicked: setter target="@tabview->index" value=@..->modelIndex;
				};
			};
		};
		tabshere: row {
		};
		js code=`
		  debugger;
		  var tabsobj = env.ns.parent.ns.childrenTable.tabshere;
		  env.ns.parent.ns.appendChild = (...args) => {
		  	debugger;
		    tabsobj.ns.appendChild(...args);
		  }

		  tabsobj.on('change_in_tree',() => {
		  	var child_items = tabsobj.ns.getChildren() || [];
		  	var titles = [];
        child_items.forEach( (elem,eindex) => {
        	 titles.push( elem.params.text );
        });
        env.ns.parent.setParam("titles",titles);
        update_visible_tab();
		  });

		  env.ns.parent.onvalue("index",update_visible_tab )

		  function update_visible_tab() {
		  	var index = env.ns.parent.params.index;
		  	var child_items = tabsobj.ns.getChildren() || [];
        child_items.forEach( (elem,eindex) => {
        	elem.setParam("visible", eindex == index)
        })
		  }
		`;
	 };
};

register_feature name="tab" {
	 column;
};

