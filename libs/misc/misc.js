export function apply_by_hotkey(env) {

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