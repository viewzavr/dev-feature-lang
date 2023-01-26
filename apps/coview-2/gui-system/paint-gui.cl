// поняите о гуи (gui, gui-tabs) и об информации о параметрах (param-info)
// планы - сделать генератор gui на основе инфы о параметрах

/*
  Разные цели
  - нарисовать гуи (на основе параметров но и не только, мб небанальные механики взаимодействия или виды отображения)
    - подзадача - создавать структуру. для этого - проставлять ссылки. для этого - по параметру надо уметь понять, что к нему можно пристыковать.
  - выявить в принципе в системе перечень параметров, которые могут быть исходящими ссылками.
*/

feature "my-object" {
	object {
		gui { 
			gui-tab "main" {
				gui-checkbox "visible"
				gui-group "xtra" {
					gui-row {
						gui-checkbox "mode1" gui-checkbox "mode2" gui-checkbox "mode3"
						//gui-checkbox [[[ "mode1" "mode2" "mode3" ]]]
						//gui-checkbox (~ "mode1" "mode2" "mode3")
					}
				}
			}
		}
	}
}

feature "gui" {
	y: object {{ catch_children "code" reverse=true }} 

	   	/* это робит но вставим в рисователь
	   	{
	   	gui-tab "debug" {
	      button "inspect" on_click={: guiobj=@y | 
	    	  if(guiobj) console.log( guiobj.ns.parent )
	    	:}
	    }*/
	    
}

// задача - добавить табу inspect всем гуи-объеткам
// желательно через модификатор. как?
/*
find-object-bf "gui" | x-modify {
	x-append-param code={
	  gui-tab "debug" {
	    ...
	  }
	}
	или x-set-param code += { ..... } ?
}
*/

// find-object-bf "gui" | insert_children .. - не сработает

/* todo debug
feature "gui-add-inspect-tab" {
	object {
		gui-tab "debug" {
	    button "inspect"
	  }
	}
}

append_feature "gui" "gui-add-inspect-tab"
*/

let xtra_gui_codes={}

feature "paint_gui_show_tabs"

// paint-gui @object
// paint-gui @object filter=["main","extra"]
feature "paint-gui" {
	x: column gap="0.2em" show_common=true filter=null {
		let target = @x->0
		//console-log "target=" @target
		
		let gui_records = (find-objects-bf "gui" root=@target depth=1)
		//let gui_records = (read @target | get-children-arr | arr_filter_by_features features="gui")
		//console-log "gui_records=" @gui_records "gui_codes=" @gui_codes	"gui_tabs=" 
		//@gui_tabs "chi=" (@gui_space | get-children-arr)

/*
		read @gui_records | map-geta "code" | repeater always_recreate=true { |code|
			insert_children list=@code input=@gui_space
		}
*/		

		let gui_codes = (read @gui_records | map-geta "code" | arr_flat)
		//console-log "gui_codes=" @gui_codes
		insert_children list=@gui_codes input=@gui_space always_recreate=true

		// gui_space: object

		let gui_tabs = (@gui_space | get-children-arr | arr_filter_by_features features="gui-tab")
		//let filtered_tabs = @gui_tabs
		let filtered_tabs = (read @gui_tabs | arr_filter code={: tab filter=@x.filter | 
                 	  if (Array.isArray(filter))
                 			return filter ? filter.indexOf( tab.params.id ) >= 0 : true
                 		if (filter?.bind)
                 			return filter( tab.params.id, tab )
                 		return true	
                 		:} | sort_by_priority)

        ssr: switch_selector_row 
                 index=0
                 items=(read @filtered_tabs | map-geta "title")
                 visible = (@ssr.items.length > 1)
                 {{ hilite_selected }}

        let current_tab = (read @filtered_tabs | geta (m-eval {: i=@ssr.index tabs=@filtered_tabs | return Math.min( i, tabs.length-1 ) :}))
        //console-log "current_tab=" @current_tab

        // todo можно будет не index передавать а объект. надежней
        
        gui_space: show_one index=@current_tab 
          ~paint_gui_show_tabs 
          target=@target 
          {
        	if @target { 
        		// todo мб вынести в фичи, в отд модуль
        		if @x.show_common {
		        	gui-tab "Общее" block_priority=10 {
		        		gui-slot @target "title" gui={ |in out| gui-string @in @out }

					      b1: button "Отладка"
					    	reaction (event @b1 "click") {: guiobj=@target | console.log( guiobj ) :}

					    	b2: button "Удалить"
					    	reaction (event @b2 "click") {: guiobj=@target | guiobj.remove() :}
					    }						    
				    }

				    gui-tab "Модификаторы" block_priority=11 {
	        		addons_area input=@target
				    }
			    } // if target
        }

        //read @gui_space | get-children-arr | console_log_input "YYY"
	}
}

