export function setup(vz, m) {
  vz.register_feature_set( m );

}

// устанавливает параметры целевому объекту
// пока для упрощения только хост

export function set_params( env )
{
   env.host.feature("param_subchannels");

   let channel = env.host.create_subchannel();

   env.on('param_changed',(name,value) => {
      channel.setParam( name, value );
   });

   env.on("remove", () => channel.remove() );
}

// отличается от setter тем что сразу же делает
// по сути это то же самое что compute.. только на вход не код а value..
export function param_subchannels(env) 
{
  env.create_subchannel = () => {
    let res = { params: {} };
    env.$subchannels ||= [];
    env.$subchannels.push( res );

    // m.addTreeToObj(obj, "ns");
    res.remove = () => {
       let i = env.$subchannels.indexOf( res );
       if (i >= 0)
           env.$subchannels.splice( i, 1 );
       env.update_params_from_subchannels();  
    }

    res.setParam = (name,value, ...args) => {
      res.params[name] = value;
      orig_setParam( name,value, ...args );
    }

    return res;
  }

  // тупо едем по всем и выставляем, сообразно кто удалился - больше не установит
  env.update_params_from_subchannels = () => {
     for (let c of env.$subchannels) {
        for (let q of Object.keys(c.params)) {
           orig_setParam( q, c.params[q] ); // тут правда manual собъется мб, ну ладно пока
        }
     }
  };

  let channel0 = env.create_subchannel();
  channel0.params = {...env.params}; // запомним то что было 

  // теперь будем заменять стандартное setParams на новое
  let orig_setParam = env.setParam;
  env.setParam = channel0.setParam;
}