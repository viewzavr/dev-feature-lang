/*
  s: remote-session @remote {
     m-eval @s.send (json cmd="create-object" descr=@some-descr)
  }
*/

feature "remote-session" {
  r: object remote=@.->0 {
    m_eval "(remote,remote_send,session_type) => {
      let sid = Math.random() * 1000000;
      remote_send( { cmd: 'create-session', sid: sid, session_type: session_type } )
      remote.on('message',(msg) => {
        if (msg.sid != sid) return;
        if (msg.cmd == 'created') {
          scope.r.setParam( 'send',(m) => {
            remote_send( {cmd: 'session-msg', sid: sid, message: m} )
          })
        }
        else
        if (msg.cmd == 'finished') {
          scope.r.setParam( 'send', null )
        })
        else
        if (msg.cmd == 'message')
          env.emit( 'message', msg.message )
      })
    }" @r.remote @r.remote.send @r.session_type
  }
}

// серверная компонента
feature "session-creator" {
  s: object server=@.->0 objects_list=[] {
    @s.server | x-modify {
      x-on "message" (m-lambda "(ws,msg) => {
        if (msg.cmd == 'create-session') {
           let ns = env.createObj({parent:env})
           ns.feature( msg.session_type || 'session' )
           ns.setParam( 'sid', msg.sid );
           ws.send( {cmd: 'created', sid: msg.sid} )
           
           let st = scope.s.params.session_table || {}
           st[ msg.sid ] = ns;
           scope.s.setParam('session_table',st)
        }
        if (msg.cmd == 'session-cmd') {
        /*
          let found_c;
          // todo optimize
          for (let c of env.ns.getChildren()) {
            if (c.params.sid == msg.sid) {
              found_c = c;
              break;
            }
          }
          let found_session_obj = found_c;
          */
          let found_session_obj = scope.s.params.session_table[ msg.sid ]
          if (found_session_obj)
            found_session_obj.emit('message',ws,msg.message )
          else
            console.warn('session-creator: session.sid not found',msg.sid);
        }
      }")
    }
  }
}

feature "session"

feature "remote-object" {
  r: remote-session 
    descr=@.->1 
    session_type="remote-object-session"
    on_message=(m-lambda "(ws,msg) => {
      if (msg.value == 'output-value')
        scope.r.setParam( 'output', msg.value )
      // тут возникает идея.. а какая забыл.. ))))
       
    }"
  {
    m_eval @r.send (json descr=@r.descr)
    m_eval @r.send (json input=@r.input) // стало быть будет посылать при изменении инпута
  }
}

feature "remote-object-session" {
  s: session
    on_message=(m_lambda "(ws,msg) => {
      if (msg.descr)
        scope.s.setParam( 'descr', msg.descr )
      if (msg.input)
        scope.s.setParam('input',msg.input )
    }")
    {
      let obj = (read @s.descr | compalang | create-object)
      read @obj | get-cell 'input' | set-cell-value @s.input
      read @obj | get-cell 'output' | get-cell-value | m-eval "(send, output_value) => {
        send( { cmd: 'output-value', value: output_value } )
      }" @s.send
    }
}
