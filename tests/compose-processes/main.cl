load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

t1: text "text1";
t2: text "text2";

screen auto_activate {
  row {
    c1: compose_p input=(list @t1 @t2);
    // тут должно появиться объединение видимо? ну типа оба текста?

    // но это конечно не будет работать т.к. а что такого то..
    //console_log @c1->output (list @t1 @t2);
    
    l1: list 1 2 3 4 5;
    l2: list 5 5 5;
    l3: compose_p input=(list @l1 @l2);
    console_log "l3=" @l3 (@l3->output | geta 0);

    ///
    at1: text "alfa1";
    at2: text "alfa2";

    (list @at1 @at2) | ak: compose_p dom_style_color="orange";
    button "click" {
      setter target="@ak->dom_style_color" value="red";
    };

  };
};

debugger_screen_r; // todo: key="alt-s"