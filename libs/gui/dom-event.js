export function setup( vz, m ) {

  vz.register_feature_set( m );
}

export function dom_event( obj, options )
{
   obj.feature("call_cmd_by_path");

   function callcmd() {
      
      if (obj.params.cmd)
        obj.callCmdByPath( obj.params.cmd );
      if (obj.params.code) {
        var env = obj;
        var object = obj.params.object;
        if (object) 
            eval(obj.params.code);
      }
   }

   var unbind;
   var forget_bound_dom;

   function dobind() {
    if (unbind) { unbind(); unbind = null; }
    if (forget_bound_dom) { forget_bound_dom(); forget_bound_dom = null };

    var o = obj.params.object;
    if (!o) return;

    unbind = o.onvalue("dom",() => {
      if (forget_bound_dom) forget_bound_dom();

      let bound_dom = o.params.dom;
      let bound_event = obj.params.name;

      if (!bound_event) {
        //console.error("dom_event: bound_event is null",bound_event);
        return;
      }
      console.log("dom_event: success bound_event",bound_event,obj.getPath(),bound_dom);

      bound_dom.addEventListener( bound_event,callcmd )

      forget_bound_dom = () => {
        console.log("dom_event: done unbound_event",bound_event,obj.getPath(),bound_dom);
        bound_dom.removeEventListener(bound_event,callcmd );
      }
    })
   }

   obj.addObjRef("object",null,null,dobind )
   obj.trackParam("name",dobind)

   if (!obj.params.object) obj.setParam("object","..");

   obj.on("remove",() => {
      if (unbind) { unbind(); unbind = null; }
      if (forget_bound_dom) { forget_bound_dom(); forget_bound_dom = null };
   })

}