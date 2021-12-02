// update
// теперь объект проходит по объектам и собирает их output
// которые должны содержать дом, массив дом, или функцию возвращающую оное.

export function setup( vz, m ) {
  vz.register_feature_set( m );
}

// предназначение - уметь добавить элемент из html
// идея - а что если совместить с контейнером?

/* Выясняется что надо иметь несколько видов dom
   1. dom который собственный элемент объекта. ну есть и все.
   2. dom который втаскивается в родительский объект (т.е. учавствует в комбинации)
   его может и не быть. например для диалогов выяснилось что им надо быть в корне желательно.
   3. dom в который втаскиваются дети, т.е. цель для комбинации.
   она может отличаться от dom (1) потому что мы можем создать обвязку, и детей надо вставлять куда-то внутрь.
*/

/* Получается guinode наш основной объект для создания gui. У него интерфейс - он выдает dom-узел.
   (todo сделать мб - несколько dom-узлов чтобы выдавал - тогда можно делать генератор и group)
   (генератор - чтобы по функции getDomы давал набор дом-ов..)

   Этот же гуиноде играет роль контейнера. Он цепляет детские dom в себя, в obj.combiningDom
   Возможно это стоит вынести отдельно, чтобы можно было делать разного рода контейнеры.

   Далее это садится в screen, а насчет них уже идет модель - показывать какой-то экран.

   И далее к этому guinnode приделаны guinodehtml и qml и еще xml.

   А ну и еще узел layout сделан - он раскладывает элементы в плоскости.
*/



