load "ws-server misc new-modifiers"

ws-server port=8101 | cc-on { |io|
  let in=@io.0 out=@io.1
  // console-log "server new conn" @in @out
  read-value @in | console-log "privet"
  cc-on @in { |msg|
    console-log "server see" @msg
    read @out | set-cell-value (@msg.a + @msg.b)
  }
}

c: ws-client url="ws://localhost:8101" { |in out|
 cc-on @in { |msg|
   console-log "see reply" @msg
 }
 //read @c.out | set-cell-value (json a=1 b=2)
  write-value @out (json a=1 b=2)

  read 10 | repeater { |num|
    write-value @out (json a=(+ 5 @num) b=78)
    //m-eval @out.put (json a=(+ 5 @num) b=78)
  }
}
