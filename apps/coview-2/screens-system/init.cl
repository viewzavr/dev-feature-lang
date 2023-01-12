load "view-tab-recursive.cl"

/* здесь терминология не слои а source - вроде так лучше.
*/

// подфункция реакции на чекбокс view_settings_dialog
// идея вынести это в метод вьюшки. типа вкл-выкл процесс.
// ВАЖНО: все пути здесь считаются относительно проекта
feature "toggle_view_source_assoc" {
    x: object output={: view=@x.view source=@x.source val | // cobj объект чекбокса, val значение

    //let view = env.params.view; // вид the_view

    view.params.sources ||= [];
    view.params.sources_str ||= '';
    if (val) { // надо включить
      let curind = view.params.sources.indexOf( source );
      if (curind < 0) {
        let add = '@' + source.getPathRelative( view.params.project );
        //console.log('adding',add);
        let filtered = view.params.sources_str.split(',').filter( (v) => v.length>0)
        let nv = filtered.concat([add]).join(',');
        //console.log('nv',nv)
        
        view.setParam( 'sources_str', nv, true);

      }
      // видимо придется как-то к кодам каким-то прибегнуть..
      // или к порядковым номерам, или к путям.. (массив objref тут так-то)
    }
    else
    {
        // надо выключить
      let curind = view.params.sources.indexOf( source );
      //debugger;
      if (curind >= 0) {
        //obj.params.sources.splice( curind,1 );
        //obj.signalParam( 'sources' );
        let arr = view.params.sources_str.split(',').map( x => x.trim());
        arr = [...new Set(arr)]; // унекальнозть
        let p = '@' + source.getPathRelative( view.params.project );
        let curind_in_str = arr.indexOf(p);
        if (curind_in_str >= 0) {
          arr.splice( curind_in_str,1 );
          view.setParam( 'sources_str', arr.join(','), true)
        };

        source.emit('view-detached',view);
      }
    };
   :}
}