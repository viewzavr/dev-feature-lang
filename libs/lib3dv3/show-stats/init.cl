// dom-узлы для отображения fps и статистики рендеринга threejs

feature 'show_render_fps'
{
  d: dom style='position'
     Stats=(import_js (resolve_url '../three.js/examples/jsm/libs/stats.module.js'))
  {{
    @d->renderer? | get-cell "frame" | c-on "(evtargs,s) => s ? s.update() : null" @stats;
    let stats=(m_eval "(Stats) => Stats.default()" @d->Stats);
    read @stats | m_eval "(s,dom) => dom.appendChild(s.dom)" @d->dom;
    read @stats | m_eval "(s) =>  s.dom.style.position='' ";
  }}
};

feature 'show_render_stats'
{
  d: dom style='position'
     Stats=(import_js (resolve_url './rendererstats.js'))
  {{
    @d->renderer? | get-cell "frame" | c-on "(evtargs,s) => {
      let renderer = evtargs[0];
      return s ? s.update( renderer ) : null
    }" @stats;
    let stats=(m_eval "(Stats) => Stats.default()" @d->Stats);
    read @stats | m_eval "(s,dom) => dom.appendChild(s.domElement)" @d->dom;
    //@stats | m_eval "(s) =>  s.domElement.style.position='' ";
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