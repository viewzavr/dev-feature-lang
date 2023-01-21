import * as THREE from './three.js/build/three.module.js';
//import { FontLoader }   from './three.js/examples/jsm/loaders/FontLoader.js';
//import { TextGeometry } from './three.js/examples/jsm/geometries/TextGeometry.js';
import * as utils from "./utils.js";

export function setup(vz, m) {
  vz.register_feature_set( m );
}

export function text_sprite_one( env ) {

      let canvas1 = document.createElement('canvas');
      let context1 = canvas1.getContext('2d');
      let textureSize = [256,256]
      canvas1.width = textureSize[0]
      canvas1.height = textureSize[1]      

      // canvas contents will be used for a texture
      let texture1 = new THREE.Texture(canvas1) 

      texture1.minFilter = THREE.LinearFilter;
      texture1.needsUpdate = true;

  // const map = new THREE.TextureLoader().load( 'sprite.png' );
  // и отсюда что мы можем делать любой спрайт рисователь, так-то. ну как изначально в three js ))))

  var material = new THREE.SpriteMaterial( { map:texture1,color: 0xffffff } ); // front , flatShading: true
  var material1 = new THREE.MeshPhongMaterial( { color: 0xffffff } );
  env.setParam("material",material)

  var threejs_item = new THREE.Sprite( material );
  env.setParam("output",threejs_item ); // я это сделал чтобы позицию понимаешь сохранять можно было..

  env.addSlider("size",10,0,256,1 );
  env.addString("text");

  env.on("remove",() => {
    material.dispose()
  })

  env.addColor("color",[1,1,1])
  env.addColor("fill_color") // вообще их в модификаторы надо бы угнать.. которые тут же и описать.. вопрос как их программно стелить - ну придумаем
  env.addColor("border_color") // и тогда emit("before-render",canvas) ТПУ но ток надо с приоритетами.. (сделать в каллбеках приоритеты) on(name,fn,priority или типа того - с каналами)

// кокое-то бы add-to-scope или типа того.. ну или import-js освоить
function componentToHex(c) {
    if (typeof(c) === 'undefined') {
      debugger;
    }
    var hex = c.toString(16);
    return hex.length == 1 ? "0" + hex : hex;
}
    
// r g b от 0 до 255
function rgbToHex(r, g, b) {
    return "#" + componentToHex(r) + componentToHex(g) + componentToHex(b);
}
    
// triarr массив из трех чисел 0..1
function tri2hex( triarr ) {
   return rgbToHex( Math.floor(triarr[0]*255),Math.floor(triarr[1]*255),Math.floor(triarr[2]*255) )
}

function color2css( triarr ) {
   if (typeof(triarr) === "string") return triarr;
   return tri2hex( triarr );
}

  env.addSlider("radius", 1, 1, 1000, 1)
  

  env.onvalues(["text","size","color","radius"],(txt,size,color,radius) => {
      txt = txt.toString(); // а то числы подают

      let textureSize = [256,256]
      let family = "Georgia"
      //let fontString = (bold ? "Bold " : "") + (italic ? "Italic " : "")  + pixelSize + "px " + family
      let pixelSize = size
      let fontString = pixelSize + "px " + family
      let opacity = 1
      let centered = true
      let texOffset = centered ? [-0.5, 0.5] : [0,0]
      //let texOffset = centered ? [-0.25, 0.25] : [0,0]
      

      canvas1.width = textureSize[0]
      canvas1.height = textureSize[1]

      context1.clearRect( 0,0,canvas1.width,canvas1.height );
      context1.font = fontString;

      var metrics = context1.measureText(txt);
      var width = metrics.width;
      var height = pixelSize;
      //var height = metrics.fontBoundingBoxAscent;
      //console.log("height=",height,metrics,pixelSize)

      //context1.fillStyle = color2css( [1,0,0] );
      //  context1.fillRect( 3,3, width+4+3,height );

      /* это очевидные фичи
      if (fillColor != null && fillColor != "") {
        context1.fillStyle = color2css( fillColor );
        context1.fillRect( 3,3, width+4+3,height+4 );
      }


        
      if (borderColor != null) {
        context1.strokeStyle = color2css( borderColor );
        context1.strokeRect( 2,2, width+8+1,height+6);
      }*/

      context1.fillStyle = color2css( color );
      context1.fillText( txt, 5+1, height - Math.sqrt( height*0.1 ) );
      // короче разобраться тут надо, что к чему

      let twidth = width + 3+1 +4+3 +1
      let theight = height+4
      texOffset = centered ? [-0.5 + (twidth/2)/256, 0.5 - (theight)/256] : [0,0]
      texture1.offset.set( texOffset[0], texOffset[1] ); 
      //console.log("rendered texture1",textureSize,txt,width,height)

      var r = radius;
      threejs_item.scale.set( r,r,r );

      //threejs_item.material.opacity = opacity;
      //this.sceneObject.material.transparent = opacity < 1;
      //threejs_item.material.transparent = true; // due to 112
      threejs_item.material.needsUpdate = true;

      material.needsUpdate = true;
      texture1.needsUpdate = true;      
  })

  env.onvalue("color",(v) => {
     material.color = utils.somethingToColor(v);
     material.needsUpdate = true;
  });

  env.feature("lib3d_visual");
  env.feature("node3d",{object3d: threejs_item});

  // todo потом эти все вещи про df вытащить в отдельный фиче-слой
  // и аппендом их добавлять
  //env.feature( "lines_df_input" );
}