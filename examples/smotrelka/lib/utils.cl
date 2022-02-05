

register_feature name="params_to_df" {
  js code=`
    function refresh() {
       env.host.colnames = env.host.getParamsNames();
    }
    env.host.on('gui-added',refresh);
    refresh()
  `;
};

register_feature name="df_column_ref" {
  //param_ref crit_fn="(obj) => obj.colnames || []";
  crit_fn="(obj) => obj.colnames || []";
};

register_feature name="df_ref" {
  crit_fn="(obj) => {
  	return obj.getParamsNames().filter( (v) => obj.getParam(v)?.isDataFrame );
  }";
};

register_feature name="render-guis-nested" {
  rep: repeater opened=true {
    col: column {
          button 
            text=(compute_output object=@col->input code=`return env.params.object?.params.gui_title || env.params.object?.ns.name`) 
            cmd="@pcol->trigger_visible";

          pcol: column visible=true style="padding-left: 1em;" {
            render-params object=@col->input;

            find-objects pattern_root=@col->input pattern="** include_gui" 
               | render-guis;

            button text="Удалить" obj=@col->input {
              call target=@col->input name="remove";
            };
           };
         
        };
    };
};