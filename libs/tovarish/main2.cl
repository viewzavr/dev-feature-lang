load "misc new-modifiers"

feature "world" {
  w: object
    {{ local-memory }}
}

feature "local-memory" {
  x-modify {
    x-on 'add' {
      m-lambda "(obj,e) => {
        console.log('aaaadddddd',e)
    }"
    } 
  }
}

w : world
let add = (read @w | get-event-cell "add")

console-log "entities are" @w.entities

//console-log "w is" @w
//console-log "add is" @add

read @add | set-cell-value (json a=1 b=1 temp=1)
read @add | set-cell-value (json a=1 b=2 temp=2)
read @add | set-cell-value (json a=1 b=3 temp=1.5)

//перспектива.. хотя вроде это не надо, раз метод стал каналом..
// разве что set-cell-value уже пора в send переименовать
//send @w "add" (json a=2 b=1 temp=0.5)