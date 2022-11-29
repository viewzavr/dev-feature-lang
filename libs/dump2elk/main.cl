load "misc io"
load "./dump2elk.js"

args: process_args

//mk-file (process_args | geta 3)
mk-file @args.3

feature "mk-file" {
  x: object {
    //console-log @x->0
    let fname=@x.0
    console-log "loading file" @fname
    //load-file file=@fname | compalang | console-log-input "DUMP" | dump2uml | console-log-input "UML" | uml_url | console-log "click"
    let dump = (load-file file=@fname | compalang)
    
    // m-eval "(t) => JSON.stringify(t,null,' ')" @dump | console-log-input "DUMP"
    
    read @dump | dump2elk | console-log-input "ELKJSON"
  }
}