// мб тогда уж и gui-tabs и там внутри уже gui-tab
// но это если я окончательно определюсь что gui-tab и т.п. gui не идут в генерацию
// разных подсказок
feature "gui-tab" {
	g: column "main" id=@.->0 title=(@g->1? or @g->0?) gap="0.2em" {

	}
}

feature "gui-group" {
	collapsible
}

feature "gui-row" {
	row
}

///////////////////////////////////
// щас самое интересное буде
// апи
// объект имя-параметра

feature "gui-text" {
	d: dom_group in=@.->0 out=@.->1 hint="Введите текст" btn_title="Редактировать" {

		btn: button @d.btn_title

		connect (event @btn "click") (method @dlg "show")

	  dlg: dialog {
	        column {
	          //text text="Введите текст"; // todo hints
	          text style="max-width:70vh;" @d.hint
	               //((get_param_option @pf->obj @pf->name "hint") or "Введите массив");

	          ta: dom tag="textarea" style="width: 70vh; height: 30vh;" 
	          		dom_obj_value=(read @d.in | get-value) // | console_log_input "XXX" @g.0 @g.1)
	                  
	          enter: button text="ВВОД"

	          //text style="max-width:70vh;"
	          //     (get_param_option @pf->obj @pf->name "hint");

	          reaction (event @enter "click") {: ta=@ta dlg=@dlg out=@d.out |
	                let v = ta.dom?.value;
	                out.set( v )
	                dlg.close()
	          :}
	        }
	      }
	}
}

/*
dom-comp "gui-text" { | in out |

		btn: button "Редактировать"

		connect (event @btn "click") (method @dlg "show")

	  dlg: dialog {
	        column {
	          //text text="Введите текст"; // todo hints
	          text style="max-width:70vh;" "Введите текст"
	               //((get_param_option @pf->obj @pf->name "hint") or "Введите массив");

	          ta: dom tag="textarea" style="width: 70vh; height: 30vh;" 
	          		dom_obj_value=(read @in | get-value) // | console_log_input "XXX" @g.0 @g.1)
	                  
	          enter: button text="ВВОД"

	          //text style="max-width:70vh;"
	          //     (get_param_option @pf->obj @pf->name "hint");

	          reaction (event @enter "click") {: ta=@ta dlg=@dlg out=@out |
	                let v = ta.dom?.value;
	                out.set( v )
	                dlg.close()
	          :}
	        }
	      }
	
}
*/

// упс. вот приехали - нет ортогональности. я не могу отнаследоваться от gui-text
// и плохо то что они работают объектом напрямую.. каналы было бы гораздо лучше - я бы мог редиректить
// итого апи сложный у них получается..
// тут бы давали param-info хотя б.. но пока такой связи нет..
// comp всем хорош но нет именованных аргументов..

// с каналами прикольнее и яснее. но. получается оно там будет парсить все по 10 раз
// а оно нам может и не надо.. 

// пробелы или , ? или в опцию вынести?
dom-comp "gui-df" { |in out|

	//console-log "gui-df in=" @in1 "me=" @.

	//find-in-scope

	gui-text 
	  (read @in | get-value | generate-csv2 | create-channel)
		(z: create_channel)

		{{ read @z->output | get-value | parse_csv | put-value-to @out }}	

}


/* можно и так ручками но зачем когда есть comp
   но вообще это идея - подумать - таки на уровне фичи бы делать вещи да и все.. 
   просто практика показывает что чаще вроде как позиционные проще в || перечислить?..
feature "gui-df" {
	d: dom {
		let in = @d.0 out=@d.1

		gui-text 
		  (read @in | get-value | generate-csv2 | create-channel)
			(z: create_channel)
			@obj @name

		read @ z | get-value | parse_csv | put-value-to @out		

  }
} 
*/ 


dom-comp "gui-label" { |in|
	 text (read @in | get-value)
}

/* было стало
feature "gui-label" {
	g: gui-param-field name=@g.1 {
		text (param @g.0 @g.1 | get-value)
	}
}
*/

