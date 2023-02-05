// todo parameter animation - правильное название
// min, max заменить на from, to..
// сейчас сделано что при изменении gui целевого параметра меняется min,max
// возможно их стоит вынести на кнопку

export default function setup( vz, m ) {
  vz.register_feature( "animation-player", animation_player );
  vz.addType( "animation-player", (vz,opts)=>vz.createObj(opts), { title: "Animation player", cats: "animation"})
  vz.register_feature( "animation-player-priority", ()=>{} );
}

import * as DP from "../../../../viewzavr-core/extend/delayed-pool.js";

export function animation_player( obj, opts ) 
{
  var root = obj.findRoot();
  let unsub = () => {};

  //obj.feature("enabled");
  obj.addCheckbox( "playing",false );
  //obj.setParam("enabled",false);
  obj.addSlider("progress",0,0,100,1);

  //obj.setParamOption("enabled","visible",false);

  //obj.addCombo( "parameter",0,["a","b","c"] );
  
  /*
  obj.addParamRef( "parameter","", crit, (param_path) => {
    // здесь param_path это строковая ссылка
    // updateminmax();
  }, root )*/

  obj.addComboValue( "parameter", obj.params.parameter, ["-"].concat( obj.params.parameters || []) )
  obj.onvalue("parameters",() => {
    obj.addComboValue( "parameter", obj.params.parameter, ["-"].concat( obj.params.parameters || []) )
  })
  
  obj.onvalue("parameter",updateminmax);

  //obj.setParamOption("parameter","title","Choose parameter")
  obj.addCmd("update min-max",updateminmax);
  //obj.addFloat( "start_value",0 );
  obj.addFloat( "min",0 );
  obj.addFloat( "max",1 );
  obj.addFloat( "step",1 );
  obj.addFloat( "delay",2 );
  obj.addLabel("cycle");

  obj.setParamOption( "playing", "priority",110);
  obj.setParamOption( "progress", "priority",105);

  obj.onvalue("search_root",(v) => obj.setParamOption("parameter","search_root",v));

  let itsme_c = false;
  obj.trackParam("progress",(v) => {
     if (itsme_c) return;
     if (!obj.params.parameter) return;

     // todo идея сделать просто min max параметра значение
    let nv = obj.params.min + (obj.params.max - obj.params.min) * v / 100.0;
    //obj.setParam("value", nv );
    var [tobj,tparam] = obj.params.parameter.split("->");
    tobj = root.findByPath( tobj );
    if (!tobj) return;

    var g = tobj.getGui(tparam);
    if (["slider","combo"].indexOf(g.type) >= 0) 
      nv = Math.floor( nv );

    tobj.setParam( tparam, nv );

  });
  /*
  obj.addFloat("value");
  obj.trackParam("value",(v) => {

  });
  */
  
  //obj.addCmd("stop",() => obj.setParam("enabled",false));
  obj.addCmd("play",() => obj.setParam("playing", true, true ));
  obj.addCmd("pause",() => obj.setParam("playing", false, true ));
  obj.addCmd("restart",() => { obj.setParam("playing",true, true); need_restart = true; });

  // вопрос это тут надо делать или где
  obj.setParamOption("play","visible",false);
  obj.setParamOption("pause","visible",false);
  obj.setParamOption("restart","visible",false);
  //obj.setParamOption("rescan-parameter","visible",false);
  obj.setParamOption("update min-max","visible",false);
  obj.setParamOption("status-parameter","visible",false);

/*
  obj.addCmd("start",() => { obj.setParam("enabled",true); need_restart = true; });
  obj.addCmd("stop",() => obj.setParam("enabled",false));
  obj.addCmd("pause",() => obj.setParam("enabled", !obj.params.enabled ));
*/  

  function crit( o ) {
    var acc = [];
    if (o.is_feature_applied("screen")) return;
    if (o.is_feature_applied("link")) return;

    for (var name of o.getGuiNames()) {
      var g = o.getGui(name);
      if (["float","slider","combo"].indexOf(g.type) >= 0) 
          acc.push( name );
    }

    if (o.is_feature_applied("animation-player-priority")) return { result: acc, priority: 1};

    return acc;
  }


  obj.on("remove",unsub);

  obj.feature("delayed")
  let updminmax_delayed = obj.delayed( updateminmax, 30);
  //obj.vz.tools.delayed( obj ).delayed( )
  // так тоже работает
  //var updateminmax_pending = false;
  /*
  obj.timeout( () => {
    if (updateminmax_pending) updateminmax();
  },60);
  */


  function updateminmax() {
    unsub(); unsub = () => {};
    if (!obj.params.parameter) return;
    var [tobjs,tparam] = obj.params.parameter.split("->");

    let tobj = root.findByPath( tobjs );
    //console.log("zeze",root)
    // debugger
    if (!tobj) { updminmax_delayed(); return; }

    var g = tobj.getGui( tparam );
    if (g) {
      obj.setParam( "min", g.min || 0,true );
      obj.setParam( "max", g.max || 1,true );
      obj.setParam( "step", g.step || 1,true );
      //obj.setParam( "start_value", tobj.getParam(tparam),true );
    }

    unsub = tobj.on("gui-changed-"+tparam,updateminmax);

/*
    obj.setParam( "min", tobj.getParamOption( tparam,"min") || 0 );
    obj.setParam( "max", tobj.getParamOption( tparam,"max") || 1 );
    obj.setParam( "step", tobj.getParamOption( tparam,"step") || 1 );
*/
 }

 obj.trackParam("playing",(v) => {
    if (v) {
       obj.setParam("cycle",0);
    }
    window.requestAnimationFrame( animframe );
 })

 var counter = 0;
 var need_restart = true;
 function animframe() {
    if (!obj.params.playing) return;
    window.requestAnimationFrame( animframe );

    // если грузим файлы - надо подождать.
    //if (qmlEngine.rootObject.propertyComputationPending > 0) return;
    //let root = env.findRoot();
    //if (root)
    //console.log(DP.qnext.length,obj.params.step_allowed);

    if ((root.params.loading_files || []).length > 0) return;
    // типа решил ладно уж тут в коде пусть все будет чем в 5 местах
    /*if (obj.params.step_allowed == false) {
     // console.log("step is not allowed")
      return;
    }
    */

    if (DP.qnext.length > 0) {
     // console.log( "DP.qnext.length is",DP.qnext.length);
      return;
    }

    counter++;
    if (obj.params.delay > 0 && counter % obj.params.delay !== 0) return;

    if (!obj.params.parameter) return;

    var [tobj,tparam] = obj.params.parameter.split("->");
    tobj = root.findByPath( tobj );
    if (!tobj) return;

    var value = tobj.getParam( tparam );
    if (!isFinite(value)) value = obj.params.min;

    var nv = value + parseFloat( obj.params.step );

    if (nv > obj.params.max) {
       obj.setParam("cycle", (obj.params.cycle || 0) + 1);
       if (obj.params.cycle == 1) obj.emit("first-cycle-finish");
       nv = obj.params.min;
    }   
    if (nv < obj.params.min) {
       obj.setParam("cycle", (obj.params.cycle || 0) + 1);
       if (obj.params.cycle == 1) obj.emit("first-cycle-finish");
       nv = obj.params.max;
    }

    if (need_restart) { 
        need_restart=false; 
        nv = obj.params.min; 
        obj.setParam("cycle",0);
    };

    itsme_c = true;
    let diff = (obj.params.max - obj.params.min);
    if (Math.abs(diff) > 0.000001)
      obj.setParam("progress", 100 * (nv-obj.params.min) / diff );
    itsme_c = false;

    tobj.setParam( tparam, nv );

    obj.emit("tick");
 }

  obj.on("remove",() => {
    obj.setParam("playing",false);
  })
}
