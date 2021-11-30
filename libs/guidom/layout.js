// предназначение - раскладка по горизонтали вертикали
// https://css-tricks.com/snippets/css/a-guide-to-flexbox/

//import * as D from "./dom.js";

export function setup( vz, m ) {
  vz.register_feature_set( m );
//  D.setup( vz, D );
}

export function column( env, opts ) {
  env.feature( "layout" );
  env.setParam( "flow","column" );
}

export function row( env, opts ) {
  env.feature( "layout" );
  env.setParam( "flow","row" );
}

export function layout( obj, opts )
{
  obj.feature( "dom" );

  var dom;
  var flextype = 'inline-flex'; // flex

  obj.onvalue("dom",() => {
    dom = obj.dom;
    if (!obj.dom)
        debugger;
    dom.style.display=flextype; 
    /* вроде как стало не надо - dom триггерит всех
    obj.signalParam( "flow" );
    obj.signalParam( "justify-content" );
    obj.signalParam( "align-items" );
    obj.signalParam( "align-content" );
    obj.signalParam( "gap" );
    obj.signalParam( "visible" );
    */
  

    obj.addComboValue( "flow","row",["row","column","row wrap","column wrap"],(v) => {
      if (!dom)
          debugger;
        if (!dom.style)
          debugger;
      dom.style.flexFlow = v; //v.replace("_"," ");
    });

    /*
    obj.addComboValue( "direction","row",["row","column"],(v) => {
      dom.style.flexDirection = v;
    });

    obj.addComboValue( "wrap","nowrap",["nowrap","wrap"],(v) => {
      dom.style.flexWrap = v;
    });
    */

    obj.addComboValue( "justify-content","flex-start",["flex-start","flex-end","center","space-between","space-around","space-evenly"],(v) => {
      dom.style.justifyContent = v;
    });

    obj.addComboValue( "align-items","stretch",["stretch","flex-start","flex-end","center","baseline"],(v) => {
      dom.style.alignItems = v;
    });

    obj.addComboValue( "align-content","normal",["normal","flex-start","flex-end","center","space-between","space-around","space-evenly","stretch"],(v) => {
      dom.style.alignContent = v;
    });

    //obj.addSlider("gap",0,0,50,1,(v) => {
    obj.addString("gap","0em",(v) => {
      // https://developer.mozilla.org/ru/docs/Web/CSS/gap;
      dom.style.gap = v;
    });

    // стандартный метод про hidden не катит
    obj.trackParam("visible",() => {
      dom.style.display = (obj.params.visible ? flextype : "none");
    })

  });

  obj.addLabel( "flexbox-help","<a href='https://css-tricks.com/snippets/css/a-guide-to-flexbox/' target=_blank>Flexbox docs</a>");

  return obj;
}

/*
export function setup( vz ) {

  vz.addItemType( "guilayout","GUI: layout", function( opts ) {
    return create( vz, opts );
  }, {guiAddItems: true, guiAddItemsCrit: "gui"} );

  vz.addItemType( "column","GUI: column", function( opts ) {
    var obj = create( vz, {name:"column",...opts} );
    obj.setParam("flow","column");
    return obj;
  }, {guiAddItems: true, guiAddItemsCrit: "gui"} );

  vz.addItemType( "row","GUI: row", function( opts ) {
    var obj = create( vz, {name:"row",...opts} );
    obj.setParam("flow","row");
    return obj;
  }, {guiAddItems: true, guiAddItemsCrit: "gui"} );

}*/