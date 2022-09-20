register_feature name="material_generator_gui" {
    dg: dom_group text="Material options"
    {{
      link to=".->output_material" from=@matptr->output;
    }}
    {
        dom tag="h3" innerText=@dg->text;

        mattabs: tabview index=4 { 
          tab text="Basic" { render-params object=@m1;}; 
          tab text="Lambert" { render-params object=@m2;};
          tab text="Phong" { render-params object=@m3;};
          tab text="Std" { render-params object=@m4;};
          tab text="PBR" { render-params object=@m5;};
        };
        m1: mesh_basic_material;
        m2: mesh_lambert_material;
        m3: mesh_phong_material;
        m4: mesh_std_material;
        m5: mesh_pbr_material;

        matptr: mapping values=["@m1->output","@m2->output","@m3->output","@m4->output","@m5->output"] input=@mattabs->index;
    }    
    ;
};

/* вычисляет "радиус" данных
   входы:
     input - входной threejs объект (дерево) для анализа
     except - исключить объект из расчетов
   выход
     output - значение
   радиус это радиус сферы с центром в 0, в которую эти данные впишутся
*/
register_feature name="compute_data_radius" code=`
   env.feature("timers");
   env.setInterval( process,1000 );
   function process() {
      let r = 10.111;

      function rec(obj) {
        if (!obj) return;
        if (obj == env.params.except) return;

        if (obj.geometry && obj.geometry.boundingSphere) {
          var s = obj.geometry.boundingSphere;
          var q = s.radius + Math.max( Math.abs(s.center.x),Math.abs(s.center.y),Math.abs(s.center.z) );
          if (q > r) r = q;
        }
        if (obj.children)
        for (let c of obj.children)
          rec( c )
      }

      
      rec( env.params.input );
      //console.log("compute_data_radius rrrrr=",r)

      env.setParam("output",r);
   }
`;

/* вычисляет коэффиц масштабирования в зависимости от данных
   входы:
     size - желаемый итоговый размер
     input - входной threejs объект (дерево) для анализа
   выход
     output - значение  
*/

register_feature name="compute_auto_scale" {
  size=100 
  compute_output
  data_radius=(compute_data_radius input=@.->input) 
  code=`
    return env.params.size / env.params.data_radius;
  `;
};

register_feature name="auto_scale" {
  as: scale3d size=100 coef=(compute_auto_scale input=@.->input size=@.->size);
  // input=@.->output; // тогда можно цепляться к объектам
};

/////////////
// рассчитывает фактический п-у занимаемый объектом на сцене итого (в ск сцены после всех сдвигов масштабов)
// выход: min,max,center - координаты п-у, тройки чисел [x,y,z]

register_feature name="compute_bbox" code=`
   env.feature("timers");
   env.setInterval( process,1000 ); // пока так
   function process() {
      var box = new THREE.Box3();

      box.setFromObject( env.params.input );
      //env.setParam("output",box);
      //console.log("bbox computed:",box);

      let tores = (v) => [v.x, v.y, v.z];

      env.setParam("min",tores(box.min) )
      env.setParam("max",tores(box.max) )

      var center = new THREE.Vector3();
      box.getCenter( center );
      env.setParam("center",tores(center) )
   }
`;

utils: import_js (resolve_url "utils.js");
feature "tri2hex" {
  k: output=@mmm->output input=@.->0 {
    mmm: m_eval "(c,utils) => utils.tri2hex(c)" @k->input @utils->output;
  };
};

/*
feature "tri2hex" {
  k: output=@me->output {
    me: m_eval `(c) => {
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
        return tri2hex( c );
          }` @k->input;
 };
};
*/

//THREEJS: import_js (resolve_url "three.js/build/three.module.js");

register_feature name="get_coords_bbox" 
   // imports={ THREEJS: import_js .... } 
   //imports={ THREEJS: "three.js/build/three.module.js" }
   //THREEJS=@THREEJS->output
   // {{ feature_import_js "THREE" "three.js/build/three.module.js" }}
   threejspath=(resolve_url "three.js/build/three.module.js")
code=`
   env.feature("timers");

   //let THREEJS = feature_env.params.THREEJS;
   
   import( feature_env.params.threejspath ).then( (THREE) => {

   env.setInterval( process,1000 ); // пока так
   function process() {
      
      let threejs_obj = env.params.input;
      let geom = threejs_obj?.geometry;

      if (!geom) {
        env.setParam("min",[0,0,0]);
        env.setParam("max",[0,0,0]);
        env.setParam("center",[0,0,0]);
        return;
      }

      if (!geom.boundingBox)
         geom.computeBoundingBox();

      let box = geom.boundingBox;

      let tores = (v) => [v.x, v.y, v.z];

      //console.log("AFVSDFVDSFV 111",box);

      env.setParam("min",tores(box.min) )
      env.setParam("max",tores(box.max) )

      var center = new THREE.Vector3();
      box.getCenter( center );
      env.setParam("center",tores(center) )
   }

   });
`;

/* вроде пока не нужна
register_feature name="compute_bsphere" code=`
   env.feature("timers");
   env.setInterval( process,1000 ); // пока так
   function process() {
      let threejs_obj = env.params.input;
      if (!threejs_obj) {
        env.setParam("min",[0,0,0]);
        env.setParam("max",[0,0,0]);
        env.setParam("center",[0,0,0]);
        env.setParam("radius",0);
        return;
      }

      var box = new THREE.Box3();

      box.setFromObject( env.params.input );
      //env.setParam("output",box);
      //console.log("bbox computed:",box);

      let tores = (v) => [v.x, v.y, v.z];

      env.setParam("min",tores(box.min) )
      env.setParam("max",tores(box.max) )

      var center = new THREE.Vector3();
      box.getCenter( center );
      env.setParam("center",tores(center) )
   }
`;
*/