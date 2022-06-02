// метка для объектов для которых добавить визуальное управление добавками

feature "editable-addons" {
   addons_container=@xxx
   {{
     x-modify-list input=@main list=(@xxx | get_children_arr | filter_geta "visible" );
   }}
   {
     xxx: {}; // целенаправленно в children ибо оно сохранится в dump
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
feature "effect3d_additive" {
  ea: geffect3d gui={render-params @ea; }
  x-patch-r code=`(tenv) => {
    tenv.onvalue('material',(m)=> {
      //m.blending = additive ? THREE.AdditiveBlending : THREE.NormalBlending;
      m.blending = THREE.AdditiveBlending;
      //m.blending = THREE.MultiplyBlending;
    });
    return () => {
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
    {{ x-param-slider name="value" min=0 max=1 step=0.01; }}
    value=1
    gui={render-params @eo; }
    x-patch-r code=`(tenv) => {
          tenv.onvalue('material',(m)=> {
            m.transparent = true;
              m.opacity = env.params.value;
            });
            return () => {
                if (tenv.params.material)
                  tenv.params.material.transparent = false;
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
    depth_test=true
    depth_write=true
    gui={render-params @eo; }
    x-patch-r code=`(tenv) => {
          tenv.onvalue('material',(m)=> {
              m.depthTest = env.params.depth_test;
              m.depthWrite = env.params.depth_write;
            });
            return () => {
                if (tenv.params.material) {
                  tenv.params.material.depthTest = true;
                  tenv.params.material.depthWrite = true;
                }
            };
          }
    `;
  ;
};

add_sib_item @geffect3d "effect3d-pos" "Положение в пространстве";
feature "effect3d_pos" {
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
              if (isFinite(x)) threejsobj.position.x=x;
              if (isFinite(y)) threejsobj.position.y=y;
              if (isFinite(z)) threejsobj.position.z=z;
            });
            return () => {
                if (tenv.params.output) {
                  let threejsobj = tenv.params.output;
                  threejsobj.position.set(0,0,0);
                }
            };
          }
    `;
  ;
};