// вот это канеш прикол
// тут надо по-другому все делать...
// идея что комбинация типа-и-слота мб дала бы свободу творчества?
dom-comp "gui-checkbox" { |in out|
	 cb: checkbox value=(read @in | get-value) 
	 reaction (event @cb "user_change") @out
}

dom-comp "gui-string" { |in out|
	 g: input_string value=(read @in | get-value)
	 reaction (event @g "user_change") @out
}

dom-comp "gui-float" { |in out|
	 g: input_float value=(read @in | get-value)
	 reaction (event @g "user_change") @out	 
}

dom-comp "gui-local-files" { |in out|
	 g: files //value=(read @in | get-value)  // dom_obj_files=@d.value
	 reaction (event @g "user_change") @out	 
}

// один файл
// на будущее можно сделать выбор из библиотеки еще
dom-comp "gui-file" { |in out|
	 column {
	 	 let current_value = (read @in | get-value)
		 text (m-eval {: f=(read @in | get-value) | 
		 	 
		 	 let name = typeof(f?.name) == "string" ? f.name : (f || "")
		 	 let txt = ""
		 	 if (f?.url) 
		 	  txt = `<a target='_blank' href='${f.url}' title='${f.url}'>${name}</a>`
		 	 	else if (f instanceof File)
          {
          	let url = URL.createObjectURL(f);
          	txt = `<a target='_blank' href='${url}' title='${url}'>${name}</a>`
          }
		 	 	else txt = name

		 	 //return "Файл: " + txt
		 	 return txt
		 	:}) style="max-width: 20ch; overflow: hidden; text-overflow: ellipsis;
		 background: #d8d8d8;
    border-radius: 4px;
    padding: 3px;"
     visible=@current_value
		 /*
		 display:inline-block;
  	 white-space: nowrap;  	 
     
     */

		 text "Новое значение:" visible=@current_value

		 select: switch_selector_row index=1 items=["URL","Локальный файл","Очистить"] {{ hilite_selected }}

		 // если я хочу чтобы ввод был по enter-у.. надо делать форму или ловить ентер
		 show-one index=@select.index style="padding:0.3em;" {
		 	 g2: input_string value=(read @in | get-value | m-eval {: f | if (f instanceof File) return ""; return (typeof(f?.url) == "string" ? f.url : f):})
		 	        dom_attr_name="file_url"
	  	 g: file //dom_obj_value=(read @in | get-value)  // dom_obj_files=@d.value
	  	 g3: button "Очистить"
	   }

	   reaction (event @g3 "click") {: out=@out | out.set( "") :} //{ read @out | put-value "" }
	   reaction (event @g "user_change") {: out=@out file |
	   		if (file) out.set( file ); // если там нажали cancel то нам все-равно должно быть
	   	:}
	   reaction (event @g2 "user_change") {: out=@out url |
           let sp = url.split('/');
           if (sp.at(-1) == '') sp.pop();
           let result = {name:(sp.at(-1) || ""),url:url}
           
           out.set( result );
	   	:} // идея - следующий аргумент если out то туда кладется результат reaction ))) .. хотя reaction всегда может результат так-то возвращать а класть уже put-value-to
	}   
}

// выбор из библиотеки
// library= элемент типа cv-select-files. ему кстати будет посылаться сигнал add если пользователь выберет Добавить
// как я легко догадался что library это параметр.. что не надо кидаться его искать..
// что вот любой вопрос это параметр... (ведь по умолчанию его можно решать во внешнем контексте, а стало быть он параметр)
// на худой конец предложим свое дефолт-решение
// но не имеем права брать на себя ответственность решать за всех (лишая их выбора....!!!!!!)
feature "gui-file-lib" { 
	x: column in=@x.0 out=@x.1 library=null {
	 	 let current_value = (read @x.in | get-value)

		 text (m-eval {: f=(read @x.in | get-value) | 
		 	 
		 	 let name = typeof(f?.name) == "string" ? f.name : (f || "")
		 	 let txt = ""
		 	 if (f?.url) 
		 	  txt = `<a target='_blank' href='${f.url}' title='${f.url}'>${name}</a>`
		 	 	else if (f instanceof File)
          {
          	let url = URL.createObjectURL(f);
          	txt = `<a target='_blank' href='${url}' title='${url}'>${name}</a>`
          }
		 	 	else txt = name

		 	 //return "Файл: " + txt
		 	 return txt
		 	:}) style="max-width: 20ch; overflow: hidden; text-overflow: ellipsis;
		 background: #d8d8d8;
    border-radius: 4px;
    padding: 3px;"
     visible=@current_value

		 text "Новое значение:" visible=@current_value

		 //console-log "using lib " @x.library

		 cb: combobox style="max-width: 220px;font-size: 12pt;"
		 records=(m-eval {: files=@x.library.files | 
		 	  let a = [[-1,"Выберите файл:"],[-3, "..добавить новый файл"],[-2, "---"]]
		 	  let b = files.map( (x,index) => [ index, x.name ] )
		 	  let c = []
		 	  return a.concat(b).concat(c) 
		 :})

		 reaction (event @cb "user_change") {: index_in_lib tgt=@x.out files=@x.library.files lib=@x.library |
		 	  //console.log('user_hcnage',index_in_lib)
		 	  if (index_in_lib >= 0)
		 	  	tgt.set( files[ index_in_lib ])
		 	  else
		 	  if (index_in_lib == -2)  {
		 	  	tgt.set( null );
		 	  }
		 	  if (index_in_lib == -3)
		 	  	lib.emit("add_new")
		 :}

		 reaction (event @x.library "added") {: added_files cbval=(event @cb "user_change" | get-value) tgt=@x.out |
		 	  if (added_files.length > 0)
		 	  	tgt.set( added_files[0] )
		 :}
		 
	}   
}



