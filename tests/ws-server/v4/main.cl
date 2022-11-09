load "misc new-modifiers set-params ws-server"

session-server (ws-server {{ ws-logging }}) { |comm|
  read @comm | get-event-cell "message" | cc-on { |reply cmd arg|
    route @cmd
    privet={
      console-log "case 1"
      read @reply | set-cell-value (+ "sam ti " @arg)
    }
    hello={
      console-log "case 2"
      read @reply | set-cell-value "mmm"
    }
    default={
      console-log "unkown cmd" @cmd
    }
  }
}

c: remote-session (ws-client {{ ws-logging }})
m_eval @c.send "privet" "vasya" | console-log "reply is"
m_eval @c.send "hello" "vasya" | console-log "reply2 is"

feature "route" {
  c: object {
    insert_children input=@.. list=( (read @c | geta @c.0) or @c.default?)
  }
}
//можно сделать не insert-children a m_eval (make-func code=....)