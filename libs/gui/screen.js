// предназначение - быть экраном

// тут вся завязка на активацию. но в целом это не чувствуется что прям полезно, может это по-проще можно сделать все
// и убрать сущность "экран" вовсе. потому что по идее в конце концов мы садимся на некий dom-элемент и должны дать
// ему наполнение.. вот и вся история...

//import * as D from "./dom.js";

export function setup( vz, m ) {
  vz.register_feature_set( m );
//  D.setup( vz, D );
}

/*
export function setup( vz ) {

  vz.addItemType( "screen","GUI: screen", function( opts ) {
    return create( vz, opts );
  }, {guiAddItems: true, guiAddItemsCrit: "gui"} );

}
*/

addStyle(`[hidden] {
    display: none !important;
}

.vz-screen {
  pointer-events: none !important;
}

.vz-screen > * {
  pointer-events: all !important;
}

.vz-mouse-transparent-layout {
  pointer-events: none !important;
}

.vz-mouse-transparent-layout > * {
  pointer-events: all !important;
}

`)

// вот это выше очень важная история для работы orbitcontrol и т.п. у three-js вещей
// если экрану оставить события, то он почему-то не дает работать орбит-контролу
// поэтому мы у экрана события забираем, а оставляем тем кто в него вложен непосредственно
// пока так

/*
.vz-screen {
  pointer-events: all !important;
}
*/


function addStyle( styles ) {
  var styleSheet = document.createElement("style");
  styleSheet.type = "text/css"; styleSheet.textContent = styles;  
  document.head.appendChild(styleSheet)
}


export function screen( obj, opts )
{
  /*
  return new Promise( (res,rej) => {
    obj.feature("dom").then( () => {
      p.resolve();

    })
  })
  obj.feature("dom").then( () => {
    p.resolve();
  })
  obj.import("dom").then( (m) => {
  })
  */

  //obj.env("add_css_style").feature("add_css_style",{content:`[hidden] { display: none !important; }`);

  obj.feature("dom");
  obj.setParam("visible",false);
  obj.setParam("class","vz-screen");

  obj.onvalue("dom",(dom) => {
    console.log("screen: dom changed", dom)
    //console.trace();
    
    obj.addCmd("activate",() => {
      console.log("ACTIVATE CALLED");
      //qmlEngine.rootObject.setActiveScreen( obj );
      vzPlayer.feature("screens-api");
      vzPlayer.setParam("active_screen",obj,true);
    });

    qmlEngine.rootObject.dom.appendChild( dom );

    console.log("screen is emitting");
    obj.emit("screen-created");
  })

  return obj;
}

export function auto_activate(env) {
  //env.feature("screen").then( () => env.activate() );
  if (env.activate) {
    env.activate();
  }
  else {
    env.once('screen-created', () => env.activate() )
  }
}

export function activate_by_hotkey(env) {
  

 var unsub = () => {};
 env.onvalue( "hotkey",(key) => {

  unsub();

  function f(e) {
    if ( e.ctrlKey && ( String.fromCharCode(e.which) == key || String.fromCharCode(e.which) == key.toUpperCase() ) ) {
       var cur = vzPlayer.getParam( "active_screen");
       if (cur == env) {
          var prev = vzPlayer.getParam( "prev_screen");
          if (prev?.activate)
            prev.activate();
       }
       else
        env.activate();
    }
  }

  document.addEventListener('keydown', f );
  unsub = () => { document.removeEventListener('keydown', f ) };
 })

 env.on("remove",() => {
  debugger;
  unsub();
});

};