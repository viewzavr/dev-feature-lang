load "misc"

a: object alfa=15 on_alfa_assigned=(m-lambda "(val) => console.log('alfa is',val)")
b: object beta=@a->alfa! on_beta_assigned=(m-lambda "(val) => console.log('beta is',val)")
с: object teta=@b->beta! on_teta_assigned=(m-lambda "(val,cnt) => console.log('teta is',val)" (read @c | get-cell "cnt"))

timer-ms 10 | m-eval "(t,a) => {
  a.set( Math.floor( Math.random()*2 ) )
}" (read @a | get-channel "alfa") // (port @a.alfa)
// get-channel "alfa-assigned" ?
// или всегда get-channel дает assign вещи? а там хотите - дедублируйте..

//console-log @a.alfa! @b.beta!

//m-eval "(v1,v2) => console.log( v1, v2 )" @a.alfa @b.beta!

//reaction @a.alfa! @b.beta! "(