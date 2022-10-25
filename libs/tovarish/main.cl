load "misc"

repeater input=10 { |i|
  console-log "privet mir" @i
}

feature "world" {
  w: object 
    add=(m_lambda "(e) => {
      scope.w.emit('added',e); // тпу
    }")
    remove=(m_lambda "(e) => {
      scope.w.emit('removed',e); // тпу
    }")
    update=(m_lambda "(e) => {
      scope.w.emit('updated',e); // тпу
    }")

}

w: world;
add: read @w | get-method-cell "add"

read @add | set-cell-value (json a=1 b=1 temp=1)
read @add | set-cell-value (json a=1 b=2 temp=2)
read @add | set-cell-value (json a=1 b=3 temp=1.5)

//перспектива.. хотя вроде это не надо, раз метод стал каналом..
// разве что set-cell-value уже пора в send переименовать
//send @w "add" (json a=2 b=1 temp=0.5)