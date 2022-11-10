/*
  и это было бы все очень хорошо.
  но в get-value зашита delayed-логика для сшивки значений
  и в m-eval зашито всякое delayed

  мб стоило бы их как-то {{ delayed }} помечать ну или | pause-input |

  даже в случае скоростного get-value (сделал) - дальше этого дело не идет,
  т.к. onvalue, а точнее trackParam, это на самом деле param-changed
  а в случае повторных сообщений мы их скрываем. такова логика расчета параметров. эээх.
  лучше бы это клиент делал, заказывал. но с другой стороны если мы говорим ок,
  процесс меняет свое состояние при изменении входных параметров - ну он и не меняет,
  они же не изменились.

  поэтому видимо правильно, что для каналов другие методы. ну.. ладно..
*/

load "misc"

let a = (create-channel)
let b = (create-channel)

read @a | get-value | console-log-input | m-eval "(v) => [v,v*2]" | put-value-to @b

read @b | cc-on { |value|
  console-log "see value" @value
}

read @a | put-value 5
read @a | put-value 5
read @a | put-value 5
read @a | put-value 6
read @a | put-value 7