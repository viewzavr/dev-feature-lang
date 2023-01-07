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
	g: param_field name=@g.1 {
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
	g: param_field name=@g.1 {
		text (param @g.0 @g.1 | get-value)
	}
}