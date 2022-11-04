load "./websocket.js misc ./remote2.cl new-modifiers ./session.cl"

s: ws-server port=8100 
  //{{ ws-logging }}
  on2_message=(m-lambda "(client,msg) => {
  console.log('got message',msg)
}")

/*
read @s | x-modify {
  m-on 'message' (m-lambda "() => console.log('qq!!!!!!!')")
}
*/

a: object alfa=1 beta=2

// console-log @a.alfa

// s1: session-server @s

// object-on-server @s

session-server @s { |comm|
  a: object alfa=33
  object-on-server @comm

  //read @comm | get-event-cell "message" | get-cell-value | console-log "comm msg see"

/*
  read @comm | x-modify {
    m-on "message" (m-lambda "() => console.log('helow')")
  }
*/

  //console-log "comm is" @comm @comm.sid @comm.send
}