В чем-то похожие интересные языки.

# rebol
http://re-bol.com/rebol_quick_start.html#section-2
https://www.red-lang.org/p/getting-started.html
Don't solve problems you don't have. That adds complexity, and now you really have a problem.
https://www.red-lang.org/2021/12/2021-winding-down.html#comment-form

# ring
https://en.wikipedia.org/wiki/Ring_(programming_language)
- интересная фича вмешиваться в объекты извне, и плюс синтаксис, позволяют что-то такое:
new Poem {
  Пришла гроза в начале мая
}
и это будет программным выражением, т.к. каждое слово здесь определено в контексте Poem конструктором этого Poem.

# closurescript
у него и у closure неплохо теория расписана.
ну и лисп понятно наш идеал из XX века.

# возможно интересно
shift programming language

# прочее но не то
dylan
nemerle
oz (http://mozart2.org/)
alice (https://www.ps.uni-saarland.de/alice/manual/tour.html)

также мы в курсе про kotlin (compose!), qml (кстати кто его автор то???)
и react, и svetle, и lit.dev.

# TODO
https://en.wikipedia.org/wiki/Curl_(programming_language)

# посмотреть еще
AmbientTalk
Coherence

hybrid programming language => 
* https://dl.acm.org/doi/10.1002/spe.4380210603
* https://www.semanticscholar.org/paper/A-Tour-of-Hybrid-A-Language-for-Programming-with-Nierstrasz/2760cb4615e92b9f2ce38dbb2b304aaf4eb0f7ff
* http://euler.vcsu.edu:7000/2101/    
* https://journals.sagepub.com/doi/abs/10.1177/0735633120985108 Hybrid and Non-Hybrid Block-Based Programming Languages in an Introductory College Computer-Science Course
* https://ieeexplore.ieee.org/document/664163 The SHIFT programming language for dynamic networks of hybrid automata

https://www.info.ucl.ac.be/~pvr/paradigmsDIAGRAMeng108.pdf
- список парадигмов программирования (20 штук)

https://en.wikipedia.org/wiki/Unicon_(programming_language)

https://dmkpress.com/files/PDF/978-5-93700-140-5.pdf?utm_source=LeadHit&utm_medium=email&utm_campaign=MR051022&lh_message_id=633d314773efc33c30ae0bbc&lead_id=62346bf473efc37042052c9f
Клинтон Л. Джеффери Создайте свой собственный язык программирования

работы по интерфейсам
* https://www.cs.cmu.edu/~./sage/Papers/HCI-journal-96/HCI-journal.html
* https://ceur-ws.org/Vol-1947/paper06.pdf
* https://mkremins.github.io/publications/ERaCA_HAI-GEN2022.pdf
* Towards the ubiquitous visualization: Adaptive user-interfaces based on the Semantic Web

scala dotty

в целом Михаил говорит что хороший тот язык на котором решаются реальные задачи. А не тот который что-то там теоретически хорош.

https://lit.dev/docs/templates/directives/

* CSPM
https://cocotec.io/fdr/manual/cspm.html

# A Survey on Reactive Programming / Article  in ACM Computing Surveys · January 2012
 - топологическая сортировка для избежания glitches
 - разделение на behaviour и event и поддержка обоих вариантов.
 => идея get-event @channel => value, 
    select-latest (по значениям сообщает кто последний), select-second-or-first (ну или or)

# Lingua Franca
Reactors: A Deterministic Model for Composable Reactive Systems.txt
 - Предлагается математическая модель. Заявляется готовность вплоть до надежных систем реального времени, по которым можно даже проводить доказательства.
https://github.com/lf-lang/lingua-franca
https://github.com/lf-lang/lingua-franca/wiki
https://www.lf-lang.org/docs/handbook/a-first-reactor?target=c
https://www.researchgate.net/profile/Marten-Lohstroh
https://www.researchgate.net/publication/364393043_Pragmatics_Twelve_Years_Later_A_Report_on_Lingua_Franca
https://ptolemy.berkeley.edu/publications/papers/06/problemwithThreads/
https://www.icyphy.org/

- разделение понятия параметров (они кстати константны), портов (входные и выходные), переменных состояния
- у всего есть родитель (у порта, у параметра, у реакцииы)
- {= ... =} для указания кода. также возможность использовать эту запись для вычисления значений параметров, т.е. 
alfa={= Math.sin( Math.Pi*2) =} кстати выглядит нормально - это раскрашивается в Sublime, что хорошо. А метка {= .. =} позволит сразу eval-ить этот код, по идее. Но только придется делать при записи кодов всегда явное (env)=>{...} короче надо подумать
- питонские комменты допом к плюсовым
- неплохая система импорта (строгая!)
=> шикарная визуализация схемы
- схематичность явная. выводится из кода. у нас не совсем 
(@x | get-channel "Name" | get-value | m-eval "...." | put-value-to (@y | get-channel "z")) 
как по такому строить схему передачи????) или видно будет и так?..
- встроенная поддержка функции таймера, что позволяет обращаться к ней по идентификатору
- реакции есть обработчики событий; для срабатывания реакции указывается 1 или более событий, которые влекут ее вызов. при этом если событий несколько то приход любого из них есть повод для реакции. можно в коде реакции узнать, какое событие сработало.
- события не совсем события; они в частности собираются на портах группируются, если записало несколько источников то переходит к дальнему.
- запуск происходит путем отыскания фичи main; при этом если файл импортируется, то она не запускается (логично..). это позволяет делать файлы которые можно запускать, а можно импортировать (и тогда логика main не применяется...). но наверное можно было бы сделать логику on-import; либо оставить все как есть - т.к. у нас и так объекты разворачиваются; а main - добавочно сделать.