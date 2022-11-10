load "misc new-modifiers set-params ws-server"

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
  a: object alfa=0.3
  object-on-server @comm | x-modify { x-set-params a=@a }

  //read @comm | get-event-cell "message" | get-cell-value | console-log "comm msg see"

  read @comm | x-modify {
    //m-on "message" (m-lambda "() => console.log('helow')")
    m-on "message" (make-func { |obj ws msg|
      console-log 'helow' @msg
    })
  }

  /* вот нормальный вариант:
  read @comm | x-on "message" { |obj ws msg|
    console-log 'helow' @msg
  }
  */

  //console-log "comm is" @comm @comm.sid @comm.send
}