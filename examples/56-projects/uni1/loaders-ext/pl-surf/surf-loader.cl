
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

   vg: vis-group scene2d=@scene2d title="Вывод N на экран" 
   {{ x-param-color name='color' }}
   gui0={ 
    //render-params-list object=@vg list=["color"]; 
    render-params @vg filters={ params-hide ["visible","title"] };
   }
   color=[1,1,1]
   {
     scene2d: 
        dom tag="h2" style="margin: 0;" 
        innerText=(join "N=" @v->N)
        dom_style_color=(tri2hex @vg->color)
        ;

        //dom_style_color=(tri2hex @mmm->color);
   };

   @vg | x-modify {
     x-param-checkbox name="surf_color" title="цвет поверхности";
   };
   if (@vg->surf_color) then={
     @vg | x-modify {
        //x-set-params dom_style_color=(tri2hex @mmm->color);
        x-set-params color=@mmm->color;
     };
   }; 

  
/*
  find-objects-bf features="geffect3d" root=@vg recursive=false { |obj|
     add_sib_item @obj "effect3d-follow-mesh" "Цвет как у поверхности";    
  };
  */

/* тут мы юзаем имя фичи а это неправильно. она должна быть безымянной. а по описанию тупо
   а иначе почухня получается.. мешы цвета смешаются... но тогда как это будет сохраняться? тож непонятно
  add_sib_item (find-objects-bf features="geffect3d_table") "effect3d-follow-mesh" "Цвет как у поверхности";
  feature "effect3d-follow-mesh" {
    geffect3d
    x-modify {
      x-set-params color=@mmm->color;
    };
  };
*/  
   
   fils: find-files @dir "^\d+\.txt$" | sort-files "^(\d+)\.txt$";

   k: load-file file=@v->curfile | parse_csv;
   mmm: mesh-vp input=@k->output;

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