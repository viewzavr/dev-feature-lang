load "new-modifiers"

// remote-object @comm @descr_string input=....
// выдает output - результат от удаленного объекта
feature "remote-object" {
  r: object
    remote=@.->0
    descr=@.->1
  {
    m_eval @r.remote.send (json descr=@r.descr)
    m_eval @r.remote.send (json input=@r.input) // стало быть будет посылать при изменении инпута
    
    @r.remote | x-modify {
      x-on "message" (m-lambda "(ws,msg) => {
          msg = JSON.parse( msg )      
      if (msg.value == 'output-value')
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
     server=@.->0 
     {
      @s.server | x-modify {
        m-on "message" (m-lambda "(sobj, ws,msg) => {
          // console.log('object-on-server see msg!',msg)
          if (msg.descr)
            scope.s.setParam( 'descr', msg.descr );
          if (msg.input)
            scope.s.setParam( 'input', msg.input );
          // ну так-то мы можем любые значения присылать получается те. имя атрибута указывать.
          // и даже таким же макаром и метод вызывать
        }")
     }
        
     let obj = (read @s.descr | compalang | create-object)
     
     read @obj | get-cell 'input' | set-cell-value @s.input
     read @obj | get-cell 'output' | get-cell-value | m-eval "(send, output_value) => {
       send( { cmd: 'output-value', value: output_value } )
     }" @s.server.send
  }
}