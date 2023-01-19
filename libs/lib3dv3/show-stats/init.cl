// dom-узлы для отображения fps и статистики рендеринга threejs

feature 'show_render_fps'
{
  d: dom style='position'
     Stats=(import_js (resolve_url '../three.js/examples/jsm/libs/stats.module.js'))
  {{
    reaction (event @d->renderer "frame") {: renderer stats=@stats | stats.update() :}
    let stats=(m_eval "(Stats) => Stats.default()" @d->Stats);
    m-eval {: stats=@stats dom=@d.dom | stats.dom.style.position=''; dom.appendChild( stats.dom ); :}
  }}
};

feature 'show_render_stats'
{
  d: dom style='position'
     Stats=(import_js (resolve_url './rendererstats.js'))
  {{
    let stats=(m-eval {: Stats=@d.Stats | return Stats.default():})
    m-eval {: stats=@stats dom=@d.dom | dom.appendChild(stats.domElement) :}
    reaction (event @d->renderer "frame") {: renderer stats=@stats | stats.update( renderer ) :}
  }}
};

/*
// вариант на js

// надо фиче show_render_fps
import Stats from './three.js/examples/jsm/libs/stats.module.js';
// вход: renderer выход: dom-узел красивое
export function show_render_fps( env ) {
  env.feature("dom");
  const stats = Stats()
  stats.dom.style.position='';
  env.dom.appendChild( stats.dom );

  let unbind=()=>{};
  env.onvalue("renderer",(r) => {
    unbind();
    unbind=r.on('frame',() => {
       stats.update();
    })
  });
  env.on("remove",unbind)
};
*/