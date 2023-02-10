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

  obj.onvalue("dom",(dom) => {
    //dom.style.display=flextype; 
    //obj.setup_style( 'display',`display:${flextype}`);
    // далее см visible
    
    obj.addComboValue( "flow","row",["row","column","row wrap","column wrap"],(v) => {
      obj.setup_style( 'flex-flow',`flex-flow:${v}`);
    });

    obj.addComboValue( "justify-content","flex-start",["flex-start","flex-end","center","space-between","space-around","space-evenly"],(v) => {
      obj.setup_style( 'justify-content',`justify-content:${v}`);
    });

    obj.addComboValue( "align-items","stretch",["stretch","flex-start","flex-end","center","baseline"],(v) => {
      obj.setup_style( 'align-items',`align-items:${v}`);
    });

    obj.addComboValue( "align-content","normal",["normal","flex-start","flex-end","center","space-between","space-around","space-evenly","stretch"],(v) => {
      obj.setup_style( 'align-content',`align-content:${v}`);
    });

    //obj.addSlider("gap",0,0,50,1,(v) => {
    obj.addString("gap","0em",(v) => {
      // https://developer.mozilla.org/ru/docs/Web/CSS/gap;
      obj.setup_style( 'gap',`gap:${v}`);
    });

    // стандартный метод про hidden не катит
    obj.monitor_defined(["visible"],() => {
      //dom.style.display = (obj.params.visible ? flextype : "none");
      obj.setup_style( 'display',`display:${obj.params.visible ? flextype : "none"}`);
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