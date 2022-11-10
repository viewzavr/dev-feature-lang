feature 'ws-logging' {
  x-modify {
    m-on 'message' (m-lambda "(obj,ws,msg) => console.log('incoming message',msg)")
    m-on 'sending' (m-lambda "(obj,ws,msg) => console.log('outcoming message',msg)")
  }
}

/*
  s: remote-session @remote {
     m-eval @s.send (json cmd="create-object" descr=@some-descr)
  }
*/

feature "remote-session" {
  r: object remote=@.->0 {
    m_eval "(remote,remote_send,session_type) => {
      if (scope.r.a_unsub) scope.r.a_unsub()

      let sid = Math.random() * 1000000;
      let session_counter = 0;
      let pending_responces = {}

      remote_send( { cmd: 'create-session', sid: sid, session_type: session_type } )
      scope.r.a_unsub = remote.on('message',(ws,msg) => {
        // console.log(1111,msg)
        if (msg.sid != sid) return;
        if (msg.cmd == 'created') {
          //console.log(222)
          scope.r.setParam( 'send',(m) => {
            let rid = session_counter++;
            remote_send( {cmd: 'session-msg', sid: sid, message: m, request_id: rid } )
            // но эта штука возвращает непойми что. а нам надо вернуть промису.. чтобы она сработалась с m-eval и тот мог вернуть output.. хотя бы так..
            let k = new Promise( (resolve,reject) => {
              pending_responces[ rid ] = [resolve, reject]
              if (Object.keys(pending_responces).length > 1000) {
                console.warn('remote-session: more than 1000 pending responces promises')
              }
            })
            k.make_func_result=true;
            return k;
          })
        }
        else
        if (msg.cmd == 'finished') {
          scope.r.setParam( 'send', null )
        }
        else
        if (msg.cmd == 'message') {
          //console.log('gggg message, sensing to self',env)
          scope.r.emit( 'message', ws, msg.value )
        }
        else
        if (msg.cmd == 'reply') {
          let r = pending_responces[ msg.request_id ]
          if (r) {
            // console.log('found rrrr' )
            r[0]( msg.value ); // вызываем промису, насыщаем output у m-eval
            delete pending_responces[ msg.request_id ]
          }
        }
      })
    }" @r.remote @r.remote.send
  }
}

// серверная компонента
feature "session-server" {
  s: object server=@.->0 objects_list=[] {{
    catch-children 'code'
    read @s.server | x-modify {
      m-on "connection" (m-lambda "(session_srv,server_obj,ws) => {
        ws.on('close',() => {
          //console.log('ws closed, emitting to srv',session_srv)
          session_srv.emit('close',ws)
          // console.log('ws closed, is is',ws.sid)
          let found_session_obj = scope.s.params.session_table[ ws.sid ]
          // console.log('fso',found_session_obj)
          if (found_session_obj) {
            // console.log('removing session obj')
            delete scope.s.params.session_table[ ws.sid ]
            found_session_obj.remove()
          }
        })
      }" @s)
      m-on "message" (m-lambda "(obj,ws,msg) => {
//        console.log('qqqqqqqq1',msg)
        if (msg.cmd == 'create-session') {
//           console.log('qqqqqqqq')
           let ns = env.vz.createObj({parent:env})
           // ns.feature( msg.session_type || 'session' )
           ns.setParam( 'sid', msg.sid );
           ns.setParam( 'send', (data) => {
             ws.send( {cmd: 'message', sid: msg.sid, value: data } )
           })
           ws.sid = msg.sid;

           // это мы создали покамест коммуникатор еще ток
           // теперь надо создать собственно объект.
           let cre = env.vz.createObj({parent:ns}) // родитель это ns будем стирать его потом
           cre.feature('create-objects')
           cre.setParam( 0, ns )
           cre.setParam( 'input', scope.s.params.code )
           // все, пошло поехало - создали все по описанию и общаемся через коммуникатор
           
           // запомним таблицу сессии
           let st = scope.s.params.session_table || {}
           st[ msg.sid ] = ns;
           scope.s.setParam('session_table',st)
           
           env.feature('delayed')
           env.timeout( () => ws.send( {cmd: 'created', sid: msg.sid} ), 50 ); // подождем и пошлем
        }
        if (msg.cmd == 'session-msg') {
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
          if (found_session_obj) {
            //console.log('emitting message to communicator',found_session_obj,msg.message)
            //let rep = new Promise( (resolve,reject) => {} )
            // функция ответа
            let rep = env.create_cell()
            rep.on('assigned',value => {
              //console.log( 'using rep to reply', msg.request_id )
              ws.send( {cmd: 'reply', sid: msg.sid, value: value, request_id: msg.request_id} )
              //delete rep
            });
            //console.log('emitting, rep is',rep)
            found_session_obj.emit( 'message',rep,msg.message )
          }
          else
            console.warn('session-creator: session.sid not found',msg.sid);
        }
      }")
    }
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