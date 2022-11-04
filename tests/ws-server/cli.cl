load "./websocket.js misc ./remote2.cl ./session.cl"

c: ws-client url="ws://localhost:8100" {{ ws-logging }}

// on_message=(m_lambda "(ws,msg) => console.log('message recv',msg)")
// on_open=(m_lambda "() => console.log('handl: opened')")

// m-eval "(cc) => { console.log('sending'); cc(555) }" @c.send
// console-log "hello" @c.send

c1: remote-session @c

//create-object active=(t: timeout-ms 1000) 
//repeater input=() {
  remote-object @c1 "timer-ms ((+ 1.5 0.2 ) * 1000) | console-log" | console-log "remote reply is:"
  //read @t | get-cell "restart" | set-cell-value 1
  //emit @t "restart"
//}
