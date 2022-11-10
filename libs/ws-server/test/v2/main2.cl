load "../websocket.js misc new-modifiers"

ws-server port=8101 on_message={ |ws msg|
  console-log "server see" @msg
  m-eval @ws.send (@msg.a + @msg.b)
}

c: ws-client url="ws://localhost:8101" on_message={ |ws msg|
 console-log "see reply" @msg
}

m_eval @c.send (json a=5 b=78)