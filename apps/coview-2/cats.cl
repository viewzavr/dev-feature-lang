load "gui-system/init.cl"
// непонятно почему это здесь
load "lib/init.cl"
load "plugins/init.cl"

// Конкретные категории

coview-category title="Загрузка" id="data"
coview-category title="Программы" id="process"
coview-category title="Графика" id="gr3d" 
coview-category title="Надписи" id="gr2d"

coview-category title="Слои" id="layer"
coview-category title="Экраны" id="screen"
coview-category title="Плагины" id="plugin"

coview-record title="Загрузчик файлов" type="cv-select-files" cat_id="data"

//////////////////
coview-record title="Тест: Генератор сфер" type="test-process" cat_id="process"

feature "test-process" {
    p: visual_process count=10 title="Генератор сфер" {
      gui {
        gui-tab "main" {
          //m: slider
          gui-slot @p "count" gui={ |in out| gui-slider @in @out }
          //gui-slot @p "radius" gui={ |in out| gui-slider @in @out }
        }
      }
      // идея - разные распределения потестить. ну и тогда надо точки а не сферы

      mydf: df_create // пока оно так не умеет ~layer_object
          X=(create-array @p.count | arr_map {: r=10 | return Math.random()*r :} )
          Y=(create-array @p.count | arr_map {: r=10 | return Math.random()*r :} )
          Z=(create-array @p.count | arr_map {: r=10 | return Math.random()*r :} )
      //console-log "@mydf.output=" @mydf.output "cnt=" @p.count

      pts: cv_spheres input=@mydf.output
      //pts: cv_spheres input=(df_create X=[0,1,2] Y=[1,1,5] Z=[1,0,1])
      //pts: cv_spheres input=(df positions=[1,2,3, 5,5,2 ]
    }  
}

//////

// кстати мб было бы проще - если бы id леера совпадало с некоей фичей объектов.. тогда было бы проще искать.. ну ладно..

// это наша стартовая сущность которую пользователь добавляет в проект
// а data-artefact это уже взгляд на нее. (ну как бы..)

// включевое поле output это массив вида [ {name,url}, {name,url}, fileobject, ... ]

feature "cv-select-files" {
  qqe: layer_object
    title="Загрузка файлов"
    initial_mode=1
    url=""
    list_url=""
    files=[]
    {{ x-param-string name="url" }}
    {{ x-param-string name="list_url" }}
    {{ x-param-files  name="files" }}
    {{ x-param-switch name="src" values=["URL","Файл с диска","Папка list.txt","Папка с диска"] }}
    src=0
    output=(m_eval {: src=@qqe->src a=@qqe->url b=@qqe->files c=(@load_list_txt->output or []) |
      
      if (src == 0) {
        if (a) {
           let sp = a.split('/');
           if (sp.at(-1) == '') sp.pop();
           return [{name:sp.at(-1),url:a}];
        }
        return [];
      }
      if (src == 1)
        return b;
      if (src == 2)  
        return c
      return []
      :})
    first_file =@qqe.output.0

    gui={ paint-gui @qqe }
    gui1={
      column ~plashka {

        render-params-list object=@qqe list=["title"];

        param_field name="Источник" {

          column {
            render-params-list object=@qqe list=["src"];

            show-one index=@qqe->src style="padding:0.3em;" {
              column { render-params-list object=@qqe list=["url"];; };
              column { render-params-list object=@qqe list=["files"];; };
              column { render-params-list object=@qqe list=["list_url"];; };
              column { files; };
            };

            //text @qqe->output
          };
        };

      };
    }
    {
      load_list_txt: if (@qqe->src == 2) { load-list-txt file=@qqe->list_url }
      //let load_list_txt=(if (@qqe->src == 2) { load-list-txt file=@list_url })


      gui { // на будущее
        gui-tab "main" {
          render-params-list object=@qqe list=["title"];

          param_field name="Источник" {

          column {
            render-params-list object=@qqe list=["src"];

            show-one index=@qqe->src style="padding:0.3em;" {
              column { render-params-list object=@qqe list=["url"] }
              column { render-params-list object=@qqe list=["files"] }
              column { render-params-list object=@qqe list=["list_url"] }
              column { files }
            }

            //text @qqe->output
          }
          };
        } // main
        gui-tab "status" {
          gui-slot @qqe "first_file" gui={ |in out| gui-label @in @out }
          gui-slot @qqe "output" gui={ text ("N of files: " + @qqe.output.length) }
        }
        /*
        gui-tab {
          gui-switch @qqe "src" values=["URL","Файл с диска","Папка"]
          column {
            if (@qqe.src == 0) {
              gui-url @qqe "url"
            }
            if (@qqe.src == 1) {
              gui-files @qqe "files"
            }
            if (@qqe.src == 2) {  
              gui-dir @qqe "dir"
            }
          }
        }
        */
      }

      param-info "output" out=true
      param-info "first_file" out=true
    }
    //url="http://127.0.0.1:8080/vrungel/public_local/Kalima/v2/vtk_8_20/list.txt"
    //url="https://viewlang.ru/assets/lava/Etna/list.txt"
    //url=""
};

