Сложно-простая модель плагинов.

Попытка абстрагировать / вынести систему плагинов.
Идея - точка входа приложение, далее оно использует систему добавления.

Также здесь идет обратная группировка приложения в файл main.cl

v11 - визуальная структура
Визулизация данных
 - траектория
 - прореженная
 - текущая
Дополнительные образы
 - статичные
 - надписи?
 
v13 - используем протокол find-objects но пробуем заменить его на find-objects-bf внутри по реализации.

v14 - воспроизводим интерфейс летне-осеннего проекта

v15 - добавляем поле active к интерфейсу.
v16 - переделка v15 чтобы полностью повторяло структуру v14 чтобы через git diff видеть внедрение фичи.

v18 - развитие v16 под новый интерфейс. Фича active пока остается впечатанной в коды.

v19 - разнообразные эксперименты.

v20 - рекурсия модели + оконный слой.
(не рабочий вариант)

v22 - попытка сделать человеческий интерфейс.
подпровалилась.

v23 - попытка сыграть в модальность. т.е не раскрывающееся дерево а дерево с модальными перекрытиями.
зашли на уровень - других не видим. замысел - как в группах в Телеграме в мобильном клиенте.
кстати потом и поиск приделаем аналогичный.
в итоге потом заходим на уровень и далее объекты в нем - это как лента типа.
хотя можно попробовать и такую вещь что - мб параметры "группы" и далее если подгруппы то показать их
(мб сверху.. хотя можно и снизу).

идея - сделать рендерилку с активным фокусом и разрешением менять этот фокус. т.е. мы не делаем массы рендерилок а делаем одну и пусть она себе фокус меняет.

v24 - сделали tab selector и все слева. неудобно

v25 - отдельно слева основные параметры а отдельно про слои тема.

теперь мысль такая что можно было бы и просто списком показать объекты но не все а согласно некоей поисковой категории
(те же слои и их объекты - в дереве listbox). Но кстати их можно было бы и кнопочками такими красивыми показать - как я видел в vtk web
и типа кликаем их и их параметры видны. т.е. отображение параметров не в метафоре сообщений а все-таки выбор одного объекта.. хотя, наверное,
можно сделать и так и так. кликнул по овалу слоя - видишь все. кликнул по одному - видишь одного. это кстати вариант...

Впрочем это выглядит уже вторичным. Первично теперь сделать выбор вида отображения главного, из набора заготовленных видов. У нас есть заготовка в 12chairs.

v26 - сделан первый вариант переключения.

------

v27 - попытка начать заново, чтобы сделать все по простому. потому что даже и то что сделано - это сложно получилось.

-----
v28 - пробую внедренные поведения для указания данных по траектории и тип объекта.
резюме - траектория в datavis а вот тип объекта разумно оказалось задавать извне, в гуи-части. (но результат хранится в manual-features)

-------
v30 - рефакторинг v28 таким образом, чтобы 
а) выбранный файл и результат его парсинга оставался неизменным
б) виды отображения (экраны/субэкраны) можно было бы как-то получше программировать / абстрагировать.

v31 - выносим выбор файла и данных на общий уровень с вьюшками. разделяемый то бишь точнее.

v32 - абстрагируем штуки из landing.cl в нормальный вызов. чтобы визуализация была
а) в синтаксисе compalang как раньше, 
б) с возможностью подключнеия визуального редактора согласно правилам
- отображения списка объектов по категориям, и их gui, с возможностью добавлять и удалять объекты, в том числе описанные декларативно а не через интерфейс.

v33 - рефакторинг по мелочам.
делал в этой версии сохранение параметров oneof. убедился что внедрение фич на каждую модификацию не катит - внедрение param-changed фичи для сбора параметров оказалось оч долгим

v34 - пробуем new-modifiers новые модификаторы. что-то получается.
+ версия рисует параметр данных как параметр объекта datavis