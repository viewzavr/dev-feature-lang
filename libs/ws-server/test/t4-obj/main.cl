load "misc ws-server"

ws-server {{ws-logging}} | ws-json | session-server on_connection={ |in out ws|
  console-log 22
  object-on-server @in @out
}

ws-client | ws-json | remote-session on_connection={ |in out|
  console-log 11
  //remote-object @in @out "read (2 + 2) | console-log-input 'm'" | console-log "Result"
  remote-object @in @out "timer-ms 1000" | console-log "res"
}