load "./websocket.js misc ./remote2.cl"

c: ws-client url="ws://localhost:8100"
// on_open=(m_lambda "() => console.log('handl: opened')")

// m-eval "(cc) => { console.log('sending'); cc(555) }" @c.send
// console-log "hello" @c.send

remote-object @c "+ 2 2" | console-log "reply is"
