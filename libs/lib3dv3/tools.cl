register_feature name="material_gui" {
    dg: dom_group text="Material options"
    {{
      link to=".->output_material" from=@matptr->output;
    }}
    {
        dom tag="h3" innerText=@dg->text hhh;

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
   выход
     output - значение
   радиус это радиус сферы с центром в 0, в которую эти данные впишутся
*/
register_feature name="compute_data_radius" code=`
   env.feature("timers");
   env.setInterval( process,1000 );
   function process() {
      let r = 10;

      function rec(obj) {
        if (!obj) return;
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

      let tores = (v) => [v.x, v.y, v.z];

      env.setParam("min",tores(box.min) )
      env.setParam("max",tores(box.max) )

      var center = new THREE.Vector3();
      box.getCenter( center );
      env.setParam("center",tores(center) )
   }
`;
