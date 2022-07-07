loader load={ |dir,project,active_view|

v:
   visual_process auto_gui2 // так пока надо написать
   title="Этна" // заголовок
   // доп параметр слайдер с именем N для выбора файла. в целом не обязательный параметр
   {{ x-param-slider name="N" min=0 max=(( @blocks->output | geta 0 | geta 1 | geta "length") - 1) }} 
   N=0
{

   // vis-group это группа, объединяет вложенные визуальные процессы
   // также ее можно использовать для вывода на экран как здесь
   vis-group scene2d=@scene2d title="Вывод N на экран" {
     scene2d: dom tag="h2" style="color: white; margin: 0" innerText=(join "N=" @v->N);
   };

   // находит серии файлов, т.е. файлы с одинаковыми именами, согласно маске
   // результат: массив вида [ [имя-блока, массив-файлов...], [имя-блока, массив-файлов...], ... ]
   blocks: detect-blocks @dir "particledata_(.+)_(\d+)\.vtk$";

   // возьмем найденные серии файлов и для каждой создадим визуализацию втк точек с помощью vtk-vis-file
   @blocks->output | repeater {
     //it: vtk-vis-file title=(@it->input | geta 0) file=(@it->input | geta 1 | geta @v->N);
     it: vtk-vis-file title=(@it->input | geta 0) file=(@it->input | geta 1 | geta @v->N) default_column="visco_coeffs";
   };
   
   // группа
   vis-group title="OBJ-файлы" {
     obj-vis-file file=(find-file @dir "rb_data_0_1") color=[0, 0.5, 0] title="Поверхность";
     obj-vis-file file=(find-file @dir "rb_data_1_1") color=[1, 0.5, 1] title="Источник";
     /* // другой вариант - найти просто все obj файлы в каталоге и показать
      find-files @dir "\.obj$" | repeater {
        it: obj-vis-file file=(@it->input | geta 1) title=(@it->input | geta 0) color=[0,0.5,0];
      };
     */
   };

};

axes: axes_view size=100;

// создадим камеру
cam1: camera title="Камера для Этны" pos=[2000, 400, -50] center=[300,-800,0];

s1: the-view-uni // создадим новый экран
    title="Вид на Этну"
    auto-activate-view
{
    // создадим область на экране, которая будет показывать визуальный процесс v (см выше) используя камеру cam1
    area sources_str="@v,@axes" camera=@cam1;
};

};
