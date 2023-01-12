пусть в объекте есть такое

object {
   reaction (event @tv "manually_added") (make-func {
         console-log "privet"
         insert_children list={ area_3d } input=@tv manual=true
       } | console_log_input "QQE")
}       
       
так вот если ему сразу после создания послать оное событие то он его не поймает.
тк. все эти расчеты еще не произведены.

мысли
- ну я пока сделаю delayed-emit
- ждать подсчета вычислений и тогда считать что объект сделался
  но это уже было - я считал завершения расчета параметров.. ну и это было криво...
  
  а ведь это такая же история:
  on_manually_added=(make-func {
    console-log "privet"
    insert_children list={ area_3d } input=@tv manual=true
   })
- lazy.. ну т.е. как в qml - reaction _запрашивает_ свои 0 и 1, зачитывает их, в момент зачитывания пошло их вычисление (т.к. стоит флаг dirty)
  ну т.е. встает вопрос перехода от push-модели к комбинированной pull-push.. (точнее там будет pull + распространение dirty)
  это codea