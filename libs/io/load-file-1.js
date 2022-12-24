export function setup( vz,m ) {
    vz.register_feature( "load_file_func",load_file_func );
}
export function load_file_func(env) {
    env.loadFile = loadFile;
    env.loadFileBinary = loadFileBinary;
}

////////////////////// feature
// flag that data is loading
// this is used to pause animation


/*
function setFileProgress( filename, msg, percent, callback )
{
}
*/

function file_on() {
/*    
  setTimeout( function() {
    //qmlEngine.rootObject.propertyComputationPending = qmlEngine.rootObject.propertyComputationPending+1;
    vzPlayer.setParam( "file_pending_count", (vzPlayer.params.file_pending_count||0)+1 )
  }, 0);
*/  
}

function file_off() {
/*
  setTimeout( function() {
    vzPlayer.setParam( "file_pending_count", (vzPlayer.params.file_pending_count||0)-1 )
    //qmlEngine.rootObject.propertyComputationPending = qmlEngine.rootObject.propertyComputationPending-1;
  }, 0);
*/  
}

/////////////////////// file io
    
function loadFile( file_or_path, handler, errhandler, setFileProgress=()=>{} ) {
    //formatSrc?
    return loadFileBase( (file_or_path), true, handler, errhandler, setFileProgress );
}
function loadFileBinary( file_or_path, handler, errhandler, setFileProgress=()=>{} ) {
    return loadFileBase( (file_or_path), false, handler, errhandler, setFileProgress );
}

function loadFileBase( file_or_path, istext, handler, errhandler, setFileProgress ) {
    // таким образом в url можно посадить и FileSystemFileHandle при желании
    if (file_or_path.url)
        file_or_path = file_or_path.url;

    if (typeof(FileSystemFileHandle) !== "undefined" && file_or_path instanceof FileSystemFileHandle) {
        file_or_path.getFile().then( file => {
            loadFileBase( file, istext, handler, errhandler,setFileProgress );
        })
        return;
    }


    if (typeof(File) !== "undefined" && file_or_path instanceof File) {
        // http://www.html5rocks.com/en/tutorials/file/dndfiles/
        setFileProgress( file_or_path.name,"loading");
        file_on();

        var reader = new FileReader();

        window.setTimeout( function() {

            reader.onload = function () {
                //console.log(reader.result);
                setFileProgress( file_or_path.name,"parsing");
                window.setTimeout( function() {
                    try {
                      handler( reader.result, file_or_path.name );
                    } catch (err) {
                      console.error(err);
                      setFileProgress( file_or_path,"PARSE ERROR");
                      if (errhandler) errhandler(err,file_or_path);
                      file_off();
                      return;
                    }
                    setFileProgress( file_or_path.name );
                    file_off();
                },5 );

            };

            if (istext)
                reader.readAsText( file_or_path );
            else
                reader.readAsArrayBuffer( file_or_path );

        }, 5); //window.setTimeout

        var result = {};
        result.abort = function() { reader.abort(); setFileProgress( file_or_path.name ); file_off(); }
        result.stoploading = function() { reader.abort(); setFileProgress( file_or_path.name ); file_off(); }
        return result;
    }
    else
    {
        if (file_or_path && file_or_path.content) {
          handler( file_or_path.content, "data" );
          return;
        }
        
        var payload;
        if (file_or_path && file_or_path.path) {
          payload = file_or_path.payload;
          file_or_path = file_or_path.path;
        }
        
        if (file_or_path && file_or_path.length > 0) {
            if (file_or_path.match(/^wss?:\/\//))
              return loadFileWebsocket( file_or_path, istext, handler, errhandler );
        
            setFileProgress( file_or_path,"loading");
            file_on();

            let opts = { credentials:"include" }
            if (payload) {
                opts.method = 'POST'
                opts.headers ||= {}
                opts.headers['Content-Type'] = 'application/json;charset=utf-8'
                opts.body = JSON.stringify(payload)
                // todo поддержать и другие вещи. типа blob
                // https://learn.javascript.ru/fetch
            }

            const controller = new AbortController()
            opts.signal = controller.signal

            fetch( file_or_path, opts )
            .then(handleErrors)
            .then( res => {
                let f = istext ? res.text.bind(res) : res.arrayBuffer.bind(res)
                f().then( data => {
                    setFileProgress( file_or_path,"parsing");
                    file_off();
                    handler( data, file_or_path );                    
                })
            })
            .catch(error => {              
              //console.log("fetch load error",error );//, "message=", error.message);
              setFileProgress( file_or_path, "RESPONSE ERROR" );

              if (errhandler) errhandler(error, file_or_path);

              setTimeout( function() {
                setFileProgress( file_or_path );
              }, 25000 ); // не сразу убирать сообщение       
            } );

            var result = {};
            result.abort = function() { controller.abort(); setFileProgress( file_or_path ); file_off(); }
            result.stoploading = function() { controller.abort(); setFileProgress( file_or_path ); file_off(); }
            return result;

            function handleErrors(response) {
                if (!response.ok) {                    
                    throw Error(response.statusText || "[no status]");
                }
                return response;
            }
            
        }
        else
        {
            if (errhandler) errhandler(null, file_or_path);
        }

    }
} 

function loadFileWebsocket( path, istext, handler, errhandler ) {
  // https://learn.javascript.ru/websockets
  var socket = new WebSocket( path );
  socket.onmessage = function(event) {
    handler( event.data );
  };
  
  socket.onerror = function( event ) {
    setFileProgress( path,"WEBSOCKET ERROR");
      setTimeout( function() {
         setFileProgress( path );
       }, 25000 );
    if (errhandler)
      errhandler(event,path);
  }
  var result = {};
  result.abort = function() { socket.close(); }
  result.stoploading = function() { socket.close() }
  return result;
}


