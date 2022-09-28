// основное по ячейкам-каналам это comm3.js

// 0, input - путь вида objpath->name
feature "get-cell-by-path" {
  q: object
    input=@.->0
    splitted = (m_eval "(str) => str.split('->')" @q->input)
    objpath=@q.splitted.0
    paramname=@q.splitted.1
    output=(find-one-object input=@q->objpath | get-cell @q->paramname manual=@q->manual?)
  ;
};

// 0 одна ячейка
// 1 вторая ячейка
// идея так-то можно было бы в массиве указать несколько...
feature "bind-two-cells" {
  q: object {
    s1: set-cell-value input=@q->0 (get-cell-value input=@q->1) disabled=@s2->working;
    s2: set-cell-value input=@q->1 (get-cell-value input=@q->0) disabled=@s1->working;
  } 
};
// на будущее идейа: set-cell-value input=@q.positional_args (get-cell-value-latest @q.positional_args)

// связывает все ячейки по значениям. те. если в одной меняется то раздается на все.
feature "bind-cells" {
  q: object {
    s1: set-cell-value input=@q->input (get-cell-value-latest input=@q->input);
  } 
};
