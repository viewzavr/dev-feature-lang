export function setup(vz, m) {
  vz.register_feature_set( m );
}

// специфика nodejs
export function process_args( env )
{
  process.argv.forEach( (v,i) => {
    env.setParam( i, v )
  })
}

export function apply_by_hotkey(env) {

 env.feature("func");
 env.feature("param-alias");
 env.addParamAlias("hotkey",0);

 var unsub = () => {};
 env.onvalue( "hotkey",(key) => {

    unsub();

    function f(e) {


      if ( e.altKey && ( String.fromCharCode(e.which) == key || String.fromCharCode(e.which) == key.toUpperCase() ) ) {
        
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

export function text_to_arr( env ) {
  env.onvalue("input",(text) => {
    let arr = text.split("\n");
    env.setParam("output",arr );
  })
}