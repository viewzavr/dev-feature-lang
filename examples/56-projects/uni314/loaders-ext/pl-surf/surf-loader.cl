feature "front_addon" {
  addon crit=(m_lambda "(dir) => {
    //let dir = obj.params.output;
    if (!Array.isArray(dir)) return 0;
    let r1 = /^\d+\.txt$/;
    let f = dir.find( (elem) => r1.test( elem.name ) );
    console.log('surf crit',f);
    return f ? 1 : 0
  }");  
};

front_addon "surf1" "Визуализация фронтов 1";

feature "surf1" {
  v: addon_base
      visual_process 
      auto_gui2
      title="Поверхность фронта"
      N=0
      {{ x-param-slider name="N" min=0 max=(( @fils->output | geta "length") - 1) }}      
      curfile=(@fils->output | geta @v->N)
      curfilename=(@v->curfile | geta "name")
      {{ x-param-label name="curfilename"}}
      {
         fils: find-files @v->input "^\d+\.txt$" | sort-files "^(\d+)\.txt$";
         k: load-file file=@v->curfile | parse_csv;
         mmm: mesh-vp input=@k->output;
      }
      ;
};

front_addon "surf2_prorej" "Визуализация фронтов 2";
feature "surf2_prorej" {
  x: addon_base
  title="Визуализация фронтов 2a"
  {

   v:
    vis-group
       title="С прореживанием"
       addons={ effect3d-delta dz=5; prorej-visible step=1; }
       gui={
        column style="padding-left:0em;" {

          manage-addons @v;
          
          manage-content @v 
             vp=@v->show_settings_vp
             title=""
             items=(m_eval `(t,t2) => { return [{title:"Скалярные слои", find:t, add:t2}]}` 
                    @v->find @v->add)
             ;

        };
      } // gui
    {
       
       fils0: find-files (@x->element | geta "output") "^\d+\.txt$" | sort-files "^(\d+)\.txt$";
       fils: @fils0->output | arr_skip 1;

      repeater input=@fils->output {
         r: output=@m->output {
            k: load-file file=@r->input | parse_csv;
            m: mesh-vp input=@k->output title=(@r->input | geta "name");
         };
      };

    };

   axes: axes-view size=10;

   cam1: camera title="Камера на фронты" pos=[0,5,20] center=[0,0,0];

   s1: the-view-uni title="Вид на фронты прореж." auto-activate-view
   {
       area sources_str="@v,@axes" camera=@cam1;
   };
  };
};


