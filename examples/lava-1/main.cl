load files="lib3dv3 csv params io gui render-params df misc scene-explorer-3d";
// todo: уметь загружать по спецификатору lib3dv3/gltf-format

    lavaparams: showparams {
      ptradius: param_slider min=0.0001 max=1 value=0.05 step=0.0001;
      slice_delta: param_float value=5;
      vtkfile: param_file value="http://127.0.0.1:8080/vis-data/lava/src/1_3_v0/ParticleData_Fluid_3370.vtk"
        ;
        // value="http://127.0.0.1:8080/vis-data/lava/src/05_1_v100/ParticleData_Fluid_5000.vtk";
        // "https://viewlang.ru/assets/lava2/ParticleData_Fluid_1192.vtk" 
      objfile: param_file value="http://127.0.0.1:8080/vis-data/lava/src/obj/rb_data_0_1.obj"
        ;
        // "http://viewlang.ru/assets/models/lava/rb_data_0_1.obj"
    };

/// рендеринг 3D сцены

rend: render3d bgcolor=[0.1,0.2,0.3] target=@view
{
    orbit_control;
    camera3d pos=[0,40,40] center=[0,0,0];

    text3d_one text="loading..." showparams;

    ////////////////////////////////////// подготовка данных лавы
    
    dat: load_file_binary file=@lavaparams->vtkfile
         | parse_vtk_points | compute_magnitude_col;

    // вычисляет колонку magnitude по формуле sqrt( vecolity0^2+vecolity1^2+vecolity2^2 )
    register_feature name="compute_magnitude_col" code=`
      env.onvalue("input",(df) => {
        
        if (!df || !df.isDataFrame) {
          env.setParam("output",[]);
          return;
        }
        
        let v0 = df.get_column( "velocity0" );
        let v1 = df.get_column( "velocity1" );
        let v2 = df.get_column( "velocity2" );
        if (!(v0 && v1 && v2)) {
          env.setParam("output",df);
          return;
        }

        df = df.clone();
        let arr = new Float32Array( df.get_length() );
        for (let i=0; i<arr.length; i++)
          arr[i] = Math.sqrt( v0[i]*v0[i] + v1[i]*v1[i] + v2[i]*v2[i] );
          
        df.add_column( "magnitude", arr, df.get_column_names().indexOf( "velocity2" )+1 );
        env.setParam("output",df);
      });
    `;

    ////////////////////////////////////// лава

    rep: repeater model=@selected_columns->output {
      pts: node3d {

        //aa2: @das_state | get name=@pts->input;

        @dat | ptsa: points radius=@lavaparams->ptradius 
        {{
           pos3d y=(compute_output in=@pts->modelIndex d=@lavaparams->slice_delta code=`return env.params.in*env.params.d`);
        }} 
        {{ 
           auto_scale size=100 input=@rend->output; 
        }}
        colors=( @dat | df_get column=@pts->modelData 
                      | arr_to_colors color_params guitext=@pts->modelData );

        text3d_one text=@pts->modelData {{
          box: compute_bbox input=@ptsa->output;
          pos3d pos=@box->max;
          //pos3d pos=(compute_output in=@box->center code=`return [env.params.in[0], env.params.in[1] + 5, env.params.in[2]]`);

          //pos3d y=(compute_output in=@pts->modelIndex code=`return env.params.in*5 + 90`) x=60 z=-130;
         }};
      };
        
    };

    ////////////////////////////////////// вулкан

    obj: load_file file=@lavaparams->objfile | parse_obj;

    @obj | mesh showparams {{ auto_scale size=100 input=@rend->output; }}
       {{ 
          rotate3d showparams;
          color3d color=[0,0.5,0] showparams;
       }} material = @me1->output_material;    
};



/// интерфейс пользователя gui

screen auto-activate {

  column padding="1em" style="z-index: 3; position:absolute;
    background: rgba(255,255,255,0.5);
    overflow-y: scroll;max-height: 100%;" {

    column {
    dom style="display: grid;  grid-template-columns: 1fr 1fr; max-width: 250px" {
      selected_columns:
      @dat->output 
      | get name="colnames"
      | repeater { checkbox text=@.->input; } 
      | monitor_all_params
      | timeout ms=1000
      | compute_output code=`
        env.onvalue("input",(arr) => {
          let res = [];
          arr.forEach( (rec) => {
            if (rec.params.value) res.push( rec.params.text );
          })
          env.setParam("output",res);
        })
      `;
    };

    find-objects pattern="** color_params" | repeater {
      rec: column {  
        button text=(@rec->input | get param="guitext") cmd=@rp->trigger_visible;
        rp: render-params object=@rec->input visible=false dom_style_paddingLeft="0.5em";
      }
    };
    };

    //find-objects pattern="** color_params" | render-guis;
    //find-objects pattern="** color_params" | render-guis button_features={ set_params text="555" };
    //find-objects pattern="** color_params" | render-guis button_features={ set_params text=(@..->object->text | get name="params.text" ) };

    find-objects pattern="** showparams" | render-guis with_features=true;



    bt: button text="get csv" {
      func {
        generate_csv input=(@dat | vtk_points_to_normalized_df) | download_file_to_user filename="lava.csv";
      };
    };

/*
    text text="Select column to colorize";
    cbcol: combobox values=(compute_output in=@dat->output code=`return env.params?.in?.colnames`);
*/

    //text text="Select material for surface";
    me1: material_generator_gui text="Surface look";
  };

  view: view3d style="position: absolute; width:100%; height: 100%; z-index:-2";

};

///////////////////// визуальная отладка

debugger_screen_r;

//////////////////// доп-ы
