load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

screen auto_activate {
  row {
    bt: button "click me";
    privet_logic @bt;
  };
};

//debugger_screen_r; // hotkey='s';

feature "privet_logic" {
    logic:
    {
      console_log "welcome to csp world";
      //console_log "logic created" @logic->0;
      when @logic->0 "click" {
        console_log "privet";
        //debugger;

        when @logic->0 "click" {
          console_log "privet 2";
          
          restart @logic {
            //privet_logic @logic->0;
            cnt_logic @logic->0 counter=0;
          };
        };

      };
    };
};

feature "cnt_logic" {
    logic: counter=0
    {
      if (@logic->counter >= 5) then={
        restart @logic {
          privet_logic @logic->0;
        };
      };
    
      m_eval "(it) => console.log('cnt_logic:',it)" @logic->counter;
      //console_log "counter" @logic->counter;
      //console_log "cnt logic created" @logic->0;
      when @logic->0 "click" {

        e: m_eval "(c) => c+1" @logic->counter;
        
        when @e "computed" { |newcounter|
          restart @logic {
            cnt_logic @logic->0 counter=@newcounter;
            //privet_logic @logic->0 counter=(@logic->counter + 1);
            //cnt_logic @logic->0 counter=(@logic->counter + 1);
            //cnt_logic @logic->0 counter=15;
          };
        };

      };

    };

};
