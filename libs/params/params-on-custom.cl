// F-PARAM-CUSTOM
feature "x-param-custom" {
  r: x-patch-r @r->name @r->editor
    code=`(name,editor_code, obj) => {
      if (name) {
        obj.addGui( {name:name, type: "custom"} );
        obj.setParamOption( name,"editor",editor_code );
      }
    }
    `;
};

feature "x-param-label-small" {
  xi: x-param-custom editor={
  	 edt: text (join @edt->name " = " (@edt->object | geta @edt->name));
  };
};

feature "x-param-editable-combo" {
  xi: x-param-custom editor={
  	 edt: 
  	      editablecombo 
	        value=(@edt->object | geta @edt->name)
	        values=(get_param_option @edt->object @edt->name "values")
	        ;
	        m_eval "(obj,pn,v) => obj.setParam( pn,v,true )" @edt->object @edt->name @edt->value;
  };
};


feature "x-param-files" {
  xi: x-param-custom editor={
  	xedt: dom_group {
  		sa: switch_selector_row index=( @xedt->object | geta (join @xedt->name "_tab") default=1)
	    	  items=["Папка","Сеть"] {{ hilite_selected }} 
	    	  style_ee="padding-top:5px; padding-bottom: 3px;";

	    	  // сохранялка состояния
	    	  m_eval "(obj,nam,v)=> {
	    	  	  obj.setParam( nam,v,true);
	    	  	}" @xedt->object (join @xedt->name "_tab") @sa->index;

	    column {
		    if (@sa->index == 0) 
		    then={
		    	dir-editor object=@xedt->object name=@xedt->name;
		    }
		    else={
		    	inet-editor object=@xedt->object name=@xedt->name;
		    };
	    };
	    
  	};
  };
};

feature "x-param-files-inet" {
  xi: x-param-custom editor={ inet-editor };
  /*
  {
  	edt: 
  	  inet-editor url=(join @edt->name "_url") values=(get_param_option @edt->object @edt->name "values");
  	  set_param object=@edt->object param=@edt->name value=@edt->output;
  	  set_param object=@edt->object param=(join @edt->name "_url") value=@edt->selected_url;
  };
  */
};

feature "x-param-files-dir" {
  xi: x-param-custom editor={ dir-editor; };
};

feature "inet-editor" {
edt: dom_group {
	  	render-params @idata;
	  	set_param object=@edt->object param=@edt->name value=@result->output;

	  	//m_eval "(obj,pn,v) => obj.setParam( pn,v )" @edt->object @edt->name @result->output;
	  	//set_param object=@idata param="listing_file" value=(@edt->object | geta (join @edt->name "_url"))
	  	//  {{ console_log_params "III-in" }}
	  	//;

/*
	  	set_param object=@edt->object param=(join @edt->name "_url") value=@idata->listing_file manual=true
	  	  {{ console_log_params "III-out" }}
	    	;
*/

	    m_eval "(obj,pn,v) => {
	    	//console.log('III setting val',v);
	      obj.setParam( pn+'_url',v,true );
	    }" @edt->object @edt->name @idata->listing_file;	

/*
	    edtc: editablecombo 
	        value=(@edt->object | geta (join @edt->name "_url"))
	        values=(get_param_option @edt->object @edt->name "values")
	        ;
*/	        

	  	button "Очистить адрес" {
	    	setter object=@idata name="listing_file" value="";
	    };

	  	idata: 
			  //listing_file="http://127.0.0.1:8080/public_local/data2/data.csv"
			  listing_file=(@edt->object | geta (join @edt->name "_url"))
			  {{ x-param-editable-combo name="listing_file"; }}
			  {{ x-param-option name="listing_file" option="values" value=(get_param_option @edt->object @edt->name "values")}}

			  //listing_file=@edtc->value
			  listing_file_dir=(m_eval "(str) => str ? str.split('/').slice(0,-1).join('/') : ''" @idata->listing_file)
	      
	      // {{ x-param-label name="listing_file_lines"; }}
	      // listing_file_lines=(@listing->output | geta "length")
			{
				listing: load-file file=@idata->listing_file | m_eval "(txt) => txt && txt.length > 0 ? txt.split('\n') : []" @.->input;
				listing_resolved: @listing->output | map_geta (m_apply "(dir,item) => dir+'/'+item" @idata->listing_file_dir);
				result: m_eval "(arr1,arr2) => 
					  arr1.map( (elem,index) => [ elem, arr2[index]])
				" @listing->output @listing_resolved->output;
	    };

    };
};    

feature "dir-editor" {
  edt: dom_group {

			button "Выбрать папку" {
				m_apply `(tenv,tname) => {
				  window.showDirectoryPicker({id:'astradata',startIn:'documents'}).then( (p) => {
				  	console.log('got',p, p.entries());
				  	follow( p.entries(),(res) => {
				  		//console.log("thus res is",res);
				  		let sorted = res.sort( (a,b) => {
				  			if (a[0] < b[0]) return -1;
				  			if (a[0] > b[0]) return 1;
				  			return 0;
				  		})
				  		
				  		let myfiles = sorted.filter( s => s[0].match(/\.dat/i))
				  		tenv.setParam(tname,myfiles);
				  	} );

				  	function follow( iterator,cbfinish,acc=[] ) {
							iterator.next().then( res => {
				  			//console.log( res );
				  			if (res.done) {
				  				return cbfinish( acc );
				  			}
				  			if (res && res.value) {
				  				acc.push( res.value );
				  				return follow( iterator,cbfinish,acc )
				  			}
				  		});
				  	}
				  	
				  })
				}` @edt->object @edt->name;
			}; // button

			button "Очистить" {
	    	setter object=@edt->object name=@edt->name value=[];
	    };

    }; // dom group
};    


