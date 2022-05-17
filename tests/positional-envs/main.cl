load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

screen auto_activate {
  column {
    alfa: 5;
    text (join "result is " @alfa);
    
    beta: (join "A" "C" @alfa with="-");

    text (join "result is " @beta);
    console_log @beta;
    
    teta: (repeater input=5 {
      text 33;
    });
    
    text (join "result is " @teta);
    console_log "teta is " @teta;
    
    zita: (repeater input=5 {
      am: a=@am->input b=15;
    });
    
    text (join "result is " @zita);
    console_log "zita is " @zita;
    
    /// тест на перевод в общем то в js структуры
    zita2: (repeater input=5 {
      am: a=@am->input b=15;
    } | map_geta "params");

    text (join "result is " @zita2);
    console_log "zita2 is " @zita2;
    
    // тест F-POSITIONAL-ENVS-OUTPUT
    text (join "() result is " (@alfa));
    console_log "() result is " (@alfa);
  };
};

debugger_screen_r;

/*
  scene-explorer-screen hotkey='b' {{
    apply_by_hotkey hotkey='b' {
      rotate_screens;
    };
  }}
*/