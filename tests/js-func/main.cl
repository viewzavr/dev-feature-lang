// F-JS-FUNC

load "misc"

jsfunc "foo" {: a b | return a + b :}
jsfunc "mul" {: a b | return a * b :}

jsfunc "mylist" {: ...args | args :}

console-log (foo 1 (mul 2 2)) "list=" (mylist 1 2 3)

///////////////////////////////
/* другие формы

feature "foo" { {: a b | return a + b :} }
let foo = {: a b c | a + b + c :}
console-log ({: a b c | a + b + c :} 1 2 3)
*/
