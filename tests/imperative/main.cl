load files="imperative.js gui";

screen auto_activate {
  column padding="1em" gap="0.4em" {
    button "test" {
      i_console_log "hehe sum 1..5 is" (i_sum 1 2 3 4 5);
    };
    button "test 2" {
      t2: i_console_log "hehe 10+5*5 is" (i_sum 10 (i_mul 5 5)); 
    };

    button "test 3" {
      i-if (i-sum 0 1) (i_console_log "1 is true") (i_console_log "1 is false");
    };

    button "test 4" {
      //i-if (i-sum 0 1) @t2->output; // работает
      //i-if (i-sum 0 1) (@t2); // почему-то не работает..
      i-if (i-sum 0 1) (output=@t2->output); // тож работает
    };

    button "test 5" {
      i-if (i_less 3 5) (i_console_log "one"; i_console_log "two");
    };

    button "test 6" {
      i-repeat 10 (i_console_log "mir trud may!"); // todo
    };

    button "test 7" {
      i-repeat 10 (ib: i-block { i_console_log "mir trud may!" (i-mul @ib->0 @ib->0)}); // todo
    };

  };
};

feature "sum_kv" {
  root: i-block { // todo
    i-sum
      (i-mul @root->0 @root->0)
      (i-mul @root->1 @root->1)
      (i-mul @root->2 @root->2)
    ;
  };
};
