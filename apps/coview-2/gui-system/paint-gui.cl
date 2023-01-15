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

// paing-gui @object
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

		let gui_tabs = (@gui_space | get-children-arr | arr_filter_by_features features="gui-tab" | sort_by_priority)

        ssr: switch_selector_row 
                 index=0
                 items=(read @gui_tabs | arr_filter code={: tab filter=@x.filter | return filter ? filter.indexOf( tab.params.title ) >= 0 : true :} | map-geta "title")
                 visible = (@ssr.items.length > 1)
                 {{ hilite_selected }}

        let current_tab = (read @gui_tabs | geta (m-eval {: i=@ssr.index tabs=@gui_tabs | return Math.min( i, tabs.length-1 ) :}))

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

					      button "Отладка" on_click={: guiobj=@target | 
					    	  if(guiobj) console.log( guiobj )
					    	:}
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
	d: dom_group in=@.->0 out=@.->1 hint="Введите текст" {

		btn: button "Редактировать"

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
	  		console.log('arr=',arr)

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
		  	  	  ["-"]
		  	  	  (@outgoing_params | map { |x| join (@x.object.title or (m-eval {: obj=@x.object | return obj.getPath():})) " - " @x.name })
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
