load "misc new-modifiers set-params ws-server"

session-server (ws-json (ws-server /*{{ ws-logging prefix="srv" }}*/ )) on_connection={ |in out ws|
  console-log "server see conn"
  read @in | cc-on { |cmd reply|
    route @cmd
    privet={
      console-log "case 1"
      read @reply | put-value (+ "sam ti " @cmd)
    }
    hello={
      console-log "case 2"
      read @reply | put-value "mmm you sent hello"
    }
    default={
      console-log "unkown cmd" @cmd
    }
    // read @out | put-value (+ "comanda obrabotana " @cmd)
  }
}

c: remote-session (ws-json (ws-client {{ /*ws-logging prefix="client"*/ }})) on_connection={ |in out|
  console-log "client see conn"
  read @out | put-request "privet" | get-value | console-log "reply on privet is"
  read @out | put-request "hello" | cc-on { |resp|
    console-log "see response" @resp
  }
  read @in | cc-on { |msg| console-log "client see response msg" @msg }
}
//m_eval @c.send "privet" "vasya" | console-log "reply is"
//m_eval @c.send "hello" "vasya" | console-log "reply2 is"

feature "route" {
  c: object {
    insert_children input=@.. list=( (read @c | geta @c.0) or @c.default?)
  }
}
//можно сделать не insert-children a m_eval (make-func code=....)
