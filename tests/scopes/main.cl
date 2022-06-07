// должна выдаваться 5 а не 7

load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

thing: {
  alfa: beta=5;
};

feature "inner-thing" {
  alfa: beta=7;
};

screen auto_activate {
  column {
    inner-thing;
    text text="result = (";
    kk: text text=@alfa->beta;
    text text=" ) should be 5";
    ///
    extra: {
      alfa: beta=4; // должно выдать ошибку
    };
    ///
    text "also";
    text @qq->text
     {{ qq: text="in subfeatures"; }};
    ////
    ex: extratext more="feature may link to own name"; 
    
    ////
    text "should print sigma";
    t1: text sigma="sigma" text=@inner->result {{ inner: result=@t1->sigma; }};
    
    ////
    render-params @ex;
  };
};

feature "extratext" {
  bebe: text @bebe->more;
};

//debugger_screen_r; // hotkey='s';