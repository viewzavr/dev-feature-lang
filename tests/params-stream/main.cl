load "misc"

m-eval "() => env.vz.verbose=1"

a: object alfa=15 on_alfa_assigned=(m-lambda "(cnt,val) => console.log('alfa is',val,cnt.set( (cnt.get() || 0)+1 ))" (read @a | get-cell "cnt"))
b: object beta=@a->alfa! on_beta_assigned=(m-lambda "(cnt,val) => console.log(' beta is',val,cnt.set( (cnt.get() || 0)+1 ))" (read @b | get-cell "cnt"))
c: object teta=@b->beta! on_teta_assigned=
  (m-lambda "(cnt,val) => { console.log('  teta is',val,cnt.set( (cnt.get() || 0)+1 ));
               }"
              (read @c | get-cell "cnt"))

//console-log "cnt cell is" (read @c | get-cell "cnt")

timer-ms 1000 | m-eval "(t,a) => {
  console.log('======================')
  a.set( Math.floor( Math.random()*10 ) )
}" (read @a | get-channel "alfa") // (port @a.alfa)
// get-channel "alfa-assigned" ?
// или всегда get-channel дает assign вещи? а там хотите - дедублируйте..

//console-log @a.alfa! @b.beta!

//m-eval "(v1,v2) => console.log( v1, v2 )" @a.alfa @b.beta!

//reaction @a.alfa! @b.beta! "(