loader
  crit=(m_lambda "(dir) => {
    let r1 = /^\d+\.txt$/;
    let f = dir.find( (elem) => r1.test( elem.name ) );
    return f ? 1 : 0
  }")
  load={ |dir,project,active_view|

v:
   visual_process 
   auto_gui2
   title="Поверхность фронта"
   N=0
   {{ x-param-slider name="N" min=0 max=(( @fils->output | geta "length") - 1) }}
   //{{ x-param-label name="curfile" show="(f)=>f.name"}}
   curfile=(@fils->output | geta @v->N)
   curfilename=(@v->curfile | geta "name")
   {{ x-param-label name="curfilename"}}
   
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

/// ...........................................
/// ...........................................
/// ...........................................


loader
  crit=(m_lambda "(dir) => {
    let r1 = /^\d+\.txt$/;
    let f = dir.find( (elem) => r1.test( elem.name ) );
    return f ? 2 : 0
  }")
  load={ |dir,project,active_view|

v:
   vis-group
   title="Поверхность фронта"
   addons={ effect3d-delta dz=5 }
{
   
   fils: find-files @dir "^\d+\.txt$" | sort-files "^(\d+)\.txt$";

   //k: load-file file=@v->curfile | parse_csv;
   //mmm: mesh-vp input=@k->output;

  repeater input=@fils->output {
     r: output=@m->output {
       k: load-file file=@r->input | parse_csv;
       m: mesh-vp input=@k->output title=(@r->input | geta "name");
       //text3d_one text=(@r->input | geta "name") positions=[5,5,0] color=[0,1,0];
       //text3d lines=(m_eval "(s) => [s]" (@r->input | geta "name"))  positions=[5,5,0] color=[0,1,0];
     };
   };

/*
   repeater input=@fils->output {
     r: vis-group title=(@r->input | geta "name") {
       k: load-file file=@r->input | parse_csv;
       m: mesh-vp input=@k->output title=(@r->input | geta "name");
       //text3d_one text=(@r->input | geta "name") positions=[5,5,0] color=[0,1,0];
       text3d lines=(m_eval "(s) => [s]" (@r->input | geta "name")) 
              positions=[5,5,0] colors=[0,1,0];
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


/*
loader
  crit=(m_lambda "(dir) => {
    let r1 = /^\d+\.txt$/;
    let f = dir.find( (elem) => r1.test( elem.name ) );
    return f ? 3 : 0
  }")
  load={ |dir,project,active_view|

v:
   vis-group
   title="С прореживанием"
   addons={ effect3d-delta dz=5 }
   skip=1
   {{ x-param-slider name="skip" min=1 max=(( @fils0->output | geta "length") - 1) }}   
   gui0={
     render-params plashka @v filters={ params-hide list="title visible"; };
   }  
{
   
   fils0: find-files @dir "^\d+\.txt$" | sort-files "^(\d+)\.txt$";
   fils: @fils0->output | arr_skip @v->skip;

   //k: load-file file=@v->curfile | parse_csv;
   //mmm: mesh-vp input=@k->output;

  repeater input=@fils->output {
     r: output=@m->output {
       k: load-file file=@r->input | parse_csv;
       m: mesh-vp input=@k->output title=(@r->input | geta "name");
       //text3d_one text=(@r->input | geta "name") positions=[5,5,0] color=[0,1,0];
       //text3d lines=(m_eval "(s) => [s]" (@r->input | geta "name"))  positions=[5,5,0] color=[0,1,0];
     };
   };

};

axes: axes-view size=10;

//cam1: camera title="Камера лавы" pos=[-10,45,80] center=[-7,30,0];

s1: the-view-uni title="Вид на фронты" auto-activate-view
{
    area sources_str="@v,@axes" ; //camera=@cam1;
};

};

*/

/////////////////////////////////////////////////////

/*
loader
  crit=(m_lambda "(dir) => {
    let r1 = /^\d+\.txt$/;
    let f = dir.find( (elem) => r1.test( elem.name ) );
    return f ? 3 : 0
  }")
  load={ |dir,project,active_view|

v:
   vis-group
   title="С прореживанием"
   addons={ effect3d-delta dz=5 }
   skip=1
   {{ x-param-slider name="skip" min=1 max=(( @fils0->output | geta "length") - 1) }}   
   gui0={
     render-params plashka @v filters={ params-hide list="title visible"; };
   }  
{
   
   fils0: find-files @dir "^\d+\.txt$" | sort-files "^(\d+)\.txt$";
   fils: @fils0->output | arr_skip 1;

   //k: load-file file=@v->curfile | parse_csv;
   //mmm: mesh-vp input=@k->output;

  repeater input=@fils->output {
     r: output=@m->output {
       k: load-file file=@r->input | parse_csv;
       m: mesh-vp input=@k->output title=(@r->input | geta "name")
          visible=(m_eval "(index,skip) => index%skip == 0" @r->input_index @v->skip)
       ;
       //text3d_one text=(@r->input | geta "name") positions=[5,5,0] color=[0,1,0];
       //text3d lines=(m_eval "(s) => [s]" (@r->input | geta "name"))  positions=[5,5,0] color=[0,1,0];
     };
   };

};

axes: axes-view size=10;

//cam1: camera title="Камера лавы" pos=[-10,45,80] center=[-7,30,0];

s1: the-view-uni title="Вид на фронты" auto-activate-view
{
    area sources_str="@v,@axes" ; //camera=@cam1;
};

};

*/

// | arr_filter_by_features features="lib3d_visual"
addon "prorej-visible" "Видимость элементов";
feature "prorej-visible" {
  k: geffect3d 
    //visibles=(@k->element | get_children_arr | map_geta "get_param_cell" "visible" )
    visibles=(find-objects-bf features="visual-process" root=@k->element recursive=false include_root=false | map_geta "get_cell" "visible" )
    step=1
    {{ x-param-slider name="step" min=1 max=(@k->visibles | geta "length" )}}
  {
    m_eval "(arr,step) => {
      
      for (let i=0; i<arr.length; i++)
        if (arr[i])
            arr[i].set( i%step == 0 ? true : false );

    }" @k->visibles @k->step;
  };
};

loader
  crit=(m_lambda "(dir) => {
    let r1 = /^\d+\.txt$/;
    let f = dir.find( (elem) => r1.test( elem.name ) );
    return f ? 3 : 0
  }")
  load={ |dir,project,active_view|

v:
   vis-group
   title="С прореживанием"
   addons={ effect3d-delta dz=5; prorej-visible step=1; }
   gui={
    column style="padding-left:0em;" {

      manage-addons @v;
      
      manage-content @v 
         vp=@v->show_settings_vp
         title=""
         items=(m_eval `(t,t2) => { return [{title:"Скалярные слои", find:t, add:t2}]}` 
                @v->find @v->add)
         ;

    };
  } // gui
{
   
   fils0: find-files @dir "^\d+\.txt$" | sort-files "^(\d+)\.txt$";
   fils: @fils0->output | arr_skip 1;

   //k: load-file file=@v->curfile | parse_csv;
   //mmm: mesh-vp input=@k->output;

  repeater input=@fils->output {
     r: output=@m->output {
       k: load-file file=@r->input | parse_csv;
       m: mesh-vp input=@k->output title=(@r->input | geta "name")
       ;
       //text3d_one text=(@r->input | geta "name") positions=[5,5,0] color=[0,1,0];
       //text3d lines=(m_eval "(s) => [s]" (@r->input | geta "name"))  positions=[5,5,0] color=[0,1,0];
     };
   };

};

axes: axes-view size=10;

//cam1: camera title="Камера лавы" pos=[-10,45,80] center=[-7,30,0];

s1: the-view-uni title="Вид на фронты" auto-activate-view
{
    area sources_str="@v,@axes" ; //camera=@cam1;
};

};