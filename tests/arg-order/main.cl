load "misc"

if ( (summatra { object alfa=5 object alfa=2 }) > 111)
{
  console-log "if ok"
} else { 
  console-log "if false"
}

//console-log "privet" "mir" (+ 2 2)
/*
console-log "privet" "mir" sigma=(summatra {
  object alfa=1
  object alfa=2
  object alfa=3
})
*/

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