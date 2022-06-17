// задел на будущее для отображения процентов и тп

export function setup(vz, m) {
  vz.register_feature_set( m );
}

function mkFileProgress( env,file ) {

  let root = env.findRoot();

  let rec = [file,""];
  root.params.loading_files ||= [];
  root.params.loading_files.push( rec );
  root.signalParam( "loading_files" );
  //root.setParam( "loading_files", (root.params.loading_files || []).concat( rec ) );

  function forget() {
    root.setParam( "loading_files",root.params.loading_files.filter( f => f != rec ) );
  }

  return function setFileProgress( filename, msg, percent, callback )
  {
    if (msg) {
      rec[1] = msg;
      //console.log(rec)
      console.log( root.params.loading_files )
      root.signalParam( "loading_files" );
    }
    else
    {
      console.log("forgetting")
      forget();
      console.log(root.params.loading_files)
    };
  }

};

export function load_file( env ) {
  env.feature("load_file_func");
  //var empty_df = df.create();
  env.addFile("file");

  env.trackParam("file",(file) => {
    console.log("load-file: gonna load file from ",file,"env is",env.getPath());
    if (!file) {
      env.setParam("output","");
      return;
    }
    //env.setParam("output",df );
    // возможно стоит compute_path внедрить в load_file
    file = env.compute_path( file );

    let progress = mkFileProgress(env,file);

    env.loadFile( file,(text) => {
      console.log("load-file: file",file," loaded, text len is ",text.length);
      if (env.params.file == file) 
        env.setParam("output",text );
      else console.log('file is skipped - non actual');
    },(err) => {
      console.error("load-file: file",file," load error",err);
      if (env.params.file == file) { 
        env.setParam("output","" );
      } else console.log('file is skipped - non actual');
    }, progress );
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