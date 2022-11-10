load "misc"

feature "foo" {
  a: object on_privet={ console-log "hehe" }
  {
  let beta=5
  b: object teta=7

  read @a | listen on_privet={ |arg1|
    console-log "sam privet" @arg1 @beta
    m-eval "() => {
      console.log('b from eval is', scope.b )
    }"
  }
  read @a | get-event-channel "privet" | put-value "mir"
  }
}

foo
