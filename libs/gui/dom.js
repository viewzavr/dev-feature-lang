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
export function dom( obj, options={} )
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

  // это dom_attributes
  function apply_dom_attrs() {
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

  // todo
  // dom_*, dom_attr_* = аттрибут dom
  // dom_obj_* - поле объекта dom
  // dom_style_* - кусочек стиля
  // style_id - добавка к стилям в виде строки
  function maybe_apply_dom_attr( name, value ) {
    if (obj.dom && (name.startsWith("dom_") && !name.startsWith("dom_attr_") && !name.startsWith("dom_obj_") && !name.startsWith("dom_style_") && !name.startsWith("style_"))) {
       name = name.substring(4);
       
       obj.dom.setAttribute(name,value);
       return true;
    }
    else
    if (obj.dom && name.startsWith("dom_attr_")) {
       name = name.substring(9);
       obj.dom.setAttribute(name,value);
       return true;
    }
    return maybe_apply_dom_prop( name, value ) || maybe_apply_dom_style( name, value ) || maybe_apply_style_part( name, value );
  }

  function maybe_apply_dom_prop( name, value ) {
    if (obj.dom && name.startsWith("dom_obj_")) {
       name = name.substring(8);
       //obj.dom.setAttribute(name,value);
       ///console.log("dom: setting name=",name,"value=",value)
       obj.dom[name] = value;
       return true;
    }
    return false;
  }

  // здесь получается доступ через js-нотацию
  function maybe_apply_dom_style( name, value ) {
    if (obj.dom && name.startsWith("dom_style_")) {
       name = name.substring(10);
       //console.log("setting dom style",name,value)
       obj.dom.style[name] = value || "";
       
       //styles_hash[ name ] = name + ":" + value;
       //obj.signalParam("style");
        
       return true;
    }
    return false;
  }

// здесь получается доступ через js-нотацию
  let styles_hash = {};
  function maybe_apply_style_part( name, value ) {
    if (obj.dom && name.startsWith("style_")) {
       styles_hash[ name ] = value;

       //console.log("style part",obj.getPath(),name,value)

       obj.signalParam("style");
       //name = name.substring(10);
       //obj.dom.style[name] = value;
        
       return true;
    }
    return false;
  }  
  
  // это наши параметры
  function apply_dom_params() {
    //// фишка участия во flex-раскладке (пока тут)
    obj.addString("flex","",(v) => {
      obj.dom.style.flex = v;
    })

    obj.addText("style","",(v) => {
      //obj.dom.style.cssText = v;
      // как делать несколько стилей по разным причинам?

      // с методом выше выяснилась засада - он перебивает остальное
      // пробуем так (хотя насколько этого хватит..)
      // obj.dom.style.cssText += ";"+v;
      //obj.dom.style.cssText += ";"+v;

      let s = v + ";" + Object.values(styles_hash).join(";");
      //console.log("style append",s)

      obj.dom.style.cssText += s;
      //console.log("total style",obj.dom.style.cssText)

      // todo короче это проблемное место. получается style_alfa=... и затем обнуление - уже не сработает
      // надо нормально делать а именно совмещать с dom_style_... как-то умудряться.
      // возможно, возможно, в dom_style добавить - что и прямая установка, и в хеш-часть
      // и тогда можно будет и быстро результат получать и все остальное.
      // см также в layout.js много ставят.. итого нужны аксессоры какие-то тут.

      //obj.dom.setAttribute('style', v);

      // todo: onvalue сделать оно 1 раз срабатывает а это каждый раз
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
      //console.log("dom:innerHTML assign",obj.getPath(),v)

      obj.dom.innerHTML = v?.toString ? v.toString() : (v || "");
    })
    obj.addString("innerText","",(v) => {
      //console.log("dom:innerText assign",obj.getPath(),v)
      obj.dom.innerText = v?.toString ? v.toString() : (v || "");
    });

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

  obj.outputDom ||= () => obj.dom;    // выходной дом для кобминаций
  obj.combiningDom ||= () => obj.dom; // целевой комбинирующий дом
  obj.inputObjectsList ||= () => obj.ns.children;

  obj.setParam("output",() => obj.outputDom() )

  //obj.rescan_children = delayed(rescan_children);
  obj.feature("delayed");
  var rescan_children_delayed = obj.delayed(rescan_children2);


  //obj.on("appendChild",(q) => rescan_children_delayed("by appendChild of "+q.getPath()));
  //obj.on("forgetChild",(q) => rescan_children_delayed("by forgetChild of "+q.getPath()));

  /* похоже что они не нужны - у нас уведомления от детей приходят когда они дом себе создают
     и когда они грохаются...
     по уму надо бы мониторить их output но пока так..
     т.е. эти дети сами нам вызывают rescan

  obj.on("appendChild",(q) => {
     if (q.is_feature_applied("dom") || q.is_feature_applied("dom_group") || q.is_feature_applied("shadow_dom")) 
       rescan_children_delayed("by appendChild of "+q.getPath())
  });
  obj.on("forgetChild",(q) => {
    // todo оптимизировать свести к одной фиче
     if (q.is_feature_applied("dom") || q.is_feature_applied("dom_group") || q.is_feature_applied("shadow_dom")) 
       rescan_children_delayed("by forgetChild of "+q.getPath())
  });
  */

  //obj.on("appendChild",rescan_children2);
  //obj.on("forgetChild",rescan_children2);

  create_this_dom();

  // это у нас по сути - алгоритм комбинации из SICP.
  // ВОЗМОЖНО его надо будет сделать перенастраиваемым


  obj.addCmd("rescan_children",(reason) => rescan_children_delayed(reason) )
  //obj.addCmd("rescan_children",() => rescan_children2() )

  //obj.rescan_children = rescan_children;
  
  function rescan_children2(reason) {
   //console.log("rescan_children2 called", obj.getPath(), "["+reason+"]")
    clear_viewzavr_dom_children();

    let target  = obj.combiningDom();
    let inputs = obj.inputObjectsList();
    //let inputs = obj.ns.children;

    // вещь - побороться за правильный порядок. а то они вставляются каждый когда захотят
    // прочем не помогает порядок сохранять..
    const frag = document.createDocumentFragment();

    // почистим ко - боремся за порядок
    /* так мы уже почистили так-то...
    while (target.firstChild) {
      //target.firstChild.remove()
      target.removeChild( target.firstChild );
    }
    */

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
               frag.appendChild( odd );
               //console.log("adding child dom",odd);
               odd.viewzavr_combination_source  = c; // в него прям поселим
             }
           }
       }
    }

    target.appendChild( frag ); // всех запихнули в правильном порядке..
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
    //console.log("v triggered",obj.dump(),obj)
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

    obj.dom = options.elem_creator_f ? options.elem_creator_f( t ) : document.createElement( t );
    obj.dom.$cl_tag_name = t;
    obj.setParam("dom",obj.dom);
    rescan_children2("create_this_dom");
    apply_dom_attrs();
    apply_dom_params();

    obj.signalParam("style"); // хак

    //trigger_all_params();
    //if (obj.ns.parent?.rescan_children) obj.ns.parent.rescan_children();
    if (obj.ns.parent) {
        obj.ns.parent.callCmd("rescan_children","child created dom"+obj.getPath());
    }
  }

  obj.on("remove",() => {
    if (obj.ns.parent) {
        obj.ns.parent.callCmd("rescan_children","child removed"+obj.getPath());
    }
  });
  

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

