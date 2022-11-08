load "misc new-modifiers set-params ws-server"

session-server (ws-server {{ ws-logging }}) { |comm|
  read @comm | get-event-cell "message" | cc-on { |ws cmd arg|
    console-log "ok incoming message, cmd=" @cmd
    if (@cmd == "privet") {
      "sam ti " @arg
    }
    else
    {
      console-log "unkown cmd" @cmd
    }
  }
}

c: remote-session (ws-client {{ ws-logging }})
m_eval @c.send "privet" "vasya"