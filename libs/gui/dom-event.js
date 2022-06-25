export function setup( vz, m ) {

  vz.register_feature_set( m );
}

export function dom_event( obj )
{
   obj.feature("call_cmd_by_path");
   obj.feature("func");

   function callcmd(event_data) {
      obj.callCmd("apply",event_data); // переход к алогоритмам func
   }

   var unbind;
   var forget_bound_dom;

   function dobind() {
    if (unbind) { unbind(); unbind = null; }
    if (forget_bound_dom) { forget_bound_dom(); forget_bound_dom = null };

    var o = obj.params.object;
    if (!o) return;
    if (o.hosted) o = o.host; // такая добавка.. не знаю криминал или нет...

    unbind = o.onvalue("dom",() => {
      if (forget_bound_dom) forget_bound_dom();

      let bound_dom = o.params.dom;
      let bound_event = obj.params.name;

      if (!bound_event) {
        //console.error("dom_event: bound_event is null",bound_event);
        return;
      }
      //  console.log("dom_event: bound_event",bound_event,obj.getPath(),bound_dom);

      bound_dom.addEventListener( bound_event,callcmd )

      forget_bound_dom = () => {
        //console.log("dom_event: done unbound_event",bound_event,obj.getPath(),bound_dom);
        bound_dom.removeEventListener(bound_event,callcmd );
      }
    })
   }

   obj.addObjRef("object",null,null,dobind )
   obj.trackParam("name",dobind)
   
   if (!obj.params.object) {
      if (obj.hosted) // мы хостируимси - тогда object это хост
        obj.setParam("object",obj.host);
      else {
        obj.setParam("object","..");
      }
   }

   obj.on("remove",() => {
      if (unbind) { unbind(); unbind = null; }
      if (forget_bound_dom) { forget_bound_dom(); forget_bound_dom = null };
   })

}

export function on_dom_event( env )
{
   //console.log("on-dom-event. env id is",env.$vz_unique_id," my host id is",env.host.$vz_unique_id," and my scope is", env.$scopes.top(), "and host obj is", env.host)

   var forget_bound_dom = ()=>{};
   var forget_obj = ()=>{};

   env.onvalues([0,1,2],(obj,eventname,dom_event_handler) => {

     forget_obj();
     forget_obj = obj.onvalue("dom",(dom) => {
      forget_bound_dom();
      //console.log('subb',eventname,dom_event_handler)
      dom.addEventListener( eventname,dom_event_handler )
      forget_bound_dom = () => {
        dom.removeEventListener(eventname,dom_event_handler );
      };
    })

   });

   env.on("remove",() => {
     forget_bound_dom();
     forget_obj();
   })
}