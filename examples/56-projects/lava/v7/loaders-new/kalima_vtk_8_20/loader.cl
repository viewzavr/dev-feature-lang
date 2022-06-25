loader criteria=(m_lambda "() => 1")
load={ |dir,project|
v:
   visual_process auto_gui2
   auto_gui3
   //{{ call @v->active_view "append_process" @v; }}
   {{ m_eval "(av,v) => { av.append_process(v) }" @v->active_view @v }}
   //{{ m_eval "(av,v) => { av.feature('delayed'); av.timeout( () => av.append_process(v),65 ) }" @v->active_view @v }};
   title="Калима"
   {{ x-param-slider name="N" min=0 max=(( @blocks->output | geta 0 | geta 1 | geta "length") - 1) }}
   N=0
   dir=[]
{

   vis-group scene2d=@scene2d title="Вывод N на экран" {
     scene2d: dom tag="h2" style="color: white; margin: 0" innerText=(join "N=" @v->N);
   };

   blocks_colors: {"block_0":[0,0,1],"block_1":[0,0,1],"block_2":[0,0,1]};
   
   // найдем различные серии файлов vtk
   blocks: detect-blocks @dir "particledata_(.+)_(\d+)\.vtk$";

   // покажем найденные серии файлов
   @blocks->output | repeater {
     it: vtk-vis-file title=(@it->input | geta 0) 
                      file=(@it->input | geta 1 | geta @v->N) 
                      default_column="visco_coeffs"
                      color=(@blocks_colors | geta (@it->input | geta 0) default=[1,0,0]) ; //используем цвет для блоков
   };

   vis-group title="OBJ-файлы" {
      // найдем все файлы с расширением .obj и покажем их с помощью obj-vis-file
      find-files @dir "\.obj$" | repeater {
        it: obj-vis-file file=(@it->input | geta 1) title=(@it->input | geta 0) color=[0,0.5,0];
      };
   };

   ;

};
};