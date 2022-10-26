load "misc new-modifiers set-params"

feature "world" {
  object {{ local-memory }}
}

feature "local-memory" {
  m: object
    entities=[]
    counter=0
    add=(m_lambda "(e) => {
      console.log( 'add',e )
      console.log( env.getPath() )
      e.id = 'mem' + (scope.m.counter++);
      scope.m.entities.push( e );
      env.signalTracked( 'entities' )
      env.emit('added',e); // тпу
    }")
    remove=(m_lambda "(e) => {
      env.emit('removed',e); // тпу
    }")
    update=(m_lambda "(e) => {
      env.emit('updated',e); // тпу
    }")
}

w : world
let add = (read @w | get-method-cell "add")

console-log "entities are" @w.entities

//console-log "w is" @w
//console-log "add is" @add

read @add | set-cell-value (json a=1 b=1 temp=1)
read @add | set-cell-value (json a=1 b=2 temp=2)
read @add | set-cell-value (json a=1 b=3 temp=1.5)

//перспектива.. хотя вроде это не надо, раз метод стал каналом..
// разве что set-cell-value уже пора в send переименовать
//send @w "add" (json a=2 b=1 temp=0.5)