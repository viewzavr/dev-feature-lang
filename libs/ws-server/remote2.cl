// позволяет создать на сервере объект по описанию, передавать в него input и получать его output

load "new-modifiers"

// remote-object @comm @descr_string input=....
// выдает output - результат от удаленного объекта
feature "remote-object" {
  r: object
    remote=@.->0
    descr=@.->1
    input=null
    /* пересылка всех параметров..
    on_param_changed={ |name value|
      m_eval @r.remote.send (json param=(m_eval "(n) => (Number.isInteger(n)) ? n-2 : n" @name) value=@value)
    }
    */
  {
    m_eval @r.remote.send (json descr=@r.descr)
    m_eval @r.remote.send (json input=@r.input) // стало быть будет посылать при изменении инпута

    //m-eval "(a) => console.log('rs is ',typeof(a))" @r.remote.send

    read @r.remote | x-modify  {
      m-on "message" (m-lambda "(sobj,ws,msg) => {
          //msg = JSON.parse( msg )
        // console.log('see rep',msg)
        if (msg.cmd == 'output-value')
           scope.r.setParam( 'output', msg.value )
      }")
    }
  }
}

// object-on-server @comm
// создает объект согласно поступившему от comm параметру descr (строка)
// и также получает от него input и шлет туда output
feature "object-on-server" {
  s: object
     comm=@.->0
     input=null
     descr=null
     output=@obj
     {
      @s.comm | x-modify {
        m-on "connection" (m-lambda "(sobj, ws) => {
          scope.s.setParam( 'send',ws.send )
        }")
        m-on "message" (m-lambda "(sobj,ws,msg) => {
          // console.log('object-on-server see msg!',msg)
          if (msg.descr)
            scope.s.setParam( 'descr', msg.descr );
          if (msg.input)
            scope.s.setParam( 'input', msg.input );
          // ну так-то мы можем любые значения присылать получается те. имя атрибута указывать.
          // и даже таким же макаром и метод вызывать
        }")
        m-on "close" (m-lambda "(sobj) => {
          //console.log('object-on-server close...',sobj)
          //sobj.remove()
        }")
     }

     let obj = (read @s.descr? | compalang | create-object )

     read @obj | get-cell 'input' | set-cell-value @s.input?
     read @obj | get-cell 'output' | get-cell-value | m-eval "(output_value,send) => {
       //console.log('sending output value',send,output_value)
       send( { cmd: 'output-value', value: output_value } )
     }" @s.comm.send
  }
}