/*
нужна возможность задавать новое тело для реализации.
идеи возмьем из вебовского shadow-dom, но тут у нас своя реализация.

смысл - мы меняем поведение родителя на тему dom-комбинации
в результате родитель начинает собирать dom из детей этого shadow-dom
при этом список children родителя остается каким был, им можно пользоваться.
(но при этом shadow_dom не вносится в список детей)

т.е. здесь родитель получается берет детей shadow-дом узела в dom-компоновку
кстати это можно было бы выразить модификатором, см ниже, dom_group / insert_dom_children from=@.
но есть и отличие - dom_group не удаляет поведение по поиску других детей из родителя
а эта штука должна удалять, в этом ее и смысл..
*/
export function shadow_dom( obj, options )
{
  // 1 модифицировать у парента поведение выбора чего добавлять в дом
  // а нам надо сделать так чтобы он добавлять стал нас а не детей своих
  obj.inputObjectsList = () => obj.ns.children;
  // вот здесь важно - мы меняем поведение родителя, перехватывая его функцию комбинирования
  // и уводя с его детей на детей этого shadow_dom

  //if(!obj.ns.parent.inputObjectsList)
    //console.error("shadow_dom: parent still has no inputObjectsList",obj.ns.parent.getPath())

  //console.log("shadowdom fixes 1", obj.getPath(), obj.ns.parent.getPath())
  obj.ns.parent.inputObjectsList = () => {
    //console.log("shadowdom's parent ",obj.ns.parent.getPath(),"asked for inputObjectsList and returns list of shadow_dom", obj.inputObjectsList())
    return obj.inputObjectsList();
  }
  // сделано так чтобы смогла получиться рекурсия.

  // 2 убрать себя из списка детей парента
  var shadow_parent = obj.ns.parent;
  obj.ns.parent.ns.forgetChild( obj );
  obj.ns.parent = shadow_parent; // надо для ссылок ../..
  
  // после этого связть только через inputObjectsList получается, что в принципе норм.
  // вопрос - а не потеряет ли от этого искалка?
  // мы убираем себя из списка детей затем, чтобы другие искалки - находили детей родителя но не нас
  
  // 3. будут вызывать rescan_children и еще события слать
  // если к нам пришла необходимость чего-то сканировать - мы попросим парента (зачем?)
  obj.rescan_children = function() {
    console.log("shadow_dom 3: rescan called", obj.getPath())
    shadow_parent.rescan_children();
  }
  //obj.on("appendChild",obj.rescan_children);
  //obj.on("forgetChild",obj.rescan_children);

  // ну ка тыркнем ка родителя сами тоже
  shadow_parent.callCmd("rescan_children","shadow dom created");
}

