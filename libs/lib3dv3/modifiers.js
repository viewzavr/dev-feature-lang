import * as THREE from './three.js/build/three.module.js';
import * as utils from "./utils.js";

export function setup(vz, m) {
  vz.register_feature_set( m );
}

///////////////////// модификатор scale3d
// кстати а вот где - отмена?.. и как ее сделать?.. тут даже канальцев нет...
export function scale3d( env ) {
   //env.host.value
   // идея - групповая ловушка параметров из разных объектов
   // unsub = vz.onvalue( [ [env.host,"output"], [env,"scale"], (o,s) => {})
   // и еще можно как-то текущий env добавить в аргументы и тогда отписываться при remove

   let unsub = () => {};
   let unsub1 = () => {};
   unsub1 = env.host.onvalue("output",(threejsobj) => {
     unsub();
     unsub = env.onvalue( "coef",(coef) => {
       threejsobj.scale.set( coef,coef,coef );
     }); 
   })

   env.on("remove",() => { unsub1(); unsub(); } );
   
   // кстати тут вопросов много.. дейсвительно, может быть выгодно действовать сразу на многих
   // (аля compose) @compose
   // и потом - вот мы можем добавить управление через какой-то подкласс из иерархии 3д бибилотеки
   // но вроде интересно - отдельной фичей.. 

   env.addSlider("coef",1,0,10,0.0001);
}

///////////////////// модификатор pos3d
// кстати а вот где - отмена?.. и как ее сделать?.. тут даже канальцев нет...
export function pos3d( env ) {
   
   let unsub = () => {};
   let unsub1 = () => {};
   let unsub2 = () => {};
   unsub = env.host.onvalue("output",(threejsobj) => {
     unsub1();
     unsub1 = env.onvalues_any( ["x","y","z"],(x,y,z) => {
       if (isFinite(x)) threejsobj.position.x=x;
       if (isFinite(y)) threejsobj.position.y=y;
       if (isFinite(z)) threejsobj.position.z=z;
     });

     // ну вот еще слой управления через такое
     unsub2();
     unsub2 = env.onvalue( "pos",(v) => {
       if (v) {
         if (isFinite(v[0])) threejsobj.position.x=v[0];
         if (isFinite(v[1])) threejsobj.position.y=v[1];
         if (isFinite(v[2])) threejsobj.position.z=v[2];
       }
     });
   });

   env.on("remove",() => { unsub1(); unsub2(); unsub(); } );
   
   env.addFloat("x",0);
   env.addFloat("y",0);
   env.addFloat("z",0);
}

///////////////////// модификатор rotate3d
// вход angles - в радианах
// идея - сделать в углах, и мб по отдельности.. а может быть разные модификаторы - проще будет..
// rotate3d_grad,
// rotate3d_grad_x, rotate3d_grad_y, rotate3d_grad_z... хотя может это и лишнее

export function rotate3d_angles( env ) {
   //env.host.value
   // идея - групповая ловушка параметров из разных объектов
   // unsub = vz.onvalue( [ [env.host,"output"], [env,"scale"], (o,s) => {})
   // и еще можно как-то текущий env добавить в аргументы и тогда отписываться при remove
   // типа unsub = env.monitor_values( [ [env.host,"output"], [env,"scale"]], (o,s) => { } )

   let unsub = () => {};
   let unsub1 = () => {};
   unsub1 = env.host.onvalue("output",(threejsobj) => {
     unsub();
     unsub = env.onvalue( "angles",(angles) => {
       if (!angles) return;
       if (!Array.isArray(angles)) return;
       if (angles.length < 3) return;

       threejsobj.rotation.set( angles[0],angles[1],angles[2] );
     });
   });

   env.on("remove",() => { unsub1(); unsub(); } );
   
   // кстати тут вопросов много.. дейсвительно, может быть выгодно действовать сразу на многих
   // (аля compose) @compose
   // и потом - вот мы можем добавить управление через какой-то подкласс из иерархии 3д бибилотеки
   // но вроде интересно - отдельной фичей.. 

}

export function rotate3d( env ) {
   //env.host.value
   // идея - групповая ловушка параметров из разных объектов
   // unsub = vz.onvalue( [ [env.host,"output"], [env,"scale"], (o,s) => {})
   // и еще можно как-то текущий env добавить в аргументы и тогда отписываться при remove

   let unsub = () => {};
   let unsub1 = () => {};
   unsub1 = env.host.onvalue("output",(threejsobj) => {
     unsub();
     unsub = env.onvalues_any( ["x","y","z"],(x,y,z) => {
       if (isFinite(x)) threejsobj.rotation.x=x;
       if (isFinite(y)) threejsobj.rotation.y=y;
       if (isFinite(z)) threejsobj.rotation.z=z;
     });
   });

   env.on("remove",() => { unsub1(); unsub(); } );
   
   // кстати тут вопросов много.. дейсвительно, может быть выгодно действовать сразу на многих
   // (аля compose) @compose
   // и потом - вот мы можем добавить управление через какой-то подкласс из иерархии 3д бибилотеки
   // но вроде интересно - отдельной фичей.. 
   env.addSlider("x",0,0,Math.PI*2,0.0001);
   env.addSlider("y",0,0,Math.PI*2,0.0001);
   env.addSlider("z",0,0,Math.PI*2,0.0001);
   // а классная идея получилась.. мы теперь можем рендерить их параметры..
}

export function color3d( env ) {

  //env.monitor_values( [env,"color", env.host, "material"])

  let unsub = () => {};
  let unsub1 = () => {};
   unsub1 = env.host.onvalue("material",(material) => {
     unsub();
     unsub = env.onvalue( "color",(v) => {
        material.color = utils.somethingToColor(v);
        material.needsUpdate = true; 
     });
   });

  env.on("remove",() => { unsub1(); unsub(); } ); 

  env.addColor("color", env.params.color );

} 