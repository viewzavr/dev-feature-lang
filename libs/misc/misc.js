export function setup(vz, m) {
  vz.register_feature_set( m );
}

export function apply_by_hotkey(env,feature_env) {

 feature_env.feature("func");

 var unsub = () => {};
 feature_env.onvalue( "hotkey",(key) => {

    unsub();

    function f(e) {


      if ( e.ctrlKey && ( String.fromCharCode(e.which) == key || String.fromCharCode(e.which) == key.toUpperCase() ) ) {
        
        feature_env.callCmd( "apply" );
      }
    }

    document.addEventListener('keydown', f );
    unsub = () => { document.removeEventListener('keydown', f ) };
 })

 feature_env.on("remove",() => {
   unsub();
 });

};