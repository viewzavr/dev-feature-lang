loader
  crit=(m_lambda "(dir) => {
    let r1 = /^\d+\.txt$/;
    let f = dir.find( (elem) => r1.test( elem.name ) );
    return f ? 1 : 0
  }")
  load={ |dir,project,active_view|
v:
   visual_process auto_gui2
   title="Поверхность фронта"
   {{ x-param-slider name="N" min=0 max=(( @fils->output | geta "length") - 1) }}
   //{{ x-param-label name="curfile" show="(f)=>f.name"}}
   curfile=(@fils->output | geta @v->N)
   curfilename=(@v->curfile | geta "name")
   {{ x-param-label name="curfilename"}}
   N=0
{

   vis-group scene2d=@scene2d title="Вывод N на экран" {
     scene2d: dom tag="h2" style="color: white; margin: 0" innerText=(join "N=" @v->N);
   };

   fils: find-files @dir "^\d+\.txt$";

   k: load-file file=@v->curfile | parse_csv;
   mesh-vp input=@k->output;

/*
   @fils->output | geta @v->N | repeater {
     r: {
       k: load-file file=@r->input | parse_csv;
       mesh-vp input=@k->output;
     };
   };
*/   

};

axes: axes-view size=10;

//cam1: camera title="Камера лавы" pos=[-10,45,80] center=[-7,30,0];

s1: the-view-uni title="Вид на фронты" auto-activate-view
{
    area sources_str="@v,@axes" ; //camera=@cam1;
};

};