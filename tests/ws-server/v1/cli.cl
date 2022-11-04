load "./websocket.js misc ./remote2.cl"

c: ws-client url="ws://localhost:8100" 
// on_message=(m_lambda "(ws,msg) => console.log('message recv',msg)")
// on_open=(m_lambda "() => console.log('handl: opened')")

// m-eval "(cc) => { console.log('sending'); cc(555) }" @c.send
// console-log "hello" @c.send

remote-object @c "+ 2 2" | console-log "remote reply is:"
