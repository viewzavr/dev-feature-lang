// предназначение - показать диалог.

//import * as S from "../screen.js";

export function setup( vz, m ) {
  vz.register_feature_set( m );
//  D.setup( vz, D );
}

function addStyle( styles ) {
  var styleSheet = document.createElement("style");
  styleSheet.type = "text/css"; styleSheet.textContent = styles;  
  document.head.appendChild(styleSheet)
}

// иначе немодальный диалог болтается внизу
addStyle( `
dialog {  
    position: fixed;
    top: 0px;
    bottom: 0px;
    max-width: calc((100% - 6px) - 2em);
    max-height: calc((100% - 6px) - 2em);
    z-index: 11000;
}

dialog .vz-dlg-close {
    position: absolute;
    right: 2px; top: 2px;
    cursor: pointer;
}
`)

export function dialog( obj, opts )
{
  obj.setParam("tag","dialog")
  obj.feature( "dom" );

  dialog_polifill_feature( obj.dom );

  document.body.appendChild( obj.dom );

  obj.setParam("output",null); // чтобы не затаскивали в свои дом-ы

  obj.show = () => { obj.emit("show"); obj.emit("opened"); obj.dom.show(); }
  obj.showModal = () => { obj.emit("show"); obj.emit("opened"); obj.dom.showModal(); }
  
  // совместимость - надоело запоминать что там
  obj.open = obj.show;
  obj.openModal = obj.showModal;

  obj.close = (ret) => {
    obj.dom.close(ret); obj.emit("close"); }

  //obj.addCmd( "show", () => obj.show() );
  obj.addCmd( "show_modal", () => obj.showModal() );
  // obj.addCmd( "close", () => obj.close() );
  // вот почему у меня тут разные наименования? не знаю..

  // апплий было showModal но пока сделал show
  obj.addCmd("apply", () => obj.show())

  // фича мышкой закрывать диалоги
  // я редактировал длинный код и два раза кликнул и оно закрылось. это был криминал.
  // либо надо спрашивать перед закрытием...
  // obj.dom.addEventListener("dblclick", obj.close);

  // фича крестик
  var cr = document.createElement("span");
  cr.innerText = "X";
  cr.classList.add("vz-dlg-close");
  cr.addEventListener("click", obj.close);
  //var s = obj.dom.attachShadow({mode: 'open'});
  obj.dom.appendChild( cr );

  return obj;
}

///////////////////////////////////////////////
// dialog нету в файрфокс - используем полифилл

if (false) S.addStyle( `
dialog {
  position: absolute;
  left: 0; right: 0;
  width: -moz-fit-content;
  width: -webkit-fit-content;
  width: fit-content;
  height: -moz-fit-content;
  height: -webkit-fit-content;
  height: fit-content;
  margin: auto;
  border: solid;
  padding: 1em;
  background: white;
  color: black;
  display: block;
}

dialog:not([open]) {
  display: none;
}

dialog + .backdrop {
  position: fixed;
  top: 0; right: 0; bottom: 0; left: 0;
  background: rgba(0,0,0,0.1);
}

._dialog_overlay {
  position: fixed;
  top: 0; right: 0; bottom: 0; left: 0;
}

dialog.fixed {
  position: fixed;
  top: 50%;
  transform: translate(0, -50%);
}
`) // это копипаста из их css

import dialogPolyfill from "./dialog-polyfill/dist/dialog-polyfill.esm.js"
function dialog_polifill_feature( dom ) {
   //S.addStyleHref( vz.getDir( import.meta.url.split ) + ) - не надо, сделал копипасту
   dialogPolyfill.registerDialog( dom );
}