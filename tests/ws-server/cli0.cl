load "./websocket.js misc"

c: ws-client url="ws://localhost:8100"
// on_open=(m_lambda "() => console.log('handl: opened')")

m-eval "(cc) => { console.log('sending'); cc({descr:'+ 2 2'}) }" @c.send