// выбор нескольких файлов
feature "gui-files" {
	 x: column in=@x.0 out=@x.1 {
	 	 let current_value = (read @x.in | get-value)
		 text (m-eval {: f=(read @x.in | get-value) |
		 	 if (Array.isArray(f)) return `Файлов: ${f.length}`
		 	 return ""
		 	:}) 
     visible=@current_value
		 
		 select: switch_selector_row index=1 items=["URL","Локальные файлы","Очистить"] {{ hilite_selected }}

		 show-one index=@select.index style="padding:0.3em;" {
		 	 g2: input_string //value=(read @x.in | get-value | m-eval {: f | if (f instanceof File) return ""; return (typeof(f?.url) == "string" ? f.url : f):})
		 	        dom_attr_name="file_url"
	  	 g: files
	  	 g3: button "Очистить"
	   }

	   reaction (event @g3 "click") {: out=@x.out | out.set( "" ) :} 
	   reaction (event @g "user_change") {: out=@x.out files |
	   		if (files) out.set( files ); // если там нажали cancel то нам все-равно должно быть
	   	:}
	   reaction (event @g2 "user_change") {: out=@x.out url |
           let sp = url.split('/');
           if (sp.at(-1) == '') sp.pop();
           let result = {name:(sp.at(-1) || ""),url:url}
           
           out.set( [result] );
	   	:} // идея - следующий аргумент если out то туда кладется результат reaction ))) .. хотя reaction всегда может результат так-то возвращать а класть уже put-value-to
	}   
}


feature "gui-vector" {
	g: input_vector_c2 in=@.->0 out=@.->1 value=(read @g.in | get-value) rows=3
	{{ reaction (event @g "user_change") @g.out }}
}

feature "gui-array" { // имеется ввиду array-of-floats ну да ладно

	d: dom_group cols=3 separator=' ' hint="Введите массив (по 3 числа в строке)" {
		let in = @d.0 out=@d.1

		//console-log "gui-df in=" @in1 "me=" @.
		//find-in-scope

		gui-text hint=@d.hint rows=3
	  	(read @in | get-value | m-eval {: arr cols=@d.cols separator=@d.separator| 
	  		//return arr.map( line => line.map(toString).join(separator) ).join('\n')
	  		//console.log('arr=',arr)
	  		// todo: делать это ток когда кликнули диалог. а то зачем просто так генерить то..
	  		// для этого можно сделать active параметр у gui-text и выставлять его в 1 когда реально диалог нажали (событие gui-text)
	  		// ну либо помогло бы лейзи но у нас пока нету

	  		var TypedArray = Object.getPrototypeOf(Uint8Array);
	  	  if (!(Array.isArray(arr) || arr instanceof TypedArray)) {
	  	  	console.log('gui array input is not array', arr)
	  	  	return `входное значение должно быть массивом, а оно ${typeof(arr)}`
	  	  }
	  		
	  		let s = ''
	  		for (let i=0; i<arr.length; i++) {
	  			let elem = arr[i];
	  			if (elem?.toString)
		  			s = s + elem.toString();	  		
		  			else s = s + 'null'
	  			if (cols > 0 && i % cols == cols - 1) s = s + '\n'; else s = s + separator
	  		}
	  		return s
	  		
	  		:} | create-channel)
			(z: create_channel)

		read @z->output | get-value | m-eval {: str | 
			  str = str.trim();
			  if (str === "") return []
			  let s = str.split( /[,\s]+/ );
		    return s.map( parseFloat );
		    // todo тут мб своить к Float32Array или что там попросят
			:} | put-value-to @out

  }

}

