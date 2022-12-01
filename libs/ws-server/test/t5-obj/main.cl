load "misc ws-server"

ws-server {{ws-logging}} | ws-json | session-server on_connection={ |in out ws|
  //console-log 22
  object-on-server @in @out
  //mf-timeout 0
}

ws-client | ws-json | remote-session on_connection={ |in out|
  //mf-timeout 0
  //console-log 11 "client connected"
  //remote-object @in @out "read (2 + 2)" | console-log "Result"
  timer-ms 1000 | remote-object @in @out "@.->input? + 100" | console-log "remote result:"
//  remote-object @in @out "a: let x = 1 timer-ms 1000 | (read @a | get-channel 'x' | put-value (@x+1) | read @x) " | console-log "res"
  //remote-object @in @out "a: let x = 1 read @a | get-channel 'x' | put-value (@x+1) | pause-input" | console-log "res"
}

+ @.->input? 100 {{ hosting }}