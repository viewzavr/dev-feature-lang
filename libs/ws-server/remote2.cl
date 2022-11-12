// позволяет создать на сервере объект по описанию, передавать в него input и получать его output

load "new-modifiers"

// remote-object @in @out @descr_string input=....
// выдает output - результат от удаленного объекта
feature "remote-object" {
  r: object
    in=@.->0
    out=@.->1
    descr=@.->2
    input=null
    /* пересылка всех параметров..
    on_param_changed={ |name value|
      m_eval @r.remote.send (json param=(m_eval "(n) => (Number.isInteger(n)) ? n-2 : n" @name) value=@value)
    }
    */
  {
    //write-channel @remote.out (json descr=@r.descr)
    read @r.out | put-value (json descr=@r.descr)
    read @r.out | put-value (json input=@r.input)

    read @r.in | cc-on { |msg|
      //object
      if (@msg.cmd == "output-value") {
        read @r | get-channel "output" | put-value @msg.value | return
      } else {
        return
      }

    }
  }
}

// object-on-server in=@in out=@out
// создает объект согласно поступившему от in параметру descr (строка)
// и также получает от него input и шлет output в out
feature "object-on-server" {
  s: object
     input=null
     descr=null
     in=@.->0
     out=@.->1
     output=@obj
     {
      aaa: read @s.in | cc-on { |msg|
        console-log "ssss" @msg
        //object
        if (read @msg.descr?) {
          read @s | get-channel "descr" | put-value @msg.descr | return
        }
        else {
          if (read @msg.input?) {
            read @s | get-channel "input" | put-value @msg.input | return
          }
          else { return }
        }
     }

     let obj = (null or (read @s.descr? | compalang | create-object | geta 0))
     //console-log "created object" @obj "descr was" @s.descr
     //console-log "obj output is" @obj.output

     read @obj | get-channel 'input' | put-value @s.input?
     xxx: read @obj | get-channel 'output' | cc-on existing=true { |v|
        // console-log 555 @v
        read @s.out | put-value (json cmd='output-value' value=@obj.output?) 
                    | return
     }
  }
}