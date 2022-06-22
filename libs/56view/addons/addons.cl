// метка для объектов для которых добавить визуальное управление добавками

feature "editable-addons" {
   eathing: 
   addons_container=@addons_p
   addons=[]
   {{
     // активация аддонов из addons_p области
     x-modify-list input=@eathing list=(@addons_p | get_children_arr | filter_geta "visible");
     // внедрение доп. аддонов из параметров (апи режим)
     insert-children input=@addons_p list=@eathing->addons;
   }}
   {
     addons_p: {}; // целенаправленно в children ибо оно сохранится в dump
   };
};

geffect3d: feature {
  ef: sibling_titles=@geffect3d->sibling_titles
      sibling_types=@geffect3d->sibling_types

      title=(compute_title key=(detect_type @ef @ef->sibling_types) 
                         types=@ef->sibling_types 
                         titles=@ef->sibling_titles)
  {{ x-param-checkbox "visible"; x-param-option "visible" "visible" false; }}
  visible=true
  ;
};


add_sib_item @geffect3d "effect3d-blank" "-";

feature "effect3d_blank" {
  geffect3d;
};


add_sib_item @geffect3d "effect3d-additive" "Аддитивный рендеринг";
feature "effect3d_additive" 
  //{{ import "" "THREE"; }}
  //{{ load THREE="../../../lib3d/three.js/build/three.module.js" }}
{
  ea: geffect3d 
    gui={render-params @ea; }
  x-patch-r THREE=(import_js (resolve_url "../../../libs/lib3dv3/three.js/build/three.module.js"))
    code=`(tenv) => {
      //console.log("additive, tenv",tenv,env)
      let THREE=env.params.THREE;
      if (!THREE) return;
    
    tenv.onvalue('material',(m)=> {
      //console.log("additive, tenv mat",tenv,m)
      //m.blending = additive ? env.THREE.AdditiveBlending : THREE.NormalBlending;
      m.blending = THREE.AdditiveBlending;
      //m.blending = THREE.MultiplyBlending;
    });
    return () => {
        //let THREE=env.params.THREE;
        //if (!THREE) return;      
        if (tenv.params.material)
            tenv.params.material.blending = THREE.NormalBlending;
    };
  }  
  `
  ;
};

add_sib_item @geffect3d "effect3d-opacity" "Прозрачность";
feature "effect3d_opacity" {
  eo: geffect3d
    {{ x-param-slider name="opacity" min=0 max=1 step=0.01; }}
    {{ x-param-slider name="alfa_test" min=0 max=1 step=0.01; }}
    alfa_test=0.5
    opacity=1.0
    gui={render-params @eo; }
    x-patch-r code=`(tenv) => {
          tenv.onvalue('material',(m)=> {
              m.transparent = true;
              m.opacity = env.params.opacity;

              m.alphaTest = env.params.alfa_test;
              m.needsUpdate = true;
            });
            return () => {
                if (tenv.params.material) {
                  tenv.params.material.transparent = false;
                  tenv.params.material.opacity = 1.0;
                  tenv.params.material.alphaTest = 0.5;
                }
            };
          }
    `;
  ;
};

add_sib_item @geffect3d "effect3d-zbuffer" "Настройки z-буфера";
feature "effect3d_zbuffer" {
  eo: geffect3d
    {{ x-param-checkbox name="depth_test"; }}
    {{ x-param-checkbox name="depth_write"; }}
    {{ x-param-checkbox name="size_attenuation"}}
    depth_test=true
    depth_write=true
    size_attenuation=true
    gui={render-params @eo; }
    x-patch-r code=`(tenv) => {
          tenv.onvalue('material',(m)=> {
              m.depthTest = env.params.depth_test;
              m.depthWrite = env.params.depth_write;
              m.sizeAttenuation=env.params.size_attenuation;
              m.needsUpdate=true;
            });
            return () => {
                if (tenv.params.material) {
                  tenv.params.material.depthTest = true;
                  tenv.params.material.depthWrite = true;
                  tenv.params.material.sizeAttenuation=true;
                  tenv.params.material.needsUpdate=true;
                }
            };
          }
    `;
  ;
};

