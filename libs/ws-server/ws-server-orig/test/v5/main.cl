load "misc new-modifiers set-params ws-server"

session-server (ws-server {{ ws-logging }}) { |comm|
  read @comm | get-event-cell "message" | cc-on { |ws cmd arg|
    switch {
      case (@cmd == "privet") {
         console-log "case 1"
         read (+ "sam ti " @arg)
      }
      case (@cmd == "hello") {
        console-log "case 2"
        "mmm"
      }
      default {
        console-log "unkown cmd" @cmd
      }
    }
  }
}

c: remote-session (ws-client {{ ws-logging }})
m_eval @c.send "privet" "vasya"
