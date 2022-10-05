F-LET-ASSIGN-NOW
let присваивает значения в скоуп сразу же, даже если еще не рассчитаны.
если этого не сделать то ссылки его переменные отваливаются со временем по таймауту
т.к. у них свои варнинги что ссылаемся на неизвестный параметр.

*****************

не может потом найти pt1:

let interleaved_clicks = (find-objects-bf "..." | get-cell "clicks" | get_cell_value_latest);
let pt1 = @interleaved_clicks?
    pt2 = (@interleaved_clicks? | prev_value);
    
find-objects-bf "..." | repeater { |obj|
  @pt1 - нету грит такой.
}

диагностика показала что ее и в scope нет.

----
let interleaved_clicks = (or (find-objects-bf "vis-kv-tex-ecs-mountpoint" | get-cell "clicks" | get_cell_value_latest) null);
let pt1 = @interleaved_clicks
    pt2 = (@interleaved_clicks | prev_value) {{ console_log_life "EEE"}};
    
а вот так все заработало.

-----
у нас let публикует значение в scope только когда происходит запись плюс когда начальные параметры (константны).
надо добавить чтобы он писал еще и просто когда ссылка на параметр есть (то есть может быть будет запись)

-----
ну все let научен выкладывать в скоуп и залинкованные но еще не присвоенные вещи. хм.