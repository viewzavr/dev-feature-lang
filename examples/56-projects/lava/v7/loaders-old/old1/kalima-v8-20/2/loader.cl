v: visual_process auto_gui2
   title="Калима"
   {{ x-param-slider name="N" min=0 max=( ((find-files @v->dir "block_0.+\.vtk$") | geta "length") - 1) }} 
   N=0
   dir=[]
{

   visual_process scene2d=@scene2d title="Вывод на экран" {
     scene2d: dom tag="h2" style="color: white; margin: 0" innerText=(join "N=" @v->N);
   };

   // console_log "helo from loader" @v->dir;

   //find-files @v->dir "\.vtk";
   
   //vtk_files: m_eval "(arr) => arr.filter( rec => rec[0].match(/\.vtk/i) )" @v->dir;
   //console_log "vtk files" @vtk_files->output;

/*
   blocks: ["block_0","block_1","block_2","lava_0","lava_1","lava_2", "lava2_0","lava2_1","lava2_2"];
   
   @blocks | repeater {
      it: vtk-vis-file title=@it->input file=(find-files @v->dir @it->input | sort-by-last-number | geta @v->N);
   };
*/   

   blocks_colors: {"block_0":[0,0,1],"block_1":[0,0,1],"block_2":[0,0,1]};


   detect-blocks @v->dir "particledata_(.+)_(\d+)\.vtk$" | repeater {
     //it: vtk-vis-file title=(@it->input | geta 0) file=(@it->input | geta 1 | geta @v->N);
     it: vtk-vis-file title=(@it->input | geta 0) file=(@it->input | geta 1 | geta @v->N) default_column="visco_coeffs"
           color=(@blocks_colors | geta (@it->input | geta 0) default=[1,0,0]) ;
   };

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