// загрузка списка файлов из файла типа list.txt
// в этом файле построчно перечисляются имена или пути к файлам
feature "load-list-txt" {
  x: object output=@result
   {
    let listing_file_url=@x->file;
    let listing = (load-file file=@listing_file_url
                   | m_eval "(txt) => txt && txt.length > 0 ? txt.split('\\n') : []" @.->input);
    let listing_file_dir = (m_eval "(str) => str.split ? str.split('/').slice(0,-1).join('/') : '/invalid-input-url'" @listing_file_url);
    console-log "listing_file_dir=" @listing_file_dir "listing_file_url=" @listing_file_url
    let listing_resolved = (@listing | map_geta (m_apply "(dir,item) => dir+'/'+item" @listing_file_dir));
    let result = (m_eval "(arr1,arr2) => {
                  if (arr1.length != arr2.length) return;
                  let res = arr1.map( (elem,index) => {
                    return {name: elem, url: arr2[index]};
                  });
                  res.art_file_list = true;
                  return res;
                }
                " @listing @listing_resolved);
  };
};


/////////////////////////// Искалка файлов имени Миши

// по входному массиву и критерию (regexp) - находит файл 1 штучку, удовлетворяющий критерию.
// [list of files...] | find-file ".+\.txt$"
feature "find-file" {
  r: object output=@mm->output {

  //reaction (event @r "found")     (param @r "output")
  //reaction (event @r "not-found") (param @r "output")
  // todo вопрос а как бы так делать красиво, что "при сигнале not-found" "положить в канал output значение такое-то (другое чем в канале событий)"
  /* появилась мысль сделать пайпу. те.. reaction a b c d соединяет всех в пайпу.
  если событие в a то передает в b если в b то передает в c и т.д.
  если что-то из этого есть функция (а не канал) то вызывается функция а ее результат передается дальше
  вопрос что все это значит. особенно если первый аргумент есть функция.
  (если первый аргумент был бы "вычислением" то понятно в принципе - вычисляй и посылай результаты по цепочке...
   но у нас нет такого пока вроде сходу понятия, вычисление)
  */
        
  mm: m_eval {: arr=@r.input crit=@r.0 obj=@r |
        if (!arr) return null;
        if (!Array.isArray(arr)) arr=[arr];
        let regexp = new RegExp( crit,'i' );
        let file = arr.find( elem => elem?.name?.match( regexp ) );
        if (!file) {
          obj.emit('not-found');
          return null;
        }
        obj.emit('found',file);
        return file;
   :}   
  }
}


///////////////

coview-record title="Прочитать файл" type="load-text" cat_id="data"

feature "load-text" {
  x: layer_object
  title="Прочитать файл"
  output=(load-file @x.input?)
  gui={ paint-gui @x }
  
  {
    gui {
      gui-tab "main" {
        gui-slot @x "input" gui={ |in out|
          text "value="
          text (read @in | get-value)
        }
        gui-slot @x "output" gui={ |in out| gui-text @in @out }
      }
    }

    param-info "input" in=true out=true
    param-info "output" out=true
  }
}

/////////////////////
coview-record title="Сферы" type="cv_spheres" cat_id="gr3d"

// вопрос как передать addons в меш..
feature "cv_spheres" {
  vp: visual-process
   title="Сферы"
   gui={ paint-gui @vp }
   ~spheres 
   {
    param-info "input" in=true out=true // df-ка

    //console-log "vvv" @vp.input

    gui debug=true {
      //kkk: console-log "hi from spheres" @kkk
      gui-tab "main" {
        gui-slot @vp "input" gui={ |in out| gui-df @in @out;
           //me: console-log "invalue=" (read @in | get-value) "in=" @in me=@me; 
           //link from="@in->." to="@k->1" debug=true
           //k: object
         }
      }
      
      gui-tab "mesh" {
        paint-gui @vp.mesh show_common=false
      } 
      /*
      render-params @vp
             filters={ params-hide list="title"; };
       render-params @vp->mesh
             filters={ params-hide list="visible"; };
      }*/
      
    }
  }
}

/////////////////////
coview-record title="Цилиндры" type="cv_cylinders" cat_id="gr3d"

