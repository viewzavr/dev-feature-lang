load "lib3dv3 csv params io gui render-params df scene-explorer-3d misc";
//load "make-func.js";

// create-adder "adder" title="result==";

screen auto_activate {
  column {
    
    text "1. result = ";
    text (m_eval (make-func {
      output=(2 + 2);
    }));
    

    text "2. result = ";
    text (m_eval 
             (make-func { |x y z| output=(+ @x @y @z 2); }) 
              10 20 10);

    text "3. result = ";
    text (m_eval 
             (make-func { |x y z| 
               output=(+ @x @mul1->output 2); 
               mul1: @z * @y
              }) 
              10 20 10);

    row {
      x1: dom tag="input" {{ 
        @data | get-cell "d1" | set-cell-value (
          @x1 | dom_event_cell "change" | c-on "(evt) => parseFloat( evt[0].target.value )" 
        )
        }};
      text "+";
      x2: dom tag="input" {{ 
        @data | get-cell "d2" | set-cell-value (
          @x2 | dom_event_cell "change" | c-on "(evt) => parseFloat( evt[0].target.value )" 
        )
       }};
      text "=";
      text (m_eval 
             (make-func { |x y| output=(+ @x @y); }) 
              @data->d1 @data->d2 );

      data: d1=0 d2=0;
    };

    // F5
    row {
      // input - входной канал output = выходной канал
      feature "pass_val" {
        k: 
        {{
          @k->output | set-cell-value (@k->input | c-on "(evt) => parseFloat( evt[0].target.value )")
        }};
      };

      s1: dom tag="input" 
        {{ 
        @s1 | dom_event_cell "change" | pass_val output=(@sdata | get-cell "d1");
        }};
      text "+";
      s2: dom tag="input" 
        {{ 
          @s2 | dom_event_cell "change" | pass_val output=(@sdata | get-cell "d2");
        }};

      text "=";
      text (m_eval 
             (make-func { |x y| output=(+ @x @y); }) 
              @sdata->d1 @sdata->d2 );

      sdata: d1=0 d2=0;
    };

/*
    text "4. result = ";
    text (m_eval 
             (make-func { |x y z| 
               output=(+ @x @mul1 2); 
               mul1 = @z * @y
               alfa = sqrt( @z );
              }) 
              10 20 10);
*/

  };
};


/*
  F1 сделать добавлялку с авто-нумератором.
  т.е. f = create-adder( "result=" );
  f { body1 }
  f { body2 }

  F2 сделать доступ к параметрам через scope

  F3 сделать текст фиелд+

  F4 заменить на функцию/фичу+

  @data | get-cell "d1" | set-cell-value (
          @x1 | dom_event_cell "change" | c-on "(evt) => parseFloat( evt[0].target.value )" 
        )
  ну.. наверное вход это канал события а выход.. тож канал... куды писать
*/

create-adder: feature {
 ff: feature 
      cnt=0 
 {
   t: text (join (@t->my_cnt @ff->title)) 
   {{
     x-js (make-func { |cnt, mycnt|
          list @mycnt @cnt | set-cell-value	(once { (get-cell-value @cnt) + 1 });
         }) (@ff | get-cell "cnt") (@t | get-cell "mycnt");
   }}
   ;
 }
};
