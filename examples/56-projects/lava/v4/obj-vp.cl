// берет на вход серию файлов а на выходе выдает содержимое в форме df
feature "df56-obj";

// вход file
// выход объект с obj данными
feature "obj-source" {
  qqe: visual_process df56-obj 
  title = "Загрузка OBJ файла"
  output=@obj->output
  file="http://127.0.0.1:8080/vrungel/public_local/Kalima/scene/kalima_0.obj"
  {{
  	x-param-file name="file";
  }}
  {
    obj: load_file file=@qqe->file | parse_obj;
  }
};

/// какая боль блин... ну почему... надо понять
feature "obj-vis"
{
	vis: visual_process title="Визуализация OBJ"
	input=@data->output

  gui={
		column plashka {

			collapsible "Источник данных" visible=@vis->show_source{
  		  render-params @data;
	    };

			//render-params @m;
			insert_children input=@.. list=@m->gui;
		
		};
	}	
	gui3={
		render-params @vis;
	}	
	scene3d=@scene->output
	{
		// выбор данных человеком.. мб надо по-другому как-то... что б и человеком и программно можно было..
		data: find-data-source features="df56-obj";

		scene: node3d visible=@vis->visible {{ force_dump }}
		{

		   // 218 201 93 цвет 0.85, 0.78, 0.36
		   @vis->input | m: mesh title="OBJ" visual-process editable-addons 
		     color=[0,0.5,0] 
		     gui={ render-params @m; manage-addons @m; }
		     ;
		};
	};
};