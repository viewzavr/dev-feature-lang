load "ws-server misc new-modifiers"

ws-json (ws-server port=8101) on_connection={ |in out ws|
  //console-log "server new conn" @in @out @ws
  
  read @in | get-value | console-log "privet"
  read @in | cc-on { |msg|
    console-log "server see incoming" @msg
    //read @out | put-value (json orig=@msg sum=(@msg.a + @msg.b) | pause-input | console-log-input "making output")
    read @out | put-value (json orig=@msg sum=(@msg.a + @msg.b) | pause-input)
  }

}

c: ws-json (ws-client url="ws://localhost:8101") on_connection={ |in out|
  // console-log "client connected, out is" @out

  read @in | cc-on { |msg|
     console-log "client see reply" @msg
  }

  read @out | put-value (json a=1 b=2)

  read 10 | repeater { |num|
    read @out | put-value (json a=@num b=10)
  }

}