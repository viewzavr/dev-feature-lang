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

feature "x-param-objref-3" {
  xi: x-param-custom
  	 name=@xi->name
     editor={
  	 edt: 
  	      combobox
	        	value=(@edt->object | geta @edt->name)
	        	values=(@xi->values | map_geta (m_apply "(cam) => cam.getPath()"))
	        	titles=(@xi->values | map_geta "title")
	        	{{ x-on "user_changed_value" 
                  code=(m_apply "(area,param_var, b,c,val) => {
                       area.setParam(param_var,val,true);
                       }" @edt->object @edt->name);
            }}
	        ;
     };

};     

feature "x-param-objref-2" {
  xi: x-modify {
  	x-param-custom
  	 name=@xi->name
     editor={
  	 edt: variable_name=(+ @edt->name "_path")
  	      combobox
	        	value=(@edt->object | geta @edt->variable_name)
	        	values=(@xi->values | map_geta (m_apply "(cam) => cam.getPath()"))
	        	titles=(@xi->values | map_geta "title")
	        	{{ x-on "user_changed_value" 
                  code=(m_apply "(area,param_var, b,c,val) => {
                       area.setParam(param_var,val,true);
                       }" @edt->object @edt->variable_name);
            }}
	        ;
     };
     x-patch-r code=(m_apply "(name,obj) => {
     	  obj.feature('find_track');
     	  let pathname = name+'_path';
     	  console.log('BAREA: gonna track name',pathname,' on obj',obj)
     	  return obj.onvalue( pathname,(path) => {
     	  	  console.log('BAREA: var changed',name,'on obj',obj)
     	  		obj.findByPathTrack( obj.params[pathname],(found) => {
     	  			console.log('BAREA: setting name',name,found)
     	  			obj.setParam( name, found );
     	  		} )
     	  } );

     }" @xi->name);

     // x-set-param name=@xi->name value=(find-one-object input=?)

/*
     x-insert-children-list list=(m_eval "(name) => 
     	  `link to=..->${name} from=.. tied_to_parent`
     " | compalang)
*/     

/*
     x-insert-children {
        l: link to=(join "..->" @xi->name) from=(join "..->" @xi->name "_path") tied_to_parent=true;
     };
*/     
  };
};

// вход: listing_file - путь к файлу листинга
// выход: output - массив загруженных файлов из файла листинга
// ну и 
feature "select-files-inet" {
		idata: 
						  //listing_file="http://127.0.0.1:8080/public_local/data2/data.csv"
						  listing_file=""

						  //{{ x-param-editable-combo name="listing_file"; }}

						  {{ x-param-string name="listing_file"; }}
						  //{{ x-param-option name="listing_file" option="values" value=(get_param_option @edt->object @edt->name "values")}}

						  //listing_file=@edtc->value
						  listing_file_dir=(m_eval "(str) => str ? str.split('/').slice(0,-1).join('/') : ''" @idata->listing_file)
				      
				      // {{ x-param-label name="listing_file_lines"; }}
				      // listing_file_lines=(@listing->output | geta "length")
				      output=@result->output
						{
							listing: load-file file=@idata->listing_file 
							  | m_eval "(txt) => txt && txt.length > 0 ? txt.split('\n') : []" @.->input;
							listing_resolved: @listing->output | map_geta (m_apply "(dir,item) => dir+'/'+item" @idata->listing_file_dir);
							result: m_eval "(arr1,arr2) => 
								  arr1.map( (elem,index) => [ elem, arr2[index]])
							" @listing->output @listing_resolved->output;
				    };
};

// вход: regtest - выражение для встроенного фильтра проверки имен файлов
// выход: output - массив загруженных файлов из выбранной пользователем папки
feature "select-files-dir" { 

	ll: regtest = '\.dat'
	  {{
		x-add-cmd name="Выбрать папку" code=(
			m_apply `(tenv,regtest) => {
							  window.showDirectoryPicker({id:'astradata',startIn:'documents'}).then( (p) => {
							  	//console.log('got',p, p.entries());
							  	follow( p.entries(),(res) => {
							  		//console.log("thus res is",res);
							  		let sorted = res.sort( (a,b) => {
							  			if (a[0] < b[0]) return -1;
							  			if (a[0] > b[0]) return 1;
							  			return 0;
							  		})
							  		
							  		let myfiles = sorted.filter( s => s[0].match( new RegExp(regtest,'i') ) )
							  		tenv.setParam('output',myfiles);
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
							}` @ll @ll->regtest;
		);
		x-add-cmd name="Очистить" code=(
			m_apply `(tenv) => tenv.setParam('output',[])` @ll;
		);
	}}
};	

// выход: gui - редактор, output - выбранный список
feature "select-files" 
{
	xedt: 
	  index=1
	  output=( (list @l1 @l2) | geta @xedt->index | geta "output")
	  gui={
		  dom_group {
	  		sa: switch_selector_row index=@xedt->index
		    	  items=["Папка","Сеть"] {{ hilite_selected }} 
		    	  style_ee="padding-top:5px; padding-bottom: 3px;";

		    	  // сохранялка состояния
		    	  m_eval "(obj,nam,v)=> {
		    	  	  obj.setParam( nam,v,true);
		    	  	}" @xedt 'index' @sa->index;

		    column {
		    	//render-params ( (list @l1 @l2) | geta @xedt->index | geta "output");
		    	
			    if (@sa->index == 0) 
			    then={
			    	render-params @l1;
			    }
			    else={
			    	render-params @l2;
			    };
			    
		    };
	  } // dom-group
	} // gui
	{
		l1: select-files-dir;
		l2: select-files-inet listing_file=@xedt->url;
	}  
};

/* ...
feature "x-param-files" {
	xe: x-modify {
		xp: x-param-custom name=@xe->name editor={
			render-params (@xp->object | geta (join @xp->name "_sf"));
		};
		x-patch @xe->name code=`(name,tenv) => {
      let oo = tenv.createObj();
      oo.feature('select-files');
      tenv.setParam( name+"_sf",oo);
		}`;
			x-insert-children {
			fs: select-files;
		};
	};
};
*/