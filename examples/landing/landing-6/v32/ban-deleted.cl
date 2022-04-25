/*
  Проблема. Сцена описана программно scene { a;b;c; } и затем пользователь это в гуи удалил.
  значит надо при восстановлении сцены из дампа чтобы это тоже было удалено

  Решение: в дампе родителя запоминаем ключи детей, созданных программно и удаленных пользователем
  затем при восстановлении дампа - удаляем этих детей.
*/

debugger;

append_feature "datavis" "mark_deleted_children";
append_feature "staticvis" "mark_deleted_children";
append_feature "textvis" "mark_deleted_children";

feature "mark_deleted_children" code=`
  env.on("remove",() => {
    //console.log("uu",env,env.ismanual(),env.removedManually)
    if (!env.ismanual() && env.removedManually) { // removedManually - такой вот дебилизм
       // идея с массивом плоха тем что там начинается дублирование
       //let cur = env.ns.parent.params.banned_children || [];
       //cur.push( env.ns.name );
       //env.ns.parent.setParam( "banned_children", cur, true );
       //console.log('i see removing',env)
       
       let cur = env.ns.parent.params.banned_children || {};
       cur[ env.ns.name ] = true;
       env.ns.parent.setParam( "banned_children", cur, true );

       console.log("child", env.getPath(),"is marked as banned in",env.ns.parent);
       
       /*
       env.ns.parent.$banned_prg_children ||= {};
       env.ns.parent.$banned_prg_children[ env.ns.name ] = true;
       */
    }
  })
`;


append_feature "render3d" "skip_deleted_children";

// добавляет поведение в объект - удалять детей которые были добавлены программно и затем удалены пользователем вручную
// эту штуку можно вручную не навешивать а автоматически если что
feature "skip_deleted_children" code=`
   
   // типа это сработает при восстановлении из дампа
   env.onvalue("banned_children",(bc) => {
      //console.log('iterating',bc)
      for (let b of Object.keys(bc)) {
        let c = env.ns.getChildByName( b );
        if (c) {
          c.remove();
          //console.log("removed child ",c.getPath())
        }  
      }
   })

/*
   let orig = env.restoreFromDump;
   // хочу сказать что вроде как on проще воспринимается, почему-то.
   env.chain( "restoreFromDump",function (dump, manualParamsMode) {
     console.log("FFFF restoring",dump);

     return this.orig( dump, manualParamsMode );
   });
*/   
`;


/*
feature "datavis_remeber_deleted" {
  root: 
  {{ onremove code="{
       let obj = env.host;
       console.log('i see removing',env.host)
       if (!obj.ismanual()) {
             obj.ns.parent
       }
     }";
  }}
};
*/

/* todo разобраться чего оно не работает
append_feature "datavis" "datavis_remeber_deleted";
feature "datavis_remeber_deleted" {
  root: 
  {{ on "remove" {
      lambda @root code="(obj) => {
          //console.log('i see removing',obj)

        }";
     }

  }}
};
*/

//console_log 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB';
