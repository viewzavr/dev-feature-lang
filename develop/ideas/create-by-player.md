надо как-то вынести в удобный вариант доступа из js создания структур компаланг.
- для отладки в консоли
- для скриптов {: ... :} пущай генерируют. и там можно co`` даже оператор сделать
и даже мб контекст завести - кто там текущий родитель..

vzPlayer.create("primary-cats alfa=...")
vzPlayer.create("primary-cats alfa=...",{parent:...})
ну и там разбивка
parse - это строчка. и далее create( js-struct )

----
в плане контекста тогда
vzPlayer.create("primary-cats alfa=...",{parent:...}, () => {
  vzPlayer.create("alfa beta gamma")
})
но кстати тогда create он одну штучку создает или набор? какая сигнатура у результата?

а кстати как такое:
vzPlayer.create("primary-cats alfa=...",{parent:...}).then( (obj) => {
  vzPlayer.create("alfa beta gamma", {parent:obj})
})
как бы удобно, но что есть obj непонятно. Но это мб уже от ситуации зависит?
а вообще я думал тут контекст завести. но ладно, контекст это уже оптимизация..