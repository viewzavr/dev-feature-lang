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
    return document.createElementNS("http://www.w3.org/2000/svg",tag);
  }
  if (!env.params.tag) env.setParam("tag","svg");

  env.feature("dom", {elem_creator_f: f});
}