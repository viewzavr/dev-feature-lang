load files=`
lib3d.js
elements.js
modifiers.js
materials.js
text-geom.js
linestrips.js
3d-formats/gltf/init.js
3d-formats/vrml/vr-vrml.js
3d-formats/obj/vr-obj.js
3d-formats/vtk-points/vr-vtk-points.js
`;

register_feature name="material_gui" {
    dom_group 
    {{
      link to=".->output_material" from=@matptr->output;
    }}
    {
        dom tag="h3" innerText="Material options";

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
