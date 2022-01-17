## F-FEAT-ROOT-NAME
Обработка такой ситуации:
```
register_feature name="alfa" {
roota: column {
  row {
    text text="333";
    button text=@roota->text;
  }
}
```

## F-FEAT-PARAMS
Необходимо уметь иметь параметры у фич, то есть такая ситуация что фичам нужны собственные параметры, 
адресуемые не как константы, а по ссылкам. То есть что-то в духе circle background(color=@red).

Это приводит нас к необходимости создавать под-окружения. Но наверное возможны и другие варианты.

Из под-окружения необходимо делать доступ к родительскому окружению, куда мы прицепили фичу.
Для этого мы делаем:
## F-HOST
поле env.host -- указывает на саму env или на ту env, к которой текущая прицеплена в качестве фичи.
Допом делаем поле env.hosted которое = true если мы в режиме с host-фичей.


## F-SUBFEAT-PATH
Реализация F-FEAT-PARAMS как под-окружения приводит нас к: 
Необходимо доступ по путям-ссылкам к под-окружениям.
(потому что тот же pipe создает link-и между компонентами по путям-именам).
Например: circle backround(color=(compute1 | compute2))

Решение - даем имена objname:subenv-name через :.
Возможная проблема - разные фичи натащут в под-окружение разных суб-фич с одинаковыми именами.
Надо что-то с этим придумать, как вариант - строго следить за именами и в случае не-уникальности
что-то делать (задавать новое имя + контекст новый для использования и по старому имени внутри вложенного дерева)

## F-PARAMS-GET-OUTPUT
Очень частый наблюдаю на практике шаблон что надо что-то вычислить и присвоить как результат в параметр окружения.
fpath: get_query_param name="file_path";
load_file path=@fpath->output;
Сообразно идея оптимизации такая:
load_file path=( get_query_param name="file_path" );
Это можно реализовать если обрабатывать в языке шаблон paramname=(exprenv) и например договориться что у exprenv
берется поле output. Ну а саму эту exprenv можно сдаить в суб-фичи по аналогии с F-FEAT-PARAMS или еще как
(можно и отдельно болтать, лишь бы lexicalParent был)

# F-ENVS-TO-PARAMS
Хочется уметь передавать наборы окружений как параметры. Например для реализации идеи jetpack compose modifiers 
- декораторы как цепочки в памяти.
Решение - идея решения - это поддержать синтаксис something arg={ env; env; env }
НО при этом не кидаться создавать эти env а запомнить их как дамп и передать его в arg.
Это важно сделать именно потому что при вызове функций фич им уже надо знать, эта фича есть корневое окружение
или эта фича есть прицепленное окружение.


# F-SUBENVS-RENAME-DUP
Выснилась засада. если у нас 2 разные фичи.. в одном env.. порождают expr_env-ы...
то получается что они их именуют одинаково [почему-то..]

вероятно самое правильное это - создавать subenv-пространство для каждого головного
применения фичи (на головном окружении).. 

но тогда неясно как адресовать эти субфичи извне... 

ну пока применим что переименовывать субфичи.. но это тоже плохой вариант - на имя
могут ссылаться вполне.. @design и @todo лучше решить. пока переименуем.