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

// index - номер текущей табы
register_feature name="tabview" {
	column index=0 {
		shadow: shadow_dom {
			row {
				 /// model=@../../..->titles
				repeater model=@titles_computer->output {
					button text=@.->modelData cmd=@clicked->apply {
						clicked: setter target="../../../..->index" value=@..->modelIndex;
					};
				};
			};
			tabshere: row {	};

			js code=`
			  var shadow = env.ns.parent;
			  var tabview = shadow.ns.parent;
			  var tabshere = shadow.ns.childrenTable.tabshere;

			  tabshere.inputObjectsList = () => tabview.ns.children;
			  tabview.on("childrenChanged",() => {
			    tabshere.callCmd("rescan_children");;
			    update_visible_tab();
			  } ); // dom hack

			  tabview.onvalue("index",update_visible_tab )

			  function update_visible_tab() {
			  	var index = tabview.params.index;
   	      tabview.ns.children.forEach( (elem,eindex) => {
	        	 elem.setParam("visible", eindex == index)
	        })
			  }
		    
		    tabshere.callCmd("rescan_children");;
  	    update_visible_tab();

			 `;

			 titles_computer: compute code=`
			  var shadow = env.ns.parent;
			  var tabview = shadow.ns.parent;
			  var tabshere = shadow.ns.childrenTable.tabshere;

				function scan_titles() 
			  {
			  	var titles = [];
	        tabview.ns.children.forEach( (elem,eindex) => {
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
	 column;
};

