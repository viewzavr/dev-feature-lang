* уметь создавать с аргументом именем фичей поданной в строке.
create-object "button"
* получать результат созданный объект как output
let q = (create-object "button")

* создавать несколько экземпляров во многих объектах
create-object "button" target=(list @a @b @c)

* создавать серию объектов по списку
create-object list={ button 1; button 2; text 3; }
* создавать серию объектов по списку, каждую серию как дитей в целевых объектах (аналог insert-children)
create-object list={ button 1; button 2; text 3; } target=(list @a @b)

* создавать объект с аргументом-функцией, в этом случае она играет роль фичи
create-object (m_lambda "(env) => ......");

* передавать параметры созданному объекту
create-object "button" "privet" style=....;
можно пользоваться конечно x-modify/x-set-params но как-то неудобно..

продолжить