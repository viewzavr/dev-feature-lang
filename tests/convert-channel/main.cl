load "misc"

let a = (create-channel)
let b = (read @a | convert-channel (m-lambda "(v) => [v,v*2]"))

read @b | cc-on { |value|
  console-log "see value" @value
}

//read @b | listen on_assigned { |value| ... }

read @a | put-value 5
read @a | put-value 6
read @a | put-value 7
