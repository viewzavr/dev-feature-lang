
// активирует применение модификаторов
feature "apply_old_modifiers" {
  x: object 
  {
     // подключаем модификаторы
     x-modify-list input=@x list=(find-objects-bf root=@x include_root=false "addon-object" depth=1 | filter_geta "visible")
  }
}

feature "compute_title" {
  r: object output=@q->output {
    q: m-eval "(t,a,b) =>
       {
          
          let ind = a.indexOf(t); 
          return b[ind];
       }" @r->key @r->types @r->titles;
  };
};

// todo это уходит
/*
feature "editable-addons" {
   eathing: object
   addons_list=(@addons_p | get_children_arr) // интерфейс с gui4addons.cl
   addons_container=@addons_p
   addons=[] // возможность задать аддоны через апи
   {{
     // активация аддонов из addons_p области
     x-modify-list input=@eathing list=(@addons_p | get_children_arr | filter_geta "visible");
     // внедрение доп. аддонов из параметров (апи режим)
     insert-children input=@addons_p list=@eathing->addons;
   }}
   {
     addons_p: object {
     }; // целенаправленно размещаются addon-ы в children, ибо оно сохранится в dump
   };
};
*/

// это запись о типе
feature "addon" {
  ai22: object type=@.->0
      title=( @ai22->1? or @ai22->type )
      crit=(m_lambda "() => true");
};

// это запись об экземпляре
feature "addon_object"

let addons_list =(find-objects-bf "addon")


geffect3d: feature {
  ef: addon_object 
      appropritate_addons = ( m_eval "(list,elem) => {
        return list.filter( it => it.params.crit( elem ) )
      }" @addons_list @ef->element)
      sibling_titles=(@ef->appropritate_addons | map_geta "title")
      sibling_types=(@ef->appropritate_addons | map_geta "type")
      element=@..

      title=(compute_title key=(detect_type @ef @ef->sibling_types) 
                         types=@ef->sibling_types 
                         titles=@ef->sibling_titles)
  {{ x-param-checkbox name="visible";
     x-param-option   name="visible" option="visible" value=false; 
  }}
  visible=true

  gui={
      render-params @ef;
  }
  ;
};

addon_base: feature 
{
  geffect3d;
};

feature "addon3d" {
  addon crit=(m_lambda "(obj) => obj.is_feature_applied && (obj.is_feature_applied('lib3d_visual'))");
};
feature "addon3d_node3d" {
  addon crit=(m_lambda "(obj) => obj.is_feature_applied && (obj.is_feature_applied('lib3d_visual') || obj.is_feature_applied('node3d'))");
};

addon "effect3d_blank" "-";
feature "effect3d_blank" {
  geffect3d;
};

addon3d "effect3d_additive" "Аддитивный рендеринг";

feature "effect3d_additive" 
  //addon title="Аддитивный рендеринг" //"(obj) => obj.material"
  //{{ import "" "THREE"; }}
  //{{ load THREE="../../../lib3d/three.js/build/three.module.js" }}
{
  ea: geffect3d 
      gui={render-params @ea; }
  ~x-patch-r 
    THREE=(import_js (resolve_url "../../../libs/lib3dv3/three.js/build/three.module.js"))
    code=`(tenv) => {
      //console.log("additive, tenv",tenv,env)
      let THREE=env.params.THREE;
      if (!THREE) return;
    
    let u1 = tenv.onvalue('material',(m)=> {
      //console.log("additive, tenv mat",tenv,m)
      //m.blending = additive ? env.THREE.AdditiveBlending : THREE.NormalBlending;
      m.blending = THREE.AdditiveBlending;
      //m.blending = THREE.MultiplyBlending;
    });
    return () => {
        u1();
        //let THREE=env.params.THREE;
        //if (!THREE) return;      
        if (tenv.params.material)
            tenv.params.material.blending = THREE.NormalBlending;
    };
  }
  `
  ;
};

