export function setup(vz, m) {
  vz.register_feature_set( m );
}

export function load_file( env ) {
  env.feature("load_file_func");
  //var empty_df = df.create();
  env.addFile("file");
  //env.linkParam("file","~->0")  

  //env.trackParam("file",go)
  //env.trackParam(0,go)

  //function go() {

  function actual_file_path() { return (env.params.file || env.params[0]) }

  env.monitor_values(["file",0], () => {
    let file = actual_file_path();
    //file ||= f0
    //let file = env.params.file || env.params[0]
    //    console.log("load-file: gonna load file from ",file,"env is",env.getPath());
    if (!file) {
      env.setParam("output","");
      return;
    }
    //env.setParam("output",df );
    // возможно стоит compute_path внедрить в load_file
    file = env.compute_path( file );

    //let rec_filename = file.name ? file.name 

    let root = env.findRoot();
    root.setParam( "loading_files", (root.params.loading_files || []).concat( file ) );

    env.loadFile( file,(text) => {
      root.setParam( "loading_files",root.params.loading_files.filter( f => f != file) );
      //console.log("load-file: file",file," loaded, text len is ",text.byteLength || text.length);
      
      if (actual_file_path() == file) // передаем только в случае если
        env.setParam("output",text );
      //else console.log('file is skipped - non actual');
    },(err) => {
      root.setParam( "loading_files",root.params.loading_files.filter( f => f != file) );
      console.error("load-file: file",file," load error",err);
      if (actual_file_path() == file) { 
        env.setParam("output","" );
      };// else console.log('file is skipped - non actual');
    });
    /* fetch не работает с файловыми объектами
    fetch( file ).then( (res) => res.text() ).then( (text) => {
      var df = CSV( text )
      env.setParam("output",df );
    });
    */
  })
}

export function load_file_binary( env ) {
  env.feature("load_file");

  env.loadFile = env.loadFileBinary;
}