// здесь f это функция создания dom-элемента
export function dom( obj, options )
{

  /////// собственный html-код
  //obj.setParamOption("output","internal",true);
  
  //obj.setParamOption("dom","internal",true);

  /*
  obj.addCmd("debug",() => {
    console.log(dom);
  })
  */

  obj.setParamOption("dom","internal",true);

  function trigger_dom_params() {
    if (obj.dom)
    for( let pn of obj.getParamsNames()) {
      maybe_apply_dom_attr( pn,obj.getParam(pn) );
      //if (!obj.hasCmd( pn )) obj.signalParam( pn );
      // тут и аттрибуты dom будут и наши параметры
    }
  }

  // волшебный мостик
  obj.on('param_changed',(name,value) => {
    maybe_apply_dom_attr( name, value );
  });

  function maybe_apply_dom_attr( name, value ) {
    if (obj.dom && name.startsWith("dom_")) {
       name = name.substring(4);
       obj.dom.setAttribute(name,value);
    }
  }

  function apply_dom_params() {
    //// фишка участия во flex-раскладке (пока тут)
    obj.addString("flex","",(v) => {
      obj.dom.style.flex = v;
    })

    obj.addText("style","",(v) => {
      obj.dom.style.cssText = obj.dom.style.cssText + ";" + v; // todo странная вещь - будет расти
    })

    obj.addString("padding","0em",(v) => {
      obj.dom.style.padding = v;
    })

    obj.addString("margin","0em",(v) => {
      obj.dom.style.margin = v;
    })

    obj.addString("class","",(v) => {
      obj.dom.className = v;
    })

    obj.addString("innerHTML","",(v) => {
      console.log("dom:innerHTML assign",obj.getPath(),v)
      obj.dom.innerHTML = v.toString ? v.toString() : v;
    })

    // ну это вестимо да, всем надо..
    obj.addCheckbox("visible",true,(v) => {
      /*
       if (v) dom.removeAttribute("hidden")
        else
       dom.setAttribute("hidden", true)
     */
        //v ? dom.classList.remove("vz_gui_hide") : dom.classList.add("vz_gui_hide");
        
        obj.dom.hidden = !v;
        //dom.style.visibility = v ? 'visible' : 'collapse';
    })    
  }

  obj.on("remove",() => {
    if (obj.dom)
        obj.dom.remove();
  });
  
  obj.trackParam( "tag", () => {
    create_this_dom();
  }); // это вызовется если только параметр поменяеца
  
  //// поведение контейнера
  // todo надо будет разделить dom и childdom т.к. формально это разное

  obj.outputDom = () => obj.dom;    // выходной дом для кобминаций
  obj.combiningDom = () => obj.dom; // целевой комбинирующий дом
  obj.inputObjectsList = () => obj.ns.children;

  obj.setParam("output",() => obj.outputDom() )

  obj.on("appendChild",rescan_children);
  obj.on("forgetChild",rescan_children);

  create_this_dom();

  // это у нас по сути - алгоритм комбинации из SICP.
  // ВОЗМОЖНО его надо будет сделать перенастраиваемым

  obj.rescan_children = delayed(rescan_children);

  //obj.rescan_children = rescan_children;
  
  function rescan_children() {
    clear_viewzavr_dom_children();

    let target  = obj.combiningDom();
    //let inputs = obj.inputObjectsList();
    let inputs = obj.ns.children;
    for (let c of inputs) {
      if (c.protected) continue;

      var od = c.params.output;
      if (typeof(od) === "function") od = od();

       //let od = c.outputDom ? c.outputDom() : null;
       if (od) {
          //target.appendChild( od );
          //od.viewzavr_combination_source  = c; // в него прям поселим
        
           if (!Array.isArray(od)) od = [od];
           //od = od.flat(8);
           for (let odd of od) {
             // там в output всякого напихать могут..
             if (odd instanceof Element) {
               target.appendChild( odd );
               //console.log("adding child dom",odd);
               odd.viewzavr_combination_source  = c; // в него прям поселим
             }
           } 
       }
    }
  }

  function clear_viewzavr_dom_children() {
    var acc = [];
    for (let dc of obj.dom.children) {
      if (dc.viewzavr_combination_source) {
        if (dc.viewzavr_combination_source.protected) continue; 
        acc.push( dc );
      }
    }
    for (let dc of acc)
      dc.remove();
  }

  Object.defineProperty(obj, "visible", { 
     set: function (x) { obj.setParam("visible",x); },
     get: function() { return obj.params.visible; }
  });
  obj.addCmd("trigger_visible",() => { 
    //obj.visible = !obj.visible 
    obj.setParam("visible", !obj.visible, true); // отметка что сделано вручную
  });

/*
  // feature: передать слот
  if (opts?.params?.slot) {
    //obj.dom.slot = opts.params.slot;
    obj.dom.setAttribute("slot",opts.params.slot);
  }
*/  
  // это надо для слотов
/*
  if (options?.params?.name)
    obj.dom.setAttribute("name",opts.params.name);

  if (options?.params?.class)
    obj.dom.setAttribute("class",opts.params.class);

  // тыркнем родителя
  if (obj.ns.parent?.rescan_children) obj.ns.parent.rescan_children();
  // @todo переделать на нормальную ТПУ
*/  

  function create_this_dom() {
    var t = obj.params.tag || "div";
    if (obj?.dom?.$cl_tag_name == t) return;

    if (obj.dom) obj.dom.remove();

    obj.dom = document.createElement( t );
    obj.dom.$cl_tag_name = t;
    obj.setParam("dom",obj.dom);
    rescan_children();
    trigger_dom_params();
    apply_dom_params();

    //trigger_all_params();
    if (obj.ns.parent?.rescan_children) obj.ns.parent.rescan_children();
  }
  

  return obj;
}




/* алгоритм очистки всех чилренов дома */
function clear_dom_children(dom) {
  while (dom.firstChild) 
    dom.removeChild( dom.lastChild );
}


/*
export function create_shadow( vz, opts, f )
{
  var obj = vz.createObjByType( {...opts,type:"guinode"} );

  obj.outputDom = () => null;

  // todo on parentchange
  if (opts.parent) {
     obj.shadow_instance = opts.parent.dom.attachShadow({mode: 'open'});
     obj.combiningDom = () => obj.shadow_instance;
  }

  return obj;
}
*/

/*
export function addStyle( styles ) {
  var styleSheet = document.createElement("style");
  styleSheet.type = "text/css"; styleSheet.textContent = styles;  
  document.head.appendChild(styleSheet)
}

addStyle(".vz_gui_hide { display: none !important; }")
*/

///////////////////////////////////////////

function delayed( f,delay=0 ) {
  var t;

  var res = function() {
    if (t) return;
    t = setTimeout( () => {
      t=null;
      f();
    },delay);
  }

  return res;
}