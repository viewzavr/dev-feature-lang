// F-JS-FUNC

load "misc"

jsfunc "foo" {: a b | return a + b :}
jsfunc "mul" {: a b | return a * b :}

jsfunc "mylist" {: ...args | args :}
jsfunc "mylist-n" {: n ...args |
 let res = []
 //console.log("mylist-n n=",n,"args=",args)
 for (let i=0; i<n; i++) res = res.concat( args )
 return res
:}

//comp "mylist" {: a b | ... :}

console-log (foo 1 (mul 2 2)) "list=" (mylist 1 2 3) "list-n=" (mylist-n 3 1 2)

///////////////////////////////
/* другие формы

feature "foo" { {: a b | return a + b :} }
let foo = {: a b c | a + b + c :}
console-log ({: a b c | a + b + c :} 1 2 3)
*/

////////////////////////////// и докучи потестируем cofunc

cofunc "foo2" { |a b| @a + @b console-log "foo2 called" @a @b }
console-log "foo2=" (foo2 4 5)