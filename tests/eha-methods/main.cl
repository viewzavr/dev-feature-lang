load "misc new-modifiers"

a: object a=5

read @a | get-cell "b" | cc-on { |val|
  console-log "b val is" @val
}

//read @a | get-cell "b" | set-cell-value (timer-ms 1000)
read @a | get-cell "b" | set-cell-value 1

if (timeout-ms 1500) {
  read @a | get-cell "b" | set-cell-value 2
}
else
{
  console-log "waiting"
}


console-log @a.a

//////////////////
read @a | x-modify {
  y-on "param_b_changed" { |obj v|
    console-log "y-on see b change on obj" @obj "val" @v
  }
}