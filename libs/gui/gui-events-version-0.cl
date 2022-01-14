// некая замудрая версия - проще использовать прямо dom_event, см gui-events.cl

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
