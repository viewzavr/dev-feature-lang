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
	y: object {{ catch_children "code" external=true }}
}

// paing-gui @object
feature "paint-gui" {
	x: column gap="0.2em" {
		let target = @x->0
		
		let gui_records = (read @target | get-children-arr | arr_filter_by_features features="gui")
		//console-log "gui_records=" @gui_records "gui_codes=" @gui_codes	"gui_tabs=" 
		//@gui_tabs "chi=" (@gui_space | get-children-arr)

/*
		read @gui_records | map-geta "code" | repeater always_recreate=true { |code|
			insert_children list=@code input=@gui_space
		}
*/		

		let gui_codes = (read @gui_records | map-geta "code" | arr_flat)
		insert_children list=@gui_codes input=@gui_space always_recreate=true

		// gui_space: object

		let gui_tabs = (@gui_space | get-children-arr | arr_filter_by_features features="gui-tab")

        ssr: switch_selector_row 
                 index=0
                 items=(read @gui_tabs| map-geta "title")
                 {{ hilite_selected }}

        let current_tab = (read @gui_tabs | geta @ssr.index)

        // todo можно будет не index передавать а объект. надежней
        
        gui_space: show_one index=@ssr->index

        //read @gui_space | get-children-arr | console_log_input "YYY"
	}
}

// мб тогда уж и gui-tabs и там внутри уже gui-tab
// но это если я окончательно определюсь что gui-tab и т.п. gui не идут в генерацию
// разных подсказок
feature "gui-tab" {
	g: column "main" id=@.->0 title=(@g->1? or @g->0?) {

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

feature "gui-checkbox" {
}

feature "gui-text" {
	g: gui-param-field name=@g.1 {
		btn: button "Редактировать"

		connect (event @btn "click") (method @dlg "show")

	      dlg: dialog {
	        column {
	          //text text="Введите текст"; // todo hints
	          text style="max-width:70vh;" "Введите массив"
	               //((get_param_option @pf->obj @pf->name "hint") or "Введите массив");

	          ta: dom tag="textarea" style="width: 70vh; height: 30vh;" 
	          		dom_obj_value=(param @g.0 @g.1 | get-value) // | console_log_input "XXX" @g.0 @g.1)
	                  
	          enter: button text="ВВОД"

	          //text style="max-width:70vh;"
	          //     (get_param_option @pf->obj @pf->name "hint");

	          reaction (event @enter "click") {: ta=@ta dlg=@dlg obj=@g.0 name=@g.1 |
	                let v = ta.dom?.value;
	                obj.setParam( name, v, true );
	                // хотелось бы таки может тут каналы заюзать..

	                dlg.close()
	          :}
	        }
	      }		
	}
}

feature "gui-label" {
	g: gui-param-field name=@g.1 {
		text (param @g.0 @g.1 | get-value)
	}
}

feature "gui-param-field" {
  x: dom tag="fieldset" style="border-radius: 5px; padding: 4px; width: 100%;" 
    //items=(get-block @x)
  {
    dom tag="legend" innerText=@x.1;
    gui-setup-link @x.0 @x.1 style="position: absolute; right: 5px;"
  };
};

jsfunc "param-path" {: object param_name | 
				   	  let path = object.getPath() + "->" + param_name;
				   	  return path :}

feature "gui-setup-link" {
	g: dom {
	  btn: button "->" {}
	  reaction (event @btn "click") (method @dlg "show")
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
		  	  	  (@outgoing_params | map { |x| join (@x.object.title or @x.object.getPath) " - " @x.name })
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

feature "param-info" {
	x: object object=@.. name=@.->0 in=false out=false
				path=(param-path @x.object @x.name)
}

comp "get-param-info" { |object name|
	read @object 
	  | get-children-arr 
	  | arr_filter_by_features features="param-info"
	  // todo: | filter { |x| return (@x.name == @name) }
	  | m-eval {: arr name=@name | return arr.filter( x => x.params.name == name ) :}
	  | geta 0	
}