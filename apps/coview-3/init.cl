load "
./cats.cl 
coview-lib.cl 
gui-system/init.cl 
render-project-gui/init.cl
addons-system/init.cl
addons2/addons.cl
"

// подключаем екраны.
load "screens-system/init.cl"
// это логически правильное место размещения record-а по идее..
coview-record title="Экран" type="the_view_recursive" cat_id="screen"