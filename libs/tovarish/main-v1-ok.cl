load "misc new-modifiers set-params"

feature "world" {
  m: object
    entities=(json)
    counter=0
    add=(m_lambda "(e) => {
      e.id = 'mem_' + (scope.m.params.counter++);
      scope.m.params.entities[ e.id] = e;
      env.signalTracked( 'entities' )
      scope.m.emit('added',e); // тпу
    }")
    remove=(m_lambda "(e) => {
      delete scope.m.params.entities[ e.id ];
      scope.m.emit('removed',e); // тпу
    }")
    update=(m_lambda "(e) => {
      let olde = scope.m.entities[ e.id ];
      scope.m.params.entities[ e.id ] = e; // ну по идее оно уже и там
      scope.m.emit('updated',e, olde); // тпу
    }")
}

feature "w-log-events" {
  x-modify {
    x-on "added" {
      m-lambda "(obj,e) => {
        console.log('added ',e )
      }"
    }
  }
}

w : world {{ w-log-events }}
let add = (read @w | get-method-cell "add")

console-log "entities are" @w.entities

//console-log "w is" @w
//console-log "add is" @add

read @add | set-cell-value (json a=1 b=1 temp=1)
read @add | set-cell-value (json a=1 b=2 temp=2)
read @add | set-cell-value (json a=1 b=3 temp=1.5)

insert-children input=@.. active=(timeout_ms 1000) {
  read @add | set-cell-value (json a=1 b=3 temp=2.5)
}

//перспектива.. хотя вроде это не надо, раз метод стал каналом..
// разве что set-cell-value уже пора в send переименовать
//send @w "add" (json a=2 b=1 temp=0.5)