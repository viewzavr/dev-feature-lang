/*
  Проблема. Сцена описана программно scene { a;b;c; } и затем пользователь это в гуи удалил.
  значит надо при восстановлении сцены из дампа чтобы это тоже было удалено

  Решение: в дампе родителя запоминаем ключи детей, созданных программно и удаленных пользователем
  затем при восстановлении дампа - удаляем этих детей.
*/

append_feature "datavis" "mark_deleted_children";
append_feature "staticvis" "mark_deleted_children";
append_feature "textvis" "mark_deleted_children";
append_feature "render3d" "skip_deleted_children";

feature "mark_deleted_children" code=`
  env.on("remove",() => {
    //console.log("uu",env,env.ismanual(),env.removedManually)
    if (!env.ismanual() && env.removedManually) { // removedManually - такой вот дебилизм
       
       let cur = env.ns.parent.params.banned_children || {};
       cur[ env.ns.name ] = true;
       env.ns.parent.setParam( "banned_children", cur, true );

       console.log("child", env.getPath(),"is marked as banned in",env.ns.parent);
    }
  })
`;

// добавляет поведение в объект - 
// удалять детей которые были добавлены программно и затем удалены пользователем вручную
// эту штуку можно вручную не навешивать а автоматически если что
feature "skip_deleted_children" code=`

   let orig = env.restoreChildrenFromDump;
   env.restoreChildrenFromDump = (dump, ismanual) => {
      console.log("******* voe22", dump, env)
      for (let n of Object.keys(env.params.banned_children || {})) {
         console.log( "child is not restoring",n)
         delete dump.children[n];
      }
      return orig( dump, ismanual );
   };
`;

