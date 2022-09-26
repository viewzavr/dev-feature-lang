cot: object 
      input=null types=[] titles=[]
      text="Образ: "
      dom_generator=true
      {{ read @cot | get-event-cell "param_output_changed" | c-on "() => {
          debugger;
          scope.cot.ns.parent.callCmd('rescan_children')
        }" }}
      output=(dom_group { .... })

событие
не отрабатывает. почему?

---
гипотеза что цепочка настройки событий на реакцию не успевала настроится.
вот такое работает:
      {{ m_eval "() => {
          scope.cot.ns.parent.callCmd('rescan_children')
        }" @cot->output
      }}

вопросы..
1 какого ежа
2 что вообще тогда эта моя штука означает?... что когда-то.. будет настроено.. реагирование на событие..
а до тех пор все события будут пропущены.. в этом смысле работа с потоком (m-eval) выглядит лучше конечно..
но вообще странно это все..