// создает массив массивов "слов" (аля Денис) - экспериментально. ну и мб float-matrx надо будет
feature "gui-text-matrix" {

	d: dom_group cols=3 separator=' ' {
		let in = @d.0 out=@d.1

		//console-log "gui-df in=" @in1 "me=" @.
		//find-in-scope

		gui-text 
	  	(read @in | get-value | m-eval {: arr cols=@d.cols separator=@d.separator| 
	  		return arr.map( line => line.join(separator) ).join('\n')
	  		:} | create-channel)
			(z: create_channel)

		read @z->output | get-value | m-eval {: str | 
			  return str.split('\n').map( line => line.split( /[,\s]+/ ) );
			:} | put-value-to @out

  }

}


/*
dom-comp "gui-vector" { |in out|
	 g: input_vector_c2 value=(read @in | get-value) rows=3
	 reaction (event @g "user_change") @out
}
*/

dom-comp "gui-color" { |in out|
	 g: select_color value=(read @in | get-value)
	 reaction (event @g "user_change") @out
}

feature "gui-slider" {
	gg: dom-group in=@.->0 out=@.->1 min=0 max=100 step=1 {
	 	 g: slider2 value=(read @gg.in | get-value) min=@gg.min max=@gg.max step=@gg.step

	 	 if2: input_float style="width:30px;" value=(read @gg.in | get-value)

     connect (event @g "user_change")   @gg.out
     connect (event @if2 "user_change") @gg.out
	}
}

feature "gui-combobox" {
	gg: dom-group in=@.->0 out=@.->1 min=0 max=100 step=1 records=null values=null titles=null {
	 	 g: combobox value=(read @gg.in | get-value) values=@gg.values records=@gg.records titles=@gg.titles
     connect (event @g "user_change") @gg.out
	}
}

/* ну либо позиционно можно было бы передать
dom-comp "gui-slider" { |in out|
	 r: row min=0 max=100 step=1 {
	 	 g: slider2 value=(read @in | get-value) min=@r.min max=@r.max step=@r.step
	 	 // reaction (event @g "user_change") @out	 

	 	 if2: input_float style="width:30px;" value=(read @in | get-value)

	 	 //read @in | get-value | pass_if_changed | put-value-to (list @slider_ch @editor_ch)
     connect (event @g "user_change")   @out
     connect (event @if2 "user_change") @out
     // event @if2 "user_change" | get-value | console-log "i het value from if2"
     //connect (event @if2 "user_change") {: val | console.log('kkk',val) :}
	 }
}*/

feature "gui-slot" {
  x: dom tag="fieldset" style="border-radius: 5px; padding: 4px; width: 95%;" 
    //items=(get-block @x)
  {
    dom tag="legend" innerText=@x.1;
    gui-setup-link @x.0 @x.1 style="float: right;"

    insert_children list=@x.gui input=@x (param @x.0 @x.1) (param @x.0 @x.1 manual=true)
      
  }
}

feature "gui-box" {
  x: dom tag="fieldset" style="border-radius: 5px; padding: 4px; width: 95%;" 
  {
    dom tag="legend" innerText=@x.0;
  }  	
}

jsfunc "param-path" {: object param_name | 

   	  let path = object && param_name ? object.getPath() + "->" + param_name : null;
   	  return path :}

