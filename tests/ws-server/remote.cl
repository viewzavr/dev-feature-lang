feature "remote-object" {
  r: object remote=@.->0 descr=@.->1 {
    m_eval "(remote,remote_send,descr) => {
      remote_send( { cmd: 'create-object', descr: descr } )
    }" @r.remote @r.remote.send @r.descr
  }
}

feature "object-server" {
  s: object server=@.->0 objects_list=[] {
    @s.server | x-modify {
      x-on "message" (m-lambda "(ws,msg) => {
        if (msg.cmd == 'create-object')
          scope.s.params.objects_list.push( [ msg.descr, ws ] );
      }")
    }
    @s.objects_list | repeater { |descr|
      let obj = (read @descr.0 | compalang | create-object)
      read @obj | get-cell 'output' | get-cell-value | m-eval "(ws, output_value) => {
        ws.send( { cmd: 'output-value', output_value } )
      }"
    }
  }
}