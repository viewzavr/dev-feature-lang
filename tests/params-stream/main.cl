load "misc"

verbose false
//m-eval "() => env.vz.verbose=1"

a: object alfa=15 on_alfa_assigned=(m-lambda "(cnt,val) => console.log('alfa is',val,cnt.set( (cnt.get() || 0)+1 ))" (read @a | get-cell "cnt"))
b: object beta=@a->alfa! on_beta_assigned=(m-lambda "(cnt,val) => console.log(' beta is',val,cnt.set( (cnt.get() || 0)+1 ))" (read @b | get-cell "cnt"))
c: object teta=@b->beta! on_teta_assigned=
  (m-lambda "(cnt,val) => { console.log('  teta is',val,cnt.set( (cnt.get() || 0)+1 ));
               }"
              (read @c | get-cell "cnt"))

//console-log "cnt cell is" (read @c | get-cell "cnt")

timer-ms 1000 | m-eval "(t,a) => {
  console.log('======================')
  a.set( Math.floor( Math.random()*3 ) )
}" (read @a | get-channel "alfa") // (port @a.alfa)
// get-channel "alfa-assigned" ?
// или всегда get-channel дает assign вещи? а там хотите - дедублируйте..

//console-log @a.alfa! @b.beta!

//m-eval "(v1,v2) => console.log( v1, v2 )" @a.alfa @b.beta!

//reaction @a.alfa! @b.beta! "(

/* то что надо
on-assigned "alfa=" @a->alfa! "beta=" @b->beta! "teta=" @c->teta! (m-lambda "(...args) => {
  console.log('on-assigned',...args)
}")
*/

/*
on-assigned "alfa=" @a->alfa! "beta=" @b->beta "teta=" @c->teta (m-lambda "(...args) => {
  console.log('on-assigned',...args)
}")
*/

/*
on-assigned "alfa=" @a->alfa! "beta=" @b->beta "teta=" @c->teta (k: make-func { |a b c d e f|
  console-log "on-assigned mf" @a @b @c @d @e @f on_print=(make-func { return 55 target=@k })
})
*/

//on-assigned @a->alfa! @b->beta! @c->teta! (m-lambda "(a,b,c) => { console.log('------------------ evalling ',a,b,c ); return a+b+c }") | console-log "result"
//on-assigned @a->alfa! @b->beta! @c->teta! (m-lambda "(a,b,c) => a+b+c") | console-log "result"

//on-assigned @a->alfa! @b->beta! @c->teta! (m-lambda "(a,b,c) => a+b+c") | on-assigned (delay (m-lambda "(val) => console.log( 'result',val )") pause=2)

// тестируем быструю передачу из ()-скобок
on-assigned
  (on-assigned @a->alfa! @b->beta! @c->teta! (m-lambda "(a,b,c) => a+b+c"))
  (m-lambda "(val) => console.log( 'result',val )") 