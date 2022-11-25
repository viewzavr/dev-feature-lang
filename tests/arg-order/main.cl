load "misc"

timer-ms 1000 | put-value-to (create-channel) | cc-on { |value|
  console-log "wow" @value
}

//console-log "mememmeme"

//object output=null | console-log-input "KK"

let qq=5

//g2: read @qqa
//console-log "qqa" (g0: read @qq.a | g: console-log-input "I")
//console-log "qqa" (read @qq | g2: geta "a" | g: console-log-input "I")

//console-log "g has_input:" (m_eval "(g) => g.hasParam('input')" @g (timer-ms 1000)) (timer-ms 500)
//m_eval "(g) => console.log( 'g has input',g.hasParam('input') )" @g (timer-ms 1000)
//m_eval "(g) => console.log( 'g0 has output ',g.hasParam('output'), g.params.output )" @g0 (timer-ms 1000)
//m_eval "(g) => console.log( 'g2 has output ',g.hasParam('output'), g.params.output )" @g2 (timer-ms 1000)
//console-log "g0 output is" @g0.output

//if ( (summatra { object alfa=5 object alfa=2 }) > 111)

//console-log "i params 
//m_eval "(g) => console.log( 'if has arg0 ',g.hasParam(0), g.params[0] )" @i (timer-ms 1000)

//i: if (read @qq.a)
if ( (timer-ms 100) > 10)
{
  console-log "if ok"
} else {
  console-log "if false"
}

// ........................................

console-log "privet" "mir" (+ 2 2)

console-log "privet" "mir" sigma=(summatra {
  object alfa=1
  object alfa=2
  object alfa=3
})

feature "summatra" {
  k: object output=( read @k | get-children-arr | map_geta "alfa" | m_eval "(arr) => {
    let acc = 0;
    arr.forEach( k => acc += k )
    return acc
    }"
  )
}

feature "a" {
  object {
    //m-eval "(a,b,c)"
  }
}