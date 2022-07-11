v: visual_process auto_gui2
   title="Калима"
//   {{ x-param-slider name="N" }} N=0
   dir=[]
{
   console_log "helo from loader" @v->dir;

   //find-files @v->dir "\.vtk";
   
   //vtk_files: m_eval "(arr) => arr.filter( rec => rec[0].match(/\.vtk/i) )" @v->dir;
   //console_log "vtk files" @vtk_files->output;
   
   vtk-series title="block 0" files=(find-files @v->dir "block_0.+\.vtk$");
   vtk-series title="block 1" files=(find-files @v->dir "block_1.+\.vtk$");
   vtk-series title="block 2" files=(find-files @v->dir "block_2.+\.vtk$");   
   
   vtk-series title="lava_0" files=(find-files @v->dir "lava_0.+\.vtk$");
   vtk-series title="lava_1" files=(find-files @v->dir "lava_1.+\.vtk$");   
   vtk-series title="lava_2" files=(find-files @v->dir "lava_2.+\.vtk$");   
   
   vtk-series title="lava2_0" files=(find-files @v->dir "lava2_0.+\.vtk$");
   vtk-series title="lava2_1" files=(find-files @v->dir "lava2_1.+\.vtk$");   
   vtk-series title="lava2_2" files=(find-files @v->dir "lava2_2.+\.vtk$");
   obj-array title="Вулкан" files=(find-files @v->dir "\.obj$")
    //{{ effect3d-pos x=-91 y=10 }};
   ; 
   
   
};

/*
feature "find_files" {
  r: {
    m_apply "(arr,regtest) => {
     }
  };
};*/


s1: the-view-uni title="Общий вид 2" {
    area sources_str="@v";
    camera pos=[-1.213899509537966, -6.483218783513895, 6.731292315078603] center=[-1.3427112420191143,2.246045687869776,2.985181087924206];
};
