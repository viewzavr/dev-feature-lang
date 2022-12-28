// F-PARAM-CUSTOM

/*
  здесь "параметр" это процесс ассоциированный с основным процессом
   который показывает свой интерфейс на стадии render-params основного процесса
   и взаимодействует с пользователем, записывая свой результат в указанных выход
   основного процесса.
   при этом начальное значение как ни странно сейчас записывается через этот же вход
   и берется оттуда же.

   хотя должно бы поидее являться начальным входом этого процесса, а результат работы
    процесса должен по идее пропускаться через функцию проверки или произвольной реакции.

   update - хоть бы выставляла параметры окружению типа editor={  |object name cell| }  

   update - вообще теперь идея что "параметры" это да, некие ассоциированыне вещи но не входящие в объект.
   а у нас задействуется спец-структура (поле .gui)
*/

// name - имя
// editor - компаланг код редактора
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
  	 edt: text (join @edt->name " = " (@edt->object | geta @edt->name default=null));
  };
};

feature "x-param-switch" {
  xi: x-param-custom editor={
  	 edt: switch_selector_row
  	        items=@xi->values
  	        index=(@edt->object | geta @edt->name)

  	        //{{ read @edt->index | create-channel | reaction {: x | console.log("x=",x) :} }}

  	        {{ hilite_selected }}
  	        {{ @edt->object | get-cell @edt->name manual=true | set-cell-value @edt->index }};
  };
};

