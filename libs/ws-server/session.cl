// неактуально
feature 'ws-logging-old' {
  x-modify {
    m-on 'message' (m-lambda "(obj,ws,msg) => console.log('incoming message',msg)")
    m-on 'sending' (m-lambda "(obj,ws,msg) => console.log('outcoming message',msg)")
  }
}

// модификатор
feature 'ws-logging' {
  x: x-modify prefix="" {
    y-on 'connection' { |sobj in out|
      read @in | cc-on { |msg|
        console-log @x.prefix "incoming message" @msg
      }
      read @out | cc-on { |msg|
        console-log @x.prefix "outgoing message" @msg
      }
    }
  }
}

// капитально отдельная вещь конечно. посмотрим прикрутить ее к вызову методов.
feature "put-request" {
  x: object output=@c {
    let c = (create_channel)
    put-value input=@x->input (json request=@x->0 responce_channel=@c)
  }
}

feature "remote-session" {
  r: object 
    remote=@.->0
    @.->input
    {

      sigma: object

      read @r.remote 
      | 
      listen on_connection={ |in out|
        
        m-eval "(cin,cout) => {
          //console.log('scope.sigma=',scope.sigma)
        if (scope.r.a_unsub) scope.r.a_unsub()

        let sid = Math.random() * 1000000;
        let session_request_counter = 0;
        let pending_responces = {}

        let session_input = env.create_cell();
        let session_output = env.create_cell();

        cout.put( { cmd: 'create-session', sid: sid } )

        scope.r.a_unsub = cin.on('assigned', (msg) => {
          if (msg.sid != sid) return;
          if (msg.cmd == 'created') {

            session_output.on('assigned',(m) => {
              let rid = session_request_counter++;

              if (m.request && m.responce_channel) {
                 cout.put( {cmd: 'session-msg', sid: sid, message: m.request, request_id: rid } )
                 pending_responces[ rid ] = m.responce_channel
                 if (Object.keys(pending_responces).length > 1000) {
                   console.warn('remote-session: more than 1000 pending responces promises')
                 }
              }
              else
                cout.put( {cmd: 'session-msg', sid: sid, message: m, request_id: rid } )
              
            })
            //console.log('cli emit connnection')
            scope.r.emit( 'connection', session_input, session_output )
          }
          else
          if (msg.cmd == 'finished') {
            // ?
          }
          else
          if (msg.cmd == 'message') {
            //console.log('gggg message, sensing to self',env)
            session_input.put( msg.value )
          }
          else
          if (msg.cmd == 'reply') {
            let r = pending_responces[ msg.request_id ]
            if (r) {
              // console.log('found pending responce, calling its promise' )
              //r[0]( msg.value ); // вызываем промису, насыщаем output у m-eval
              r.put( msg.value )

              delete pending_responces[ msg.request_id ]
            }
        }
      }) // входящий пакет
    }" @in @out
    }
  }
}

// серверная компонента
feature "session-server" {
  s: object 
    server=@.->0
    objects_list=[]
    @.->input
    {{
     read @s.server | listen on_connection={ |in out ws|

       read @in | cc-on { |msg|
         m-eval "(ws,cin,cout,msg) => {
         if (msg.cmd == 'create-session') {
        
          let session_in = env.create_channel()
          let session_out = env.create_channel()

          session_out.on('assigned',(v) => {
            cout.put({cmd: 'message', sid: msg.sid, value: v})
          })
          /*
          in.on('assigned',(inmsg) => {
            i
          })
          */
           
          // запомним таблицу сессии
          // console.log('scope.s=',scope.s)
          let st = scope.s.params.session_table || {}
          st[ msg.sid ] = { in: session_in, out: session_out, cout: cout }
          scope.s.setParam('session_table',st)
           
          env.feature('delayed')
          env.timeout( () => cout.put( {cmd: 'created', sid: msg.sid} ), 50 ); // подождем и пошлем

          scope.s.emit( 'connection', session_in, session_out )
        }
        if (msg.cmd == 'session-msg') {
          let session_record = scope.s.params.session_table[ msg.sid ]
          if (session_record) {
            // функция ответа
            let rep = env.create_channel()
            rep.on('assigned',value => {
              //console.log( 'using rep to reply', msg.request_id )
              session_record.cout.put( {cmd: 'reply', sid: msg.sid, value: value, request_id: msg.request_id} )
              //delete rep
            });
            //console.log('emitting, rep is',rep)
            let arg = [msg.message, rep]
            arg.is_event_args = true
            session_record.in.put( arg )
          }
          else
            console.warn('session-creator: session.sid not found',msg.sid);
        }
        }" @ws @in @out @msg
         
      } // cc-on

      m-eval "(ws) => {
        ws.on('close',() => {
          //console.log('ws closed, emitting to srv',session_srv)
          //session_srv.emit('close',ws)
          // console.log('ws closed, is is',ws.sid)
          let session_record = scope.s.params.session_table[ ws.sid ]
          // console.log('fso',found_session_obj)
          if (session_record) {
            // console.log('removing session obj')
            delete scope.s.params.session_record[ ws.sid ]
            //found_session_obj.remove()
          }
        })
      }" @ws
     } // on-connection
    
  }}
}

feature "session"

/*
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
*/