add_sib_item @geffect3d "effect3d-pos" "Положение";
feature "effect3d_pos" {
  eo: geffect3d
    {{ x-param-float name="x"; }}
    {{ x-param-float name="y"; }}
    {{ x-param-float name="z"; }}
    gui={render-params @eo; }
    x-patch-r code=`(tenv) => {
      //console.log("patching",tenv.getPath(),env.params.x,env.params.y,env.params.z);
          tenv.onvalue('output',(threejsobj)=> {
              let x = env.params.x;
              let y = env.params.y;
              let z = env.params.z;
              if (isFinite(x)) threejsobj.position.x=x;
              if (isFinite(y)) threejsobj.position.y=y;
              if (isFinite(z)) threejsobj.position.z=z;
              threejsobj.position.managed_by_addons ||= 0;
              threejsobj.position.managed_by_addons++;
            });

            return () => {
                if (tenv.params.output) {
                  let threejsobj = tenv.params.output;
                  //console.log('unpatching',tenv.getPath())
                  threejsobj.position.managed_by_addons--;
                  if (threejsobj.position.managed_by_addons <= 0)
                    threejsobj.position.set(0,0,0);
                }
            };
          }
    `;
  ;
};

add_sib_item @geffect3d "effect3d-scale" "Масштаб";
feature "effect3d_scale" {
  eo: geffect3d
    {{ x-param-float name="x"; }}
    {{ x-param-float name="y"; }}
    {{ x-param-float name="z"; }}
    gui={render-params @eo; }
    x-patch-r code=`(tenv) => {
          tenv.onvalue('output',(threejsobj)=> {
              let x = env.params.x;
              let y = env.params.y;
              let z = env.params.z;
              if (isFinite(x)) threejsobj.scale.x=x;
              if (isFinite(y)) threejsobj.scale.y=y;
              if (isFinite(z)) threejsobj.scale.z=z;
            });
            return () => {
                if (tenv.params.output) {
                  let threejsobj = tenv.params.output;
                  threejsobj.scale.set(1,1,1);
                }
            };
          }
    `;
  ;
};

add_sib_item @geffect3d "effect3d-sprite" "Вид точек";
feature "effect3d_sprite" {
  eoa: geffect3d
    {{ x-param-combo name="sprite" values=["","spark1.png","ball.png","circle.png","disc.png","particle.png","particleA.png","snowflake1.png","snowflake3.png"]; }}
    sprite="ball.png"
    gui={render-params @eoa; }
    x-modify {
      //x-set-params texture_url=(if (@eoa->sprite != "") then={resolve_url (+ "sprites/" @eoa->sprite)});
      // этот if ненадежная схема - сначала успевает отработать resolve-url а потом уже if его грохает, но сигнал уже послан..
      // спокойная функц схема отрабатывает тут лучше.. забавно..
      x-set-params texture_url=(m_eval "(p) => p && p.length > 0 ? env.compute_path('sprites/'+p) : null " @eoa->sprite);
    }  
  ;
};

/// ну тут вопрос что входы хотелось бы из других объектов..
add_sib_item @geffect3d "effect3d-script" "Скрипт";
feature "effect3d_script" {
  script: geffect3d
    {{ x-param-float name="input1" }}
    {{ x-param-float name="input2" }}
    {{ x-param-text name="code" }}
    gui={
      text "Введите код скрипта и при желании доп. входные параметры.";
      render-params @script; 
    }
    x-patch-r @script->input1 @script->input2
    code=
`(n,coef,tenv) => {
  if (n != null && coef != null)
    tenv.setParam('theta', coef*(n*360/100)-180 );
  return () => {};
};`;  
  ;
};


//////////////

/// ну тут вопрос что входы хотелось бы из других объектов..
add_sib_item @geffect3d "effect3d-delta" "Размещение детей (delta)";
feature "effect3d_delta" {
  eff: geffect3d
  {{ x-param-slider name="dx" min=-10.0 max=10 step=0.1 }}
  {{ x-param-slider name="dy" min=-10.0 max=10 step=0.1 }}
  {{ x-param-slider name="dz" min=-10.0 max=10 step=0.1 }}
  dx=1 dy=0 dz=0
    gui={
      render-params @eff; 
    }
  
  element=@../..
  // нужен x-insert-children. тогда
  {
  find-objects-bf root=@eff->element features="node3d" recursive=false include_root=false
    | filter_geta "visible" 
    | repeater {
        rep: x-modify {
          effect3d-pos 
            x=(@rep->input_index * @eff->dx)
            y=(@rep->input_index * @eff->dy)
            z=(@rep->input_index * @eff->dz);
        };
      };
  };
};

/// ну тут вопрос что входы хотелось бы из других объектов..
add_sib_item @geffect3d "effect3d-colorize" "Раскраска по данным";
feature "effect3d_colorize" {
  eff: geffect3d
  dx=1 dy=0 dz=0
    gui={
      //render-params @d;
      dom_group {
        insert_children input=@.. list=@d->gui;
      };
      render-params @arrtocols;
    }
  element=@../..
  x-modify {
    x-set-params colors=@arrtocols->output;
    d: find-data-source-column init_input=(@eff->element | geta "input");
    arrtocols: arr_to_colors gui_title="Цвета" input=@d->output;
  };
};
