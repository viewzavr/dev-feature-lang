load "./websocket.js misc"

c: ws-client url="ws://localhost:8100" on_message=(m_lambda "(ws,msg) => console.log('message recv',msg)")

m-eval "(cc) => { console.log('sending'); cc({descr:'+ 2 2'}) }" @c.send
