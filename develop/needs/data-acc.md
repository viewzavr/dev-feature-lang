
window_height=(@output_window_size | geta "height" default=0)

и вот она если меняется в 0 -- то не надо ее передавать. (нужна такая логика)

а ведь у нас тут правило - что передавать надо..
и вот как на компаланге это описать?
по идее можно было бы какой-то m-eval с аккумулятором может быть приделать...

----

пока пришлось решить таким подходом:
        let nonzero_window_size=(@output_window_size | m_eval "(ws) => {
            if (ws.width != 0 && ws.height != 0) 
               env.prev_ws = ws;
            return env.prev_ws || ws;
          }");
и затем          
window_height=(@nonzero_window_size | geta "height" default=0)