feature "x-param-vector-2" {
  xi: x-param-custom editor={
  	 edt: input_vector_c (@edt->object | geta @edt->name)
   			   {{ x-on 'user-changed' {
   			   	  m_lambda "(obj,obj2,val) => {
   			   	  	debugger;
   			   	    //console.log('setting visible to obj',obj,val );
   			   	    obj.setParam('visible', val, true);
   			   	  }" @xi->name;
   			   } }};
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

feature "x-param-df" {
  xi: x-param-custom 
     editor={
  	 edt: param_field {

		    button text="Редактировать" {
		      dlg: dialog {
		        column {
		          text text="Введите данные"; // todo hints
		          ta: dom tag="textarea" style="width: 70vh; height: 30vh;" 
		                dom_obj_value=(generate_csv2 include_column_names=false input=(@edt->object | geta @edt->name))
		                  ;
		          bt: button text="ВВОД";

		          text style="max-width:70vh;"
		               (get_param_option @edt->object @edt->name "hint");

		          logic: csp {
		          	when @bt "click" then={

		          		k: m_eval `(obj,pn,v,dlg) => {
		          	    obj.setParam( pn,v,true );
		          		  dlg.close();
		          	  }` @edt->object 
		          	     @edt->name 
		          	     (m_eval "(ta,columns) => columns + '\n' + ta.dom.value" @ta @xi->columns| parse_csv)
		          	     @dlg;
		          	  when @k "computed" then={
		          	  	restart @logic;
		          	  };
		          	}; // when clicked
		          }; // logic
		        }; // column
		      }; // dlg
		    }; // btn
		  }; //edit
  }; //param custom
};

// рабочий вариант
// x-param-objref-3 name=.... values=.... где values это набор объектов
feature "x-param-objref-3" {
  r: x-patch-r title_field="title"
    @r->name @r->editor @r->values // {{ l: console-log-life; debug_input input=@l }}
    code=`(name,editor_code, values, obj) => {
      if (name) {
      	//console.log("objref-3 init: name=",name,"cur val=",obj.params[name],"obj=",obj.getPath(),obj.dump())
      	//console.log("objref-3 init: name=",name,"cur val=",obj.params[name],"obj=",obj.getPath(), values );
      	//debugger;
      	obj.setReference( name );
        obj.addGui( {name:name, type: "custom",value: obj.params[name]} );
        obj.setParamOption( name,"editor",editor_code );

        // ну вот тоже как-то так.. пусть хоть что-то выбирает
        // причем это надо для камеры.. шоб выбиралась..

        if (values && values[0] && !obj.params[name]) {
        	obj.setParam( name, values[0] );
        }
        
      }
    }
    `
     editor={
  	 edt: param_field {
	  	      combobox style="width: 160px;"
		        	value=(@edt->object | geta @edt->name default=null | geta "getPath" default=null fok=true | m_eval_input) // считается что там объект сидит благодаря
		        	values=(@r->values | map_geta (m_lambda "(obj) => obj.getPath()"))
		        	titles=(@r->values | map_geta @r->title_field)
		        	{{ x-on "user_changed_value" 
	                  code=(m_apply "(area,param_var, b,c,val) => {
	                  	console.log('>>>>>>>>>>>>>>>>',param_var,val)
	                       area.setParam(param_var,val,true);
	                       }" @edt->object @edt->name);
	            }}
		        ;
	        };
     };
};

feature "x-param-objref-2" {
  xi: x-modify {
  	x-param-custom
  	 name=@xi->name
     editor={
  	 edt: combobox 
  	        variable_name=(+ @edt->name "_path")
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

//////////////////////////////////
////////////////////////////////// выбор файлов
//////////////////////////////////

// вход: listing_file - путь к файлу листинга
// выход: output - массив путей файлов из файла листинга
// где каждая запись это {name:имя,url:полный-путь}
feature "select-files-inet" {
		idata:    object
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
							  | m_eval "(txt) => txt && txt.length > 0 ? txt.split('\\n') : []" @.->input;
							listing_resolved: read @listing->output | map_geta (m_apply "(dir,item) => dir+'/'+item" @idata->listing_file_dir);
							result: m_eval "(arr1,arr2) => {
								  
								  if (arr1.length != arr2.length) return;
								  return arr1.map( (elem,index) => {
								  	return {name: elem, url: arr2[index]};
								  })
								}
								" @listing->output @listing_resolved->output;
				    };
};

// вход: regtest - выражение для встроенного фильтра проверки имен файлов
// выход: output - массив загруженных файлов из выбранной пользователем папки
// где каждая запись это FileSystemFileHandle и у нее есть поле name

// update: regtest завалил мне работу с vtk. и это изменение протокола 
// (хоть и встройка адаптера - лесом ее пусит явная будет..) 
// наверное это и не встройка адаптера а изменение таки протокола.. параметр добавили и поведение измениили
feature "select-files-dir" {

	ll: object regtest = '.'
	  {{
		x-add-cmd name="Выбрать папку" code=(
			m_apply `(tenv,regtest) => {
							  window.showDirectoryPicker({id:'astradata',startIn:'documents'}).then( (p) => {
							  	//console.log('got',p, p.entries());
							  	follow( p.values(),(res) => {
							  		//console.log("thus res is",res);
							  		let sorted = res.sort( (a,b) => {
							  			if (a[0] < b[0]) return -1;
							  			if (a[0] > b[0]) return 1;
							  			return 0;
							  		})
							  		
							  		//let myfiles = sorted.filter( s => s[0].match( new RegExp(regtest,'i') ) )
							  		let myfiles = sorted;
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
	xedt: object
	  index=1
	  output=( (list @l1 @l2) | geta @xedt->index | geta "output" default=[])
	  url=""
	  gui={
		  dom_group {
	  		sa: switch_selector_row index=@xedt->index
		    	  items=["Папка","Сеть"] {{ hilite_selected }} 
		    	  style_ee="padding-top:5px; padding-bottom: 3px;";

		    	  // сохранялка состояния
		    	  m_eval "(obj,nam,v)=> {
		    	  	  obj.setParam( nam,v,true);
		    	  	}" @xedt 'index' @sa->index;

				// rgb(90 177 204);
				// идея что пока невыбрано оно поярче а когда выбралось то потише

		    column style="background: #70ddff; 
    border-radius: 5px;
    border: 0px solid black; padding: 2px;
    margin: 2px;" {
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