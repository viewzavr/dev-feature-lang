export function setup(vz, m) {
  vz.register_feature_set( m );
}

// история такая что мы
// 1 хотим использовать нашу либу dom ибо там много сделано
// 2 но должны использовать createElementNS чтобы создавать узлы svgs
// https://stackoverflow.com/questions/3492322/javascript-createelementns-and-svg
// поэтому вот:

export function svg( env ) {
  let f = function(tag) {
    let ee = document.createElementNS("http://www.w3.org/2000/svg",tag);

/*  вроде как решил что неуместно это здесь - пусть пока там будет где надо кому ыыы
    // F-NEED-EXPLICIT-XMLNS-IN-SVG-TAG
    if (tag == "svg") {
      ee.setAttribute("xmlns","http://www.w3.org/2000/svg");
      //xmlns="http://www.w3.org/2000/svg" 
    }
*/    
    return ee;
  }
  if (!env.params.tag) env.setParam("tag","svg");

  env.feature("dom", {elem_creator_f: f});

  // в свг dom.hidden не катит (которое юзается в dom)
  // и поэтому вот такое поведение добавляем
  env.trackParam("visible",(v) => {
    //debugger;
    if (env.dom)
      env.dom.setAttribute("visibility", v ? 'visible' : 'hidden' );
      //env.dom.visibility = v ? 'visible' : 'hidden';
  })
}