load "misc"

# verbose true

alfa: object a=(timer-ms 500)

console-log @alfa.a

reaction @alfa.a {: val | console.log('val=',val) :}
reaction @alfa.b {: val | console.log('b val=',val) :}
reaction @alfa.mmm {: val | console.log('mmm occured',val) :}
// создает универсальный канал mmm в alfa

if (timer-ms 1000) {
  // создает канал события mmm в alfa
  event @alfa "mmm" | put-value 10
  param @alfa "b" manual=true | put-value 22
}

param @alfa "mmm" manual=true | get-value | console-log-input "MMM"

param @alfa "b" manual=true | get-value | console-log-input "alfa.b"