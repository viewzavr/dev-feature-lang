 make-func { |arg arg| bla bla. что-то такое надо нам. }

на входе у ней одно. на выходе - функция которая создает компаланг окружение, передает ему параметры, и там все работает, а когда завершается - функция схлаптывает окружение.

ну тут еще такой нюанс. промисы. m_eval если я хочу юзать.. надо чтобы он в output записал результат такой функции, а не просто что вот мол промиса.

хотя можно сделать мостик от промисов к парметрам.
типа wait-promise (m_eval (.....))
но мудреновато.