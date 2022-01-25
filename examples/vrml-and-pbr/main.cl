load files="lib3dv3 csv params io gui render-params df
            scene-explorer-3d
            ";
//load files="gui";

mainparams: {
  cb1: param_combo values=["https://viewlang.ru/dubins/data/1-mnojestva.cdb/Symm-232.vrml",
                            "https://viewlang.ru/dubins/data/1-mnojestva.cdb/Symm-100.vrml"];
  f1:  param_file value=@cb1->value;
       //param_label name="selected_file" value=@f1->value;
};

vrmlobject: load-file file=@mainparams->f1 | parse_vrml;

debugger_screen_r;
 
mainscreen: screen auto-activate padding="1em" {

  column style="z-index: 3; position:absolute; background-color: rgba(255,255,255,0.7);" padding="0.5em" gap="1em" {
    dom tag="h3" innerText="Параметры" style="margin-bottom: 0.3em;";
    render-params object=@mainparams gap="1em";

    //render-params object=@select_mat;

    mattabs: tabview { 
      tab text="Basic" { render-params object=@m1;}; 
      tab text="Lambert" { render-params object=@m2;}; 
      tab text="Phong" { render-params object=@m3;}; 
      tab text="PBR" { render-params object=@m4;}; 
    };

    find-objects pattern="** manage_too" | console_log | render-guis;
/*    
    text text="M1";
    render-params object=@m1;
    text text="M2";
    render-params object=@m2;

    column {
      text text="Material options"
      find-objects pattern="** mat1" | console_log | render-guis;
    };
*/    
    
  };

  v1: view3d style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2";

  r1: render3d 
      bgcolor=[0.1,0.2,0.3]
      target=@v1
  {
    camera3d pos=[0,0,100] center=[0,0,0];
    orbit_control;

    @vrmlobject | vrml_render: render_vrml {{ dbg }} {{ scale3d coef=0.004 }}
    {{
      link to=".->material" from=@matptr->output;
    }};

    render-normals: render_normals input=@vrml_render manage_too;

    points positions=[0,0,0, 50,0,0, 0,50,0 ];

/*
    mesh positions=[0,0,0, 50,0,0, 0,50,0 ] {{
      link to=".->material" from=@matptr->output;
      //material=@curmat->output;
    }}
    ;
*/    


  };
  
};

/////////////////////////////////
m1: mesh_basic_material mat1;
m2: mesh_lambert_material mat1;
m3: mesh_phong_material mat1;
m4: mesh_pbr_material mat1;

matptr: mapping values=["@m1->output","@m2->output","@m3->output","@m4->output"] input=@mattabs->index;

/*
select_mat: {
  cbp: param_combo values=["Basic","Lambert","Phong","PBR"];
};
*/