// dom_group - цель это сделать так, чтобы все дети dom_group попали в dom-комбинацию
// к родителю. таким образом можно делать dom_group { dom1; dom2 } и вот эти оба 
// dom1 dom2 уедут к родителю dom_group-а

export function dom_group( env ) {

  env.feature("delayed");
  let rescan_delayed = env.delayed( rescan );
  env.on("childrenChanged",rescan_delayed);

  env.onvalue("input",rescan);
  // тупо это конечно все с текущими уведомлениями rescan_children..
  // типа дети сами кого-то там уведомляют. но ничего, сдюжим.

  function rescan() {
    env.setParam("output", () => {
      let acc = [];
      env.ns.children.forEach( 
          (c) => {
            let od = c.params.output;
            if (typeof(od) === "function") od = od();
            if (Array.isArray(od)) od.forEach( (el) => acc.push(el) )
              else acc.push( od );
          }
       );

      
      if (Array.isArray(env.params.input)) 
      for (let c of env.params.input)
          {
            if (!c) continue;

            // разрешим подавать на input массив в котором есть функции
            if (typeof(c) === "function") c = c();

            if (c instanceof Element)
            {
              acc.push( c ); // разрешим подавать массив просто дом объектов
              continue;
            }            

            let od = c.params.output;
            if (typeof(od) === "function") od = od();
            if (Array.isArray(od)) od.forEach( (el) => acc.push(el) )
              else acc.push( od );
          };
          

      return acc;

      /* вариант с мэп не учитывает что могут вернуть массив и получится мы генерим массив массивов
         а я решил этого не делать чтобы потом в дом сборщике не писать dom.flat
       return env.ns.children.map( 
          (c) => {
            let od = c.params.output;
            if (typeof(od) === "function") od = od();
            return od;
          }
       );
       */
    } );

    // наш output изменился - надо тыркнуть родителя
    if (env.ns.parent) 
        env.ns.parent.callCmd("rescan_children");
  }

  // предоставляем апи для нашего дом - это нас дети так тыркать будут
  env.addCmd("rescan_children",rescan_delayed );

  rescan();
}
// todo идея передалать dom на f_monitor_children_output


// поведение аналогично dom_group но список узлов берется не из детей этого узла
// а из детей произвольного узла.
// о а пусть это будет модификатор..

// а кстати вроде как зачем нам append-ить. когда мы можем именно что перехватывать..

// итого получилось - use_dom_children - модификатор - заставляет узел использовать
// в качестве дом-детей детей указанного узла. все.
// пример: use_dom_children from=@some-other-env;
// todo - если введем ->children то можно будет как-то с этим работать тоже.
export function use_dom_children( env ) {

  env.onvalue("from",(from) => {

    env.host.inputObjectsList = () => {
      //return from.inputObjectsList();
      return from.ns.children;
      // если мы используем from.inputObjectsList(); то он уже может быть заменен 
      // на что-то левое. нам именно детей подавай.
    };

    env.host.callCmd("rescan_children");

    from.rescan_children = function() {
      env.host.rescan_children();
    };

  })
  
}