addon3d "effect3d-opacity" "Прозрачность";
feature "effect3d_opacity" {
  eo: geffect3d
    {{ x-param-slider name="opacity" min=0 max=1 step=0.01; }}
    {{ x-param-slider name="alfa_test" min=0 max=1 step=0.01; }}
    alfa_test=0.5
    opacity=1.0
    gui={render-params @eo; }
    ~x-patch-r code=`(tenv) => {
          let u1 = 
          tenv.onvalue('material',(m)=> {
              m.transparent = true;
              m.opacity = env.params.opacity;

              m.alphaTest = env.params.alfa_test;
              m.needsUpdate = true;
            });
            return () => {
                u1();
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

addon3d "effect3d-zbuffer" "Настройки z-буфера";
feature "effect3d_zbuffer" {
  eo: geffect3d
    {{ x-param-checkbox name="depth_test"; }}
    {{ x-param-checkbox name="depth_write"; }}
    {{ x-param-checkbox name="size_attenuation"}}
    depth_test=true
    depth_write=true
    size_attenuation=true
    gui={render-params @eo; }
    ~x-patch-r code=`(tenv) => {
      let u1 = 
          tenv.onvalue('material',(m)=> {
              m.depthTest = env.params.depth_test;
              m.depthWrite = env.params.depth_write;
              m.sizeAttenuation=env.params.size_attenuation;
              m.needsUpdate=true;
            });
            return () => {
                u1();
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

addon3d "effect3d-fixed-pt-size" "Неизменный размер точек";
feature "effect3d-fixed-pt-size" {
  eo: geffect3d
    gui={render-params @eo; }
    ~x-patch-r code=`(tenv) => {
      let u1 = 
          tenv.onvalue('material',(m)=> {
              m.sizeAttenuation=false;
              m.needsUpdate=true;
            });
            return () => {
                u1();
                if (tenv.params.material) {
                  tenv.params.material.sizeAttenuation=true;
                  tenv.params.material.needsUpdate=true;
                }
            };
          }
    `;
  ;
};

addon3d_node3d "effect3d-pos" "Положение";
feature "effect3d_pos" {
  eo: geffect3d
    {{ x-param-float name="x"; }}
    {{ x-param-float name="y"; }}
    {{ x-param-float name="z"; }}
    x=0 y=0 z=0

    gui={ render-params @eo }
    ~x-patch-r code=`(tenv) => {
      //console.log("patching",tenv.getPath(),env.params.x,env.params.y,env.params.z);
        if (!tenv) debugger;
        let u1 = () => {};
        if (tenv)
            u1 = tenv.onvalue('output',(threejsobj)=> {
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
                u1();
                
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

addon3d_node3d "effect3d-scale" "Масштаб";
feature "effect3d_scale" {
  eo: geffect3d
    {{ x-param-float name="x"; }}
    {{ x-param-float name="y"; }}
    {{ x-param-float name="z"; }}
    x=1 y=1 z=1
    gui={render-params @eo; }
    ~x-js `(tenv) => {
          let u1 = tenv.onvalue('output',(threejsobj)=> {
              let x = env.params.x;
              let y = env.params.y;
              let z = env.params.z;
              if (isFinite(x)) threejsobj.scale.x=x;
              if (isFinite(y)) threejsobj.scale.y=y;
              if (isFinite(z)) threejsobj.scale.z=z;
            });
            return () => {
                u1();
                if (tenv.params.output) {
                  let threejsobj = tenv.params.output;
                  threejsobj.scale.set(1,1,1);
                }
            };
          }
    `;
  ;
};

addon3d "effect3d-sprite" "Внешний вид точек";
feature "effect3d_sprite" {
  eoa: geffect3d
    {{ x-param-combo name="sprite" values=["","spark1.png","ball.png","circle.png","disc.png","particle.png","particleA.png","snowflake1.png","snowflake3.png"]; }}
    sprite="ball.png"
    gui={render-params @eoa; }
    ~x-modify {
      //x-set-params texture_url=(if (@eoa->sprite != "") then={resolve_url (+ "sprites/" @eoa->sprite)});
      // этот if ненадежная схема - сначала успевает отработать resolve-url а потом уже if его грохает, но сигнал уже послан..
      // спокойная функц схема отрабатывает тут лучше.. забавно..
      x-set-params texture_url=(m_eval "(p) => p && p.length > 0 ? env.compute_path('sprites/'+p) : null " @eoa->sprite);
    }  
  ;
};

/// ну тут вопрос что входы хотелось бы из других объектов..
addon3d "effect3d-script" "Скрипт";
feature "effect3d_script" {
  script: geffect3d
    {{ x-param-float name="input1" }}
    {{ x-param-float name="input2" }}
    {{ x-param-text name="code" }}
    gui={
      text "Введите код скрипта и при желании доп. входные параметры.";
      render-params @script; 
    }
    ~x-patch-r @script->input1 @script->input2
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
addon "effect3d-delta" "Разместить детей повдоль";
feature "effect3d_delta" {
  eff: geffect3d
  {{ x-param-slider name="dx" min=-10.0 max=10 step=0.1 }}
  {{ x-param-slider name="dy" min=-10.0 max=10 step=0.1 }}
  {{ x-param-slider name="dz" min=-10.0 max=10 step=0.1 }}
  dx=0 dy=0 dz=0
    gui={
      render-params @eff; 
    }
  
  // нужен x-insert-children. тогда
  {
  //find-objects-bf root=@eff->element features="node3d" recursive=false include_root=false
  find-objects-by-crit "node3d, lib3d_visual" root=@eff->element recursive=false include_root=false depth=1
    | pass_input_if @eff->visible default=[]
    | filter_geta "visible"
    | repeater { |child_obj input_index|
        @child_obj | x-modify {
          effect3d-pos 
            x=(@input_index * @eff->dx)
            y=(@input_index * @eff->dy)
            z=(@input_index * @eff->dz)
            element=@child_obj
            ;
        };
      };
  };
};

/// решил сделать такой модификатор для слоя, т.к. тогда "приложения" могут добавлять его в слой
/// и через это управлять поведением камеры.
addon "addon-map-control" "Управление камерой - режим карты"

feature "addon-map-control" {
  vp: geffect3d 
     title = "Управление камерой - режим карты"
     ~have-scene-env
     scene_env={ |show_3d_scene|
       
       //console-log "privet medved" @show_3d_scene
       if @vp.visible {
         list @show_3d_scene | x-modify {
           x-set-params camera_control={ |renderer camera target_dom| 
              map-control camera=@camera target_dom=@target_dom renderer=@renderer damping=@vp.damping
           }
         }
       }
     }
     damping=true
     gui={ paint-gui @vp filter=["main"] }
     {
      gui {
        gui-tab "main" {
          gui-slot @vp "damping" gui={ |in out| gui-checkbox @in @out }
        }
      }
     }
}

/*
addon3d "effect3d-debug" "Отладка";
feature "effect3d_debug" {
  eff: geffect3d
  {{ x-param-cmd name="Запустить js отладчик" cmd="debugger" }}
};
*/

/// ну тут вопрос что входы хотелось бы из других объектов..
addon3d "effect3d-colorize" "Раскраска по данным";
feature "effect3d_colorize" {
  eff: geffect3d
  
    gui={
      //render-params @d;
      dom_group
      {
        insert_children input=@.. list=@d->gui;
      };
      render-params @arrtocols;
      // todo здесь флаг надо ли смешивать с цветом color или полностью свой делать

      d4: show_palette 
          style_p = "padding: 0px; margin: 0.1em;"
          values=@arrtocols->minmax 
          colors=(m_eval @arrtocols->colorize_data (generate_arr_from_minmax @arrtocols->minmax))
          title=(@eff->element | geta "title" default="");

      render-params @eff;          
    }
  //{{ x-param-combo name="color_mix_mode" values=[ false,true ] titles=["Смешать с основным цветом","Не смешивать"] }}
  //{{ x-add-cmd2 "Вывести цвета как есть" (m_lambda "(objs) => (objs || []).forEach( obj => obj.setParam('color',[1,1,1]) )" @eff->output?) }}
  {{ x-param-checkbox name="show_palette_on_screen" }}

  // element=@../.. // жуткий хак - перетащен наружу
  init_input=(@eff->element | geta "input" default=null) 
  base_color=(@eff->element | geta "color" default=[0,1,1]) 
  show_input=true
  output_column_name=@d->output_column_name

  ~x-modify {
    x-set-params colors=@arrtocols->output ;
    /*
    if (@eff->color_mix_mode) then={
        x-set-params color=[1,1,1];
    };
    */
    d: find-data-source-column
             //init_input=@eff->init_input
             show_input=@eff->show_input
             source_df=@eff->init_input
             selected_column=@eff->selected_column?
             ;

    arrtocols: arr_to_colors 
        gui_title="Цвета" 
        input=@d->output 
        datafunc=@eff->datafunc?
        base_color=@eff->base_color
    ;

    if (@eff->show_palette_on_screen?) then={
      x-set-params scene2d=@d2;
      d2: show_palette 
            style_p = "padding: 0px; margin: 0.1em;"
            values=@arrtocols->minmax 
            colors=(m_eval @arrtocols->colorize_data (generate_arr_from_minmax @arrtocols->minmax))
            title=(m_eval `(title,colname) => {
              title ||= "";
              if (title.indexOf(colname) < 0)
                title += ": " + colname;
              return title;
            }` (@eff->element | geta "title" default="") @d->output_column_name);
    };

  };
};

// текущее
feature "generate_arr_from_minmax" {
  root: object output=@la->output {
  la: m_eval "(mm)=> {
                let res = [];
                if (! (Array.isArray(mm) && mm.length >= 2) ) return res;
                let diff = mm[1]-mm[0];
                if (!isFinite(diff)) return res;
                for (let i=0; i<100; i++)
                  res.push( mm[0] + i * diff / 99 );
                return res;
           }" @root->0;
   };
};


// вход:
// values - массив из 2х, минимальное и максимальное значение
// colors - массив цветов
// title - надпись поверх палитры
feature "show_palette" 
{
  d2: column 
    style="border: 1px solid black;" 
    values=[0,1] 
    colors=[0,0,0, 1,0,1]
    title=""
  {

       canv: dom tag="canvas" dom_attr_width='300' dom_attr_height=30
            ;

       // чет некрасиво плюс сьезжает чет.     
       //text @d2->title style="color: white; position: absolute; left:1em;";

       row style="background: #555555; justify-content: space-between; color: white; padding-left: 2px; padding-right: 1px;" 
       {
         text (m_eval "(a) => a.toFixed(4)" (@d2->values | geta 0));
         text (m_eval "(a) => ((a[0]+a[1])/2).toFixed(4)" @d2->values);
         text (m_eval "(a) => a.toFixed(4)" (@d2->values | geta 1));
       };
       
       row style="background: #555555; justify-content: space-around; color: white;" 
       {
          text @d2->title;
       };
       

    // http://fabricjs.com/demos/   
    // lottie

    m_eval `(canvas,sz,colors) => {
        var context = canvas.getContext("2d");
        var grd = context.createLinearGradient(0, 0, sz.width, 0);

        /// работа с цветом....
        // c число от 0 до 255
        function componentToHex(c) {
            if (typeof(c) === 'undefined') {
              debugger;
            }
            var hex = c.toString(16);
            return hex.length == 1 ? "0" + hex : hex;
        }
            
        // r g b от 0 до 255
        function rgbToHex(r, g, b) {
            return "#" + componentToHex(r) + componentToHex(g) + componentToHex(b);
        }
            
        // triarr массив из трех чисел 0..1
        function tri2hex( triarr ) {
           return rgbToHex( Math.floor(triarr[0]*255),Math.floor(triarr[1]*255),Math.floor(triarr[2]*255) )
        }

        if (colors.length <= 3)
          grd.addColorStop(0, tri2hex( colors.length == 3 ? colors : [1,1,1] ) );
        else
        {  
          for (let i=0; i<colors.length; i+=3) {
            grd.addColorStop( 
                i / (colors.length-3), 
                tri2hex( [colors[i],colors[i+1],colors[i+2]] )
                );
          }
        }
        //grd.addColorStop(0, tri2hex( [1,0,0] ) );
        //grd.addColorStop(1, tri2hex( [1,0,1] ));

        // Fill with gradient
        context.fillStyle = grd;
        context.fillRect(0, 0, sz.width, sz.height );
/*
    // set line stroke and line width
    context.strokeStyle = 'red';
    context.lineWidth = 5;

    // draw a red line
    context.beginPath();
    context.moveTo(0, 0);
    context.lineTo(256, 100);
    context.stroke();
*/    

    };` @canv->dom (get_dom_size @canv->dom) @d2->colors;
  };     
};