feature "gui-setup-link" {
	g: dom {
	  btn: button "->" 
	    style_s = (m-eval {: my_link=@my_link | return my_link ? "background: radial-gradient(#ffffff00, #673ab7);" : "" :})
	    //style_k = "border-radius: 3px; border: 1px solid;"

	  reaction (event @btn "click") (method @dlg "show")

	  //if (@my_link?) { @btn.style := "background: radial-gradient(#ffffff00, #673ab7);" }

	  dlg: dialog {

	  	let object = @g.0
	  	let param_name = @g.1

	  	// перечень param-info к которым можно целпяться
	  	let outgoing_params = (find-objects-bf "param-info" | m-eval {: arr | return arr.filter( x => x.params.out ) :})

	  	let links_storage_place=@project // пока так

	  	let my_path = (param_path @object @param_name)
			
			let my_link = (read @links_storage_place | get_children_arr 
				   | pause_input
				   //| console-log-input "x1"
				   | arr_filter_by_features features="link"
				   //| console-log-input "x2"
				   | m-eval {: arr path=@my_path| 
				   	  //console.log("my-link eval, arr=",arr,"looking to=",path)
				   	  let res = arr.find( x => x.params.to == path ) 
				   	  //console.log("res=",res)
				   	  return res
				   :})

			let selected_source_param=(read @outgoing_params | geta (@cb.index - 1) default=null)
			let selected_source_path=(param_path @selected_source_param.object @selected_source_param.name)

			let index_of_my_link=(read @outgoing_params 
				| m-eval {: arr my_link=@my_link| 
					if (!my_link) return -1
					//console.log("looking index of my link",arr,my_link)
					let res = arr.findIndex( x => x.params.path == my_link.params.from ) 
					//console.log(res)
					return res
					:})
			//console-log "index_of_my_link=" @index_of_my_link
			param @cb "index" | put-value (1 + @index_of_my_link)

	  	column {

		  	cb: combobox 
		  	  dom_size=10
		  	  titles = (
		  	  	  arr_concat
		  	  	   (list ["-"]
		  	  	         (@outgoing_params | map { |x| join (@x.object.title or (m-eval {: obj=@x.object | return obj.getPath():})) " - " @x.name })
		  	  	   )     
		  	  	  )

		  	select: button "Выбрать"  

		  	reaction (event @select "click") 
		  	  {: my_link=@my_link links_storage_place=@links_storage_place selected_source_param=@selected_source_param 
		  	  	 my_path=@my_path	selected_source_path=@selected_source_path dlg=@dlg |


		  	  	if (selected_source_param) {
		  	  		 // надо назначить
		  	  		 if (my_link) {
		  	  		 	 // уже есть - зададим
		  	  		 	 my_link.setParam("from",selected_source_path,true)
		  	  		 	 console.log("link updated",my_link)
		  	  		 } else {
		  	  		 	 // еще нет - создадим
		  	  		 	 //let link = links_storage_place.vz.createLink( {parent:links_storage_place, manual: true})
		  	  		 	 //let link = links_storage_place.vz.createObj( {parent:links_storage_place, manual: true})
		  	  		 	 let link = links_storage_place.vz.createObjByType( {parent:links_storage_place, manual: true, type: "link"})
		  	  		 	 link.setParam("manual",true,true)
		  	  		 	 link.setParam("from",selected_source_path,true)
		  	  		 	 link.setParam("to",my_path,true)
		  	  		 	 //link.setParam("debug",true)
		  	  		 	 //link.manual_feature("link")
		  	  		 	 link.manuallyInserted = true
		  	  		 	 console.log("link created",link)
		  	  		 }
		  	  	} else {
		  	  		 // надо убрать
		  	  		 if (my_link) {
		  	  		 	  my_link.remove()
		  	  		 	  console.log("link removed")
		  	  		 }  
		  	  	}

		  	  	dlg.close()

		  	:}

	    }

	  	// найти подходящие с чем можно сцепиться
	  	// предоставить выбор пользователю. вероятно с текстовой фильтрацией
	  	// запомнить выбор. плюс возможность для отмены. плюс мб active или как.
	  }
  }
}

/*
feature "param-in" {
	x: object object=@.. name=@..->0
}

feature "param-out" {
	x: object object=@.. name=@..->0
}
вроде как нам зачем их раздельно.. когда можно и туды и сюды типа
param-info name incoming=true outgoing=true gui={ |io| ... } type="text"

ну и по ним гуи можно построить будет, и ссылочную информацию (что там надо было еще? - строгую информацию?)
и еще их дублировать можно будет например - потом соединять по имени

ну и можно будет пожесче сделать.. add-param-info (getparam @x "name")
но вроде нет нуды пока
*/

// param-info name in=.. out=.. value=..
// если задано value то оно копируется в объект. удобно?
feature "param-info" {
	x: object object=@.. name=@.->0 in=false out=false
				path=(param-path @x.object @x.name)
				{{ reaction existing=true (param @x "value") (param @x.object @x.name) }}
}

comp "get-param-info" { |object name|
	read @object 
	  | get-children-arr 
	  | arr_filter_by_features features="param-info"
	  // todo: | filter { |x| return (@x.name == @name) }
	  | m-eval {: arr name=@name | return arr.filter( x => x.params.name == name ) :}
	  | geta 0	
}
