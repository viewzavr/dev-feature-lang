loader
  criteria="(dir) => true"
  create={ |dir|

v: visual_process
   auto_gui2
   title="Этна"
   {{ x-param-slider "N" 0 min=0 max=(( @blocks->output | console_log_input | geta 0 | geta 1 | geta "length") - 1) }}
   N=0
{

   vis-group scene2d=@scene2d title="Вывод N на экран" {
     scene2d: dom tag="h2" style="color: white; margin: 0" innerText=(join "N=" @v->N);
   };

   blocks: detect-blocks @dir "particledata_(.+)_(\d+)\.vtk$";

   @blocks->output | repeater { |input|
     //it: vtk-vis-file title=(@it->input | geta 0) file=(@it->input | geta 1 | geta @v->N);
     vtk-vis-file title=(@input | geta 0) file=(@input | geta 1 | geta @v->N) default_column="visco_coeffs";
   };

   vis-group title="OBJ-файлы" {
     obj-vis-file file=(find-file @dir "rb_data_0_1" | console_log_input) color=[0, 0.5, 0] title="Поверхность";
     obj-vis-file file=(find-file @dir "rb_data_1_1" ) color=[1, 0.5, 1] title="Источник";
   };
   ;
};

cam1: camera title="K1" pos=[2000, 400, -50] center=[300,-800,0];

s1: the-view-uni title="Вид на Этну" {{ activate-view }} {
    area sources_str="@v" camera=@cam1;
    //cam1: camera title="K1" pos=[3000,1000,-100] center=[300, -600, 40] {{ auto_activate }};
    //camera pos=[-1.213899509537966, -6.483218783513895, 6.731292315078603] center=[-1.3427112420191143,2.246045687869776,2.985181087924206];
};

};
};
