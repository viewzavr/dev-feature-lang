load files="misc gen.cl"

let k = (gen-object "object" | add-params sigma=5 | add-child @k2 "q4" )
    let k2 = (gen-object "object" | add-params teta=11)
//let k2 = (gen-object "object")

//console-log "k=" @k
//console-log "k2=" @k2

let ko = (create-object input=@k)

console-log "ko.getPath = " (@ko | geta "getPath" eval=true)
console-log "ko.sigma=" @ko.sigma
console-log "ko.q4.teta=" @ko.q4.teta

/////////////////////

// множественное надо ли нам?
//let k3 = (gen-object "object" | add-child (gen-object "object" count=10 | add-params sigma=15))
let k3 = (gen-object "object" | add-child (repeater input=10 { |cnt| gen-object "object" count=10 | add-params sigma=@cnt } | pause_input | map_geta "output" ))
let ko3 = (create-object input=@k3)
console-log "k3=" (read @ko3 | geta "dump" eval=true)
console-log "k3.children.sigma=" (read @ko3 | get_children_arr | map-geta "sigma")

//////////////////// сделаем что-то осмысленное
let a = (gen-object "+")
let aa = (create-object input=@a | x-modify { x-set-params 1 2 3 })
console-log "aa.output= @aa.output
