load "misc io"
load "./dump2uml.js"

args: process_args

//mk-file (process_args | geta 3)
mk-file @args.3

feature "mk-file" {
  x: object {
    //console-log @x->0
    let fname=@x.0
    console-log "loading file" @fname
    load-file file=@fname | compalang | console-log-input "DUMP" | dump2uml | console-log-input "UML" | uml_url | console-log "click"
  }
}
