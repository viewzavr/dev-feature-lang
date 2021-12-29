export function setup(vz, m) {
  vz.register_feature_set( m );
}

export function apply_by_hotkey(env) {

  env.feature("func");

 var unsub = () => {};
 env.onvalue( "hotkey",(key) => {

    unsub();

    function f(e) {
      if ( e.ctrlKey && ( String.fromCharCode(e.which) == key || String.fromCharCode(e.which) == key.toUpperCase() ) ) {
        
        env.callCmd( "apply" );
      }
    }

    document.addEventListener('keydown', f );
    unsub = () => { document.removeEventListener('keydown', f ) };
 })

 env.on("remove",() => {
  unsub();
});

};