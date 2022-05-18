/*
  Проблема. Сцена описана программно scene { a;b;c; } и затем пользователь это в гуи удалил.
  значит надо при восстановлении сцены из дампа чтобы это тоже было удалено

  Решение: в дампе родителя запоминаем ключи детей, созданных программно и удаленных пользователем
  затем при восстановлении дампа - удаляем этих детей.
*/

// todo переписать на новые модификаторы

feature "mark_deleted_children" code=`
  env.on("remove",() => {
    //console.log("uu",env,env.ismanual(),env.removedManually)
    if (!env.ismanual() && env.removedManually) { // removedManually - такой вот дебилизм
       let cur = env.ns.parent.params.banned_children || {};
       cur[ env.ns.name ] = true;
       env.ns.parent.setParam( "banned_children", cur, true );
       //console.log("child", env.getPath(),"is marked as banned in",env.ns.parent);
    }
  })
`;

// добавляет поведение в объект - удалять детей которые были добавлены программно и затем удалены пользователем вручную
// эту штуку можно вручную не навешивать а автоматически если что
feature "skip_deleted_children" {

  x-patch code=`(tgt) => {
   
   console.log("*************************** skip_deleted_children init",tgt)
   // типа это сработает при восстановлении из дампа
   let q1 = tgt.onvalue("banned_children",(bc) => {
     // console.log('*************************** skip_deleted_children iterating',bc)
      for (let b of Object.keys(bc)) {
        let c = tgt.ns.getChildByName( b );
        if (c) {
          c.remove();
          //console.log("removed child ",c.getPath())
        }
      }
   })

   let q2 = tgt.on("appendChild",(c) => {
      c.feature("mark_deleted_children");
      // но это ток на непосредственных детей получается
   });

   //return () => { q1(); q2(); }

 }`;

};

