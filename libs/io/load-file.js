export function setup(vz, m) {
  vz.register_feature_set( m );
}

export function load_file( env ) {
  env.feature("load_file_func");
  //var empty_df = df.create();
  env.addFile("file");
  env.onvalue("file",(file) => {
    console.log("load-file: gonna load file from ",file);
    //env.setParam("output",df );
    // возможно стоит compute_path внедрить в load_file
    file = env.compute_path( file );

    let root = env.findRoot();
    root.setParam( "loading_files", (root.params.loading_files || []).concat( file ) );

    env.loadFile( file,(text) => {
      root.setParam( "loading_files",root.params.loading_files.filter( f => f != file) );
      console.log("load-file: file",file," loaded, text len is ",text.length);
      env.setParam("output",text );
    },(err) => {
      root.setParam( "loading_files",root.params.loading_files.filter( f => f != file) );
      console.error("load-file: file",file," load error",err);
      env.setParam("output","" );
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
  env.feature("load_file_func");
  //var empty_df = df.create();
  env.addFile("file");
  env.onvalue("file",(file) => {
    console.log("load-file: gonna load file from ",file);
    //env.setParam("output",df );
    // возможно стоит compute_path внедрить в load_file
    file = env.compute_path( file );

    env.loadFileBinary( file,(text) => {
      console.log("load-file: file",file," loaded, byte len is ",text.byteLength);
      env.setParam("output",text );
    },(err) => {
      console.error("load-file: file",file," load error",err);
      env.setParam("output","" );
    });
    /* fetch не работает с файловыми объектами
    fetch( file ).then( (res) => res.text() ).then( (text) => {
      var df = CSV( text )
      env.setParam("output",df );
    });
    */
  })
}