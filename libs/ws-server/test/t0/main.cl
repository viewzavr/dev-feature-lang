load "ws-server misc new-modifiers"

ws-server port=8101 {{ ws-json-serialize }} on_connection={ |in out|
  //console-log "server new conn" @in @out
  read @in | get-cell-value | console-log "privet"
  read @in | cc-on { |msg|
    console-log "server see" @msg
    read @out | set-cell-value (@msg.a + @msg.b)
  }
}

c: ws-client url="ws://localhost:8101" {{ ws-json-serialize }} on_connection={ |in out|
  // console-log "client connected, out is" @out

  read @in | cc-on { |msg|
     console-log "see reply" @msg
  }

  read @out | set-cell-value (json a=1 b=2)

  read 10 | repeater { |num|
    read @out | set-cell-value (json a=@num b=10)
  }

}