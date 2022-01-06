export function setup( vz, m ) {

  vz.register_feature_set( m );
}

export function dom_event( obj, feature_env )
{
   feature_env.feature("call_cmd_by_path");
   feature_env.feature("func");

   function callcmd(event_data) {
      feature_env.callCmd("apply",event_data);
      /*
      if (obj.params.cmd)
        obj.callCmdByPath( obj.params.cmd );
      if (obj.params.code) {
        var env = obj;
        var object = obj.params.object;
        if (object) 
            eval(obj.params.code);
      }
      */
   }

   var unbind;
   var forget_bound_dom;

   function dobind() {
    if (unbind) { unbind(); unbind = null; }
    if (forget_bound_dom) { forget_bound_dom(); forget_bound_dom = null };

    var o = feature_env.params.object;
    if (!o) return;

    unbind = o.onvalue("dom",() => {
      if (forget_bound_dom) forget_bound_dom();

      let bound_dom = o.params.dom;
      let bound_event = feature_env.params.name;

      if (!bound_event) {
        //console.error("dom_event: bound_event is null",bound_event);
        return;
      }
//      console.log("dom_event: success bound_event",bound_event,obj.getPath(),bound_dom);

      bound_dom.addEventListener( bound_event,callcmd )

      forget_bound_dom = () => {
        //console.log("dom_event: done unbound_event",bound_event,obj.getPath(),bound_dom);
        bound_dom.removeEventListener(bound_event,callcmd );
      }
    })
   }

   feature_env.addObjRef("object",null,null,dobind )
   feature_env.trackParam("name",dobind)

   
   if (!feature_env.params.object) {
      // корявое
      if (feature_env !== obj)
        feature_env.setParam("object",obj);
      else
        feature_env.setParam("object","..");
   }

   feature_env.on("remove",() => {
      if (unbind) { unbind(); unbind = null; }
      if (forget_bound_dom) { forget_bound_dom(); forget_bound_dom = null };
   })

}