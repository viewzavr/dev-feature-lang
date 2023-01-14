if @target { 
        		// todo вынести в фичи, в отд модуль
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