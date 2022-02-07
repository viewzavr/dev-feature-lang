
/////////////////////////////////////////////////// mesh_visualizer0


register_feature name="mesh_visualizer0" {
   root: mesh input=@collected_df {

     collected_df: copy_params_to_obj {{dbg}} {
        link to=".->X" from=@input_data->X tied_to_parent=true;
        link to=".->Y" from=@input_data->Y tied_to_parent=true;
        link to=".->Z" from=@input_data->Z tied_to_parent=true;
     };

     connection object=@collected_df event_name="param_changed" root=@root code=`
       if (env.params.root) {
        env.params.root.signalTracked( "input" );
       }
     `;

     /*
     {
       call target=@root name="signalTracked"
       @root->signalTracked "input";
     }
     */

     input_data: include_gui {
       param_ref df_column_ref name="X";

       param_ref df_column_ref name="Y";
       param_ref df_column_ref name="Z";
     };
   };
};


/////////////////////////////////////////////////// mesh_visualizer

register_feature name="mesh_visualizer" {
   root: mesh {
     link to="..->input" from=@input_data->input;

     input_data: include_gui {
       param_ref df_ref name="input";
     };
   };
};

/////////////////////////////////////////////////// points_visualizer

register_feature name="points_visualizer" {
   root: points {
     link to="..->input" from=@input_data->input;

     input_data: include_gui {
       param_ref df_ref name="input";
     };
   };
};



