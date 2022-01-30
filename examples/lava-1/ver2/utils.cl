// вычисляет колонку magnitude по формуле sqrt( vecolity0^2+vecolity1^2+vecolity2^2 )
// вход input, df
// выход output, df

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

// рисует слой точек
// вход: input - df с данными
// выход: output, threejs-узел

register_feature name="vtk_points_layer" {
  root: 
    columns=(@.->input | get name="colnames")
    selected_data = (get input=@.->input name=@.->selected_column)
    output=@visual->output
    
    {{
      selected_column: param_combo values=@.->columns index=0;
    }}
    gui={
      column {
        render_params object=@root;
        render_params object=@visual;
      };
    }
  {
      visual: node3d  {

        //data_filter: include_gui gui_title="Input data"

        //aa2: @das_state | get name=@pts->input;

        @root->input | ptsa: points include_gui gui_title="Points" //radius=@lavaparams->ptradius 
        {{
           // pos3d y=(compute_output in=@pts->modelIndex d=@lavaparams->slice_delta code=`return env.params.in*env.params.d`);
        }}
        {{
           auto_scale size=100 input=@rend->output; 
        }}
        colors=( @root->selected_data | arr_to_colors include_gui gui_title="Coloring" );

        text3d_one text=@root->selected_column include_gui gui_title="Text" {{
          box: compute_bbox input=@ptsa->output;
          pos3d pos=@box->max;
          //pos3d pos=(compute_output in=@box->center code=`return [env.params.in[0], env.params.in[1] + 5, env.params.in[2]]`);
          //pos3d y=(compute_output in=@pts->modelIndex code=`return env.params.in*5 + 90`) x=60 z=-130;
         }};
      };
  }
}    