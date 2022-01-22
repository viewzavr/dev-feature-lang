/// недоделка

/// вот всякие pointermove они ловятся через dom_event нормально..
/// а вот pointerdown и затем pointerdownmove (нажали и ведут мыш) это интересно...
/// ну и pointerdownup (нажали мб поводили и подняли)

/* как использвоать:
  rect {{
    pointerdownmove {
       ...;
    }
    pointerdownup {
       
    }
  }}

  ну или еще, в стиле combinedmouse из compose
  rect {{
    downmotion start={ ... } move={ .... } finish={....}
  }}

  т.е. речь идет о том что мы это группируем... и можем задавать разные handler-ы

  вопрос - а почему у нас handler-ы это обязательно наборы окружений?
  формально это может быть что-то что можно "вызвать" т.е. типа ссылка на команду.. быб...
  наверное если бы func выдавала в свой output указатель на вызов себя, то тогда

  downmotion move=( setter {} )

  короче не так. мы должны дать такие аргументы просто, у которых есть метод apply..
  что-то вроде такого.. func-подобного.. а как уж его задали, через code, окружения, или cmd-ссылку
  это типа нас не колышет... вот так должно быть...

  т.е. формально типа
  downmotion move=( js code=``) finish=( func cmd=.. ) start=( setter ... )

  ну вот и вопрос, что делать - {} или (). Разумно конечно ().
  Но вот пользователю что делать? Как он догадается что следует применять?...

  А может стоит тут иметь нечто другое универсальное, не строчку например а нечто "вызываемое"..?
  наверное это связано все с inline-js. подумать надо.

  В целом получается надо продумывать систему передачи событий.

*/

/*
register_feature name="downmotion" {
   dm: {
      start:  func { deploy_many @dm->start; }
      finish: func { deploy_many @dm->finish; }
      move:   func { deploy_many @dm->move; }

      dom_event object=@dm->host name...= cmd={}
      code=`
        env.object.ns.childrenTable.start.callCmd("apply");
      `;
   }
}

register_feature name="downmotion" {
      dom_event name="pointerdown" code=`
        env.setParam("dragging",true);
        env.setParam("drag_start_screen_x",args[0].screenX );
        env.setParam("drag_start_x",parseFloat(env.params.x) );
        env.dom.setPointerCapture( args[0].pointerId );
        console.log("SETTED DSX",args[0].screenX);
      `;

      dom_event name="pointerup" code=`
        env.setParam("dragging",false);
      `;

      dom_event name="pointermove" code=`
        if (env.params.dragging) {

          var event_data = args[0];
          
          //console.log(args);
          var maxx = parseFloat( env.ns.parent.params.width ) - parseFloat( env.params.width );
          var newx = event_data.screenX - env.params.drag_start_screen_x + env.params.drag_start_x;
          //debugger;
          //console.log("eeee",newx,maxx,env.params.width);
          if (newx < 0) newx = 0;
          if (newx > maxx) newx = maxx;
            //console.log("setting",newx + "px")
          env.setParam("x", newx + "px");
          //console.log("ddd vv",newx / maxx); 
          
          env.ns.parent.setParam( "value",newx / maxx );
        }
      `;
*/      

/*
register_feature name="clicked" {
    func 
    {{ js code=`
       let monitored_dom;
       env.host.host.onvalue("dom",(dom) => {
          unsub();
          dom.addEventListener( "click", f);
          monitored_dom = dom;
       })
       function f() {
          env.host.callCmd("apply");
          //if (feature_env.params.cmd) 
          //feature_env.callCmdByPath(feature_env.params.cmd);
       }
       function unsub() {
          if (monitored_dom)
              monitored_dom.removeEventListener( "clicked", f);
          monitored_dom = null;
       }
       env.on("remove",unsub);
    `;
  }}
};

register_feature name="doubleclicked" {
    func 
    {{ js code=`
       let monitored_dom;
       env.host.host.onvalue("dom",(dom) => {
          unsub();
          dom.addEventListener( "dblclick", f);
          monitored_dom = dom;
       })
       function f() {
          env.host.callCmd("apply");
          //if (feature_env.params.cmd) 
          //feature_env.callCmdByPath(feature_env.params.cmd);
       }
       function unsub() {
          if (monitored_dom)
              monitored_dom.removeEventListener( "dblclick", f);
          monitored_dom = null;
       }
       env.on("remove",unsub);
    `;
  }}
};

/// вот всякие pointermove они ловятся через dom_event нормально..
/// а вот pointerdown и затем pointerdownmove (нажали и ведут мыш) это интересно...
/// ну и pointerdownup (нажали мб поводили и подняли)

register_feature name="pointermove" {
    func 
    {{ js code=`
       let monitored_dom;
       env.host.host.onvalue("dom",(dom) => {
          unsub();
          dom.addEventListener( "pointermove", f);
          monitored_dom = dom;
       })
       function f(event) {
          env.host.callCmd("apply",event);
          //if (feature_env.params.cmd) 
          //feature_env.callCmdByPath(feature_env.params.cmd);
       }
       function unsub() {
          if (monitored_dom)
              monitored_dom.removeEventListener( "pointermove", f);
          monitored_dom = null;
       }
       env.on("remove",unsub);
    `;
  }}
};
*/