load "./eha.js misc new-modifiers"

/*
console-log "hello world" (timer-ms 1000)

timer-ms 1000 | object on_param_input_changed=(make-func { |cnt|
  console-log "process-like eha, cnt=" @cnt
})
*/

//console-log (timer-ms 1000 | get-cell "output" | get-cell-value)

//console-log ( create-object { timer-ms 1000 } | get-cell "output" | get-cell-value )

create-object { timer-ms 1000 } | get-cell "output" | c-on (make-func { |cnt|
  console-log "process-like eha on cell, cnt=" @cnt
})

ws-server on_message={ |msg|
  console-log @msg
}

c: ws-client
m_eval @c.send (json a=5 b=5)