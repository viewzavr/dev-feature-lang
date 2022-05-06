// тест
// load files="imperative2.js gui";
load files="imperative gui";

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
      //i-if (i-sum 0 1) (output=@t2->output); // тож работает
      i-if (i-sum 0 1) i-call-block {
        i-console-log "i call test 2 line 1";
        i-call @t2 "extra-arg from test 4";
        i-console-log "done";
      }
    };

    button "test 4a - call lambda" {
      la: i-lambda { i-console-log "lambda called" };
      i-console-log "calling lambda";
      i-call @la;
      i-console-log "done";
    };

    button "test 5" {
      i-if (i_less 3 5) (i_console_log "one"; i_console_log "two");
    };

    button "test 5a" {
      i-if (i_less 3 5) { i_console_log "one"; i_console_log "two"; };
    };

    button "test 6" {
      //i-repeat 10 (i_console_log "mir trud may!"); // todo?
      i-repeat 10 { i_console_log "mir trud may!" };
    };

    button "test 6a" {
      //i-repeat 10 (i_console_log "mir trud may!"); // todo?
      i-repeat 10 { 
        i_console_log "mir trud may!"; 
        i_console_log "pobeda!"; 
      };
    };    

    button "test 7" {
      i-repeat 10 { 
        q: i-args;
        i_console_log "mir trud may!" @q->0 "*" @q->0 "=" (i-mul @q->0 @q->0);
        i-if (@q->0 i-more 6)
          { i_console_log "ura!"; };
      };
    };

    button "test 8" {
      i-console-log (sum_kv 5 5 5);
    };

    button "test 8 test func" {
      test-func 123;
    };

/*
    button "test 7" {
      i-repeat 10 (ib: i-block { i_console_log "mir trud may!" @ib->0 "*" @ib->0 "=" (i-mul @ib->0 @ib->0)}); // todo
    };
*/    

    button "test aa" {
      i-call-block {
        qqq: alfa=(sum_kv 3 3 3); // todo каррирования нет - все перезатрется
        i-console-log "qqq is " @qqq;
        i-console-log "qqq->alfa is " @qqq->alfa;
        i-console-log (i-mul (i-call @qqq->alfa 2 2 2) @qqq->alfa);

        /*
        qqq: sum_kv 5 5 5;
        i-console-log (i-mul @qqq->result @qqq->result);
        */
      };
    };

  };
};

feature "test-func" {
  root: i-call-block {
    //i-console-log "testfunc working 1";
    //q: i-lambda code="() => console.log('hi from js')";
    args: i-args;
    q2: i-lambda { i-call-js code="() => 22;" };
    i-console-log "testfunc working" @args->0 (i-call @q2);
  };
};

feature "sum_kv" {
  root: i-call-block {
    args: i-args;
    i-console-log "sum-kv lambda called" @args->0 @args->1 @args->2;
    i-sum
      (i-mul @args->0 @args->0)
      (i-mul @args->1 @args->1)
      (i-mul @args->2 @args->2)
    ;
  };
};

/*
feature "i-repeat" {
  i_call_js code="(count) => {
     for (let i=0; i<count; i++)
     {
        //env.callCmd('eval_attached_block',i);
        // можно вернуть если надо будет
        env.eval_attached_block( i );
     }
  }";
};
*/
