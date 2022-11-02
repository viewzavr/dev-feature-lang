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
