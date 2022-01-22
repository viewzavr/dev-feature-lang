
/// организует массив записей о фичах

register_feature name="visual-feature" {};

register_feature name="visual-features" code=`
  env.feature('delayed');
  // мечта: var d = vz.get('delayed'); или что-то типа..
  // но это статическая загрузка модулей.. можно будет типа reg-feature imports={d:delayed,...}
  // ну или еще как
  var dp = env.delayed(process);

  env.on("childrenChanged",dp);

  let unsubs = [];
  function clear_unsubs() { unsubs.forEach( q => q() ); unsubs = []; }

  function process() {
    clear_unsubs();
    let my = [];
    for (let c of env.ns.getChildren()) {
      let unsub = c.trackParam('output',(oo) => {
        // кстати вот было бы прикольно тут логи добавлять..
        // чтобы как бы объекты писали в воздухе..
        //console.log("gather-features child va changed")
        //debugger;
        dp();
      });
      unsubs.push(unsub);
      //if (!c.is_feature_applied("dbg-3d-feature")) continue;
      if (c.params.output && Array.isArray(c.params.output))
          my = my.concat(c.params.output); // ладно уж пущай массив сразу, тогда flat не надо
      else {
        if (c.params.title && c.params.body)
          my.push( c ); // просто запись, без всякого output...
      }    
          //my.push( c.params.output ); // вот в этот момент gather-features стала у нас рекурсивной
    }
    //my = my.flat(10);
    
    env.setParam("output",my);
  }
  process();
  
  // env.vz.importAsParametrizedFeature( { type: "dbg", params { }})
  // вот как бы нам добавить такое
  //env.$dbg_info = {radius: 30};
  /*
  env.on('dbg-add',(opts) => {
     opts.radius=130;
  } );
  */
`;