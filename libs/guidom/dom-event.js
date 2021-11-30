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
        eval(obj.params.code);
      }
   }

   var unbind;
   var forget_bound_dom;
   obj.addObjRef("object","..",null,(o) => {
    if (unbind) { unbind(); unbind = null; }
    if (forget_bound_dom) { forget_bound_dom(); forget_bound_dom = null };

    unbind = o.onvalue("dom",() => {
      if (forget_bound_dom) forget_bound_dom();

      let bound_dom = o.dom;
      let bound_event = obj.params.name;

      o.dom.addEventListener( bound_event,callcmd )

      forget_bound_dom = () => {
        bound_dom.removeEventListener(bound_event,callcmd );
      }
    })
   })

   obj.on("remove",() => {
      if (unbind) { unbind(); unbind = null; }
      if (forget_bound_dom) { forget_bound_dom(); forget_bound_dom = null };
   })

}