// вопрос как передать addons в меш..
feature "cv_cylinders" {
  vp: visual-process
   title="Цилиндры"
   gui={ paint-gui @vp }
   ~cylinders
   {
    param-info "input" in=true out=true // df-ка

    //console-log "vvv" @vp.input

    gui debug=true {
      //kkk: console-log "hi from spheres" @kkk
      gui-tab "main" {
        gui-slot @vp "input" gui={ |in out| gui-df @in @out;
           //me: console-log "invalue=" (read @in | get-value) "in=" @in me=@me; 
           //link from="@in->." to="@k->1" debug=true
           //k: object
         }
      }
      
      gui-tab "mesh" {
        paint-gui @vp.mesh show_common=false
      } 
      /*
      render-params @vp
             filters={ params-hide list="title"; };
       render-params @vp->mesh
             filters={ params-hide list="visible"; };
      }*/
      
    }
  }
}


/////////////////////
coview-record title="Точки" type="cv_points" cat_id="gr3d"

// вопрос как передать addons в меш..
feature "cv_points" {
  vp: visual-process
   title="Точки"
   gui={ paint-gui @vp }
   ~points 
   {
    param-info "input" in=true out=true // df-ка
    param-info "positions" in=true out=true // df-ка
    param-info "colors" in=true out=true // df-ка

    gui debug=true {
      gui-tab "main" {
        gui-slot @vp "input" gui={ |in out| gui-df @in @out }
      }

      gui-tab "positions" {
        gui-slot @vp "positions" gui={ |in out| gui-array @in @out }
        gui-slot @vp "colors" gui={ |in out| gui-array @in @out }
      }
      
      gui-tab "view" {
        render-params @vp
           filters={ params-hide list="title"; }
      }

    }
  }
}

///////////////////// меш
coview-record title="Тримеш" type="cv_mesh" cat_id="gr3d"

// вопрос как передать addons в меш..
feature "cv_mesh" {
  vp: visual-process
   title="Тримеш"
   gui={ paint-gui @vp }
   ~mesh 
   {
    param-info "input" in=true out=true // df-ка
    param-info "positions" in=true out=true // df-ка
    param-info "colors" in=true out=true // df-ка

    gui debug=true {
      gui-tab "main" {
        gui-slot @vp "input" gui={ |in out| gui-df @in @out }
      }

      gui-tab "positions" {
        gui-slot @vp "positions" gui={ |in out| gui-array @in @out }
        gui-slot @vp "colors" gui={ |in out| gui-array @in @out }
      }
      
      gui-tab "view" {
        render-params @vp
           filters={ params-hide list="title"; }
      }

    }
  }
}

///////////////////// меш
coview-record title="Поиск пересечений по клику" type="cv_intersect_mouse" cat_id="process"

feature "cv_intersect_mouse" {
  x: process
    title="Поиск пересечений по клику"
    ~have-scene-env
    convert_fn = {: event domElement | return {
            x: (event.clientX / domElement.clientWidth) * 2 - 1,
            y: -(event.clientY / domElement.clientHeight) * 2 + 1,
        } :}
    scene_env = { |show_3d_scene_r opacity| 

       let cam = @show_3d_scene_r.camera
       let scene_items = @show_3d_scene_r.scene3d
       let THREE=(import_js (resolve_url "../../../libs/lib3dv3/three.js/build/three.module.js"))

       reaction (dom-event-cell @show_3d_scene_r "click") {: event convert_fn=@x.convert_fn THREE=@THREE threejs_camera=@cam.output scene_items=@scene_items domElement=@show_3d_scene_r.dom x=@x |

        let raycaster = new THREE.Raycaster()
        let mouse = convert_fn( event, domElement )
        raycaster.setFromCamera(mouse, threejs_camera)

        const intersects = raycaster.intersectObjects( scene_items, true )

        //console.log( "intersects=",intersects)

        x.setParam("output",intersects)

        if (intersects.length > 0) {
          let pt = intersects[0].point
          let coord_arr = [ pt.x, pt.y, pt.z ]  
          x.setParam("successful_coords", coord_arr )
          //x.setParam("successful_coords", coord_arr ) 
          x.emit("successful_coords_event", coord_arr ) // что тоже интересно
        }

        //console.log( "click", event_data, threejs_camera,scene_items,dom)
       :}
    }
    {
      param-info "output" out=true
      param-info "successful_coords" out=true
      param-info "successful_coords_event" out=true
      gui {
        gui-tab "main" {
          gui-slot @x "successful_coords" gui={ |in out| gui-vector @in @out }
        }
      }

    }
}
/* вот образец - люблю делать "готовое удобное"
   а по факту это 2 вещи слеплены. ловилка кликов по поверхности ареа. и - реакция на это в форме вот указанной.
*/

coview-record title="Поиск пересечений центра" type="cv_intersect_center" cat_id="process"

feature "cv_intersect_center" {
  x: cv-intersect-mouse
    title="Поиск пересечений центра"
    convert_fn = {: event domElement | return { x: 0, y: 0 } :}
}