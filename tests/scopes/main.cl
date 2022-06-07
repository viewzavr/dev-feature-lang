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
      alfa: beta=4; // должно выдать ошибку и не добавить эту alfa в общую видимость...
    };
    ///
    text "also";
    text @qq->text
     {{ qq: text="in subfeatures"; }};
    ////
    ex: extratext more="feature may link to own name, if you see this"; 
    
    ////
    text "should print sigma";
    t1: text sigma="sigma" text=@inner->result {{ inner: result=@t1->sigma; }};
    
    ////
    text "finally, render params";
    render-params @ex;
    text "finally, render params 2 times";
    render-params @ex;
    
    ////
    if true then={
      text (join "inside if alfa->beta is" @alfa->beta);
    };
  };
};

feature "extratext" {
  bebe: text @bebe->more;
};

//debugger_screen_r; // hotkey='s';