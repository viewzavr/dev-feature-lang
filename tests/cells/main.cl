load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

screen auto_activate {
  row {
    text "privet";
    cb: combobox values=["alfa","beta","teta"];
    bt: button "press me"; // вариант мог бы быть: {{ get-cell "click" | c-on "(e) => ...." }};
    
    clicka: (@bt | get-cell "click");
    
    //@clicka | c-on "(lele) => .... ";
    // идея ловить on- типа удобно. button "mumu" on-click="(obj) => ....";
    
    //@bt | get-event-cell "click" | m-on "(args) => console.log(args)";
    @clicka | console-log-input "e1" | get-cell-value | console-log-input "click";
    //@cb | get-event-cell "user_changed_value" | console-log-input "e2" | get-cell-value | console-log-input "cb";
    @cb | get-cell "index" | console-log-input "e3" | get-cell-value | console-log-input "cb-index";
    
    algo1 (@bt | get-cell "click") (@cb | get-cell "index");
    
    console_log "control. cb-index param is" @cb->index "cb-value is" @cb->value;
    
    bt2: button "me too";
    // @bt2 | get-event-cell "click" | c-on (m_lambda "(evt,cb) => console.log('you click me too',cb)" @cb->value);
    @bt2 | get-cell "click" | c-on "(evt,cb) => console.log('you click me too',cb)" @cb->value;

    c1: create_cell;
    @c1->output | set-cell-value 0;
    text (list "counter" (@c1->output | get-cell-value) "mememe");

    l1: csp {
      when_cell (@bt2 | get-cell "click") {
        console_log "333";
        mev: m_eval "(c) => { console.log('computing', c.get()); c.set( c.get()+1 ); return true; }" @c1->output;

      when_cell (get-cell input=@mev "output") existing=true
        {
          restart @l1;
        };
      };
    };
  };
};

// вход: ячейка-событий ячейка-целевая
feature "algo1" {
  algo: {
    @algo->0 | get-cell-value | m-eval "(e,cell) => {
      //console.log('algo1 eval',e,cell);
      console.log('algo1. cur is',cell.get(),'setting to 2' );
      cell.set( 2 );
    }" @algo->1;
  };
};


// input - одна или более ячеек
// 0 - функция вызова
// 1 и далее - доп аргументы для функции
feature "c_on0" {
  q: output=@ee->output {
    //get-cell-value input=@q->input | m_eval {{ copy_positional_args @q }};
    get-cell-value input=@q->input | ee: m_eval @q->0 @q->1? @q->2? @q->3? @q->4? allow_undefined=true allow_undefined_input=false react_only_on_input=true;
  };
};