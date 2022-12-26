load "misc"

let arr=[1,2,3,4,5]

m-eval {: console.log("privet") :}

m-eval {: a=5 b=(@arr.1 + 10) c| console.log("privetik",a,a+c,a+b) :} 7

let foo = {: qq | console.log("privet is foo",qq) :}
m-eval @foo 42

console-log "compute result is" (m-eval {: 44; return 5+5 :})
console-log "compute result 2 is" (m-eval {: x | Math.sin(x) :} 3.14152)
console-log "compute result 2 is" (m-eval "Math.sin" 3.14152)

///////////////////////
let x = (create-channel (timer-ms 250))
let y = (create-channel (timer-ms 750))

reaction @y {: value | console.log("tick",value) :}

reaction (race-channels @x @y) {: value | console.log("tack",value) :}