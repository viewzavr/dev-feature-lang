load "params";

feature "astra-vis-1" {
	avp: visual_process
	title="Визуализация звёзд N1"
	gui={
		render-params @avp;
		find-objects-bf "lib3d_visual" root=@scene | render-guis;
	}
	current_file="http://127.0.0.1:8080/public_local/data/gout_000.dat"
	{{ x-param-file name="current_file"; }}

	lines_loaded=(@loaded_data->output | geta "length")
	{{ x-param-label name="lines_loaded"}}

	scene3d=@scene->output

	{
      	loaded_data: load-file file=@avp->current_file | joinlines "X Y Z" @.->input | parse_csv separator="\s+";

		scene: node3d visible=@avp->visible force_dump=true
		{
		   // вообще может оказаться что это будет отдельный визуальный процесс - "антураж"
		   ab: axes_box size=10;

		   @loaded_data->output | pts: points;

		   //console_log "positions are" @pts->positions;
		};
      	
	}
};

register_feature name="joinlines" code=`
  env.on("param_changed",(name) => {
    if (name == "output") return;
    compute();
  });
  
  function compute() {

    let count = env.params.args_count;
    let arr = [];
    for (let i=0; i<count; i++)
      arr.push( env.params[ i ] );
    let res = arr.join( env.params.with || "\n" ); // по умолчанию пустой строкой
    env.setParam("output",res );
  };
  
  compute();
`;