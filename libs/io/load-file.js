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

    env.loadFile( file,(text) => {
      console.log("load-file: file",file," loaded, text len is ",text.length);
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