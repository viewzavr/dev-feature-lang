
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

coview-record title="Набор файлов" type="cv-select-files" cat_id="data"
coview-record title="Загрузка списка файлов" type="cv-list-txt" cat_id="data"

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

feature "cv-list-txt" {
  x: layer_object
       title="Загрузка списка файлов"
       files=(load-list-txt file=@x->list_url)
       list_url=""
       {
        gui {
          gui-tab "main" {
            gui-slot @x "list_url" gui={ |in out| gui-string @in @out}
          }
        }
        
       }
}

////// набор файлов

// выходное поле files это массив вида [ {name,url}, {name,url}, fileobject, ... ]
// идеи: list.txt (на этапе добавления? или всегда? - это сложно.. или отдельный тип?)
//       выгрузка локальных на сервер. хотя бы с простой авторизацией - уже можно там разместить что-то типа showtime.
//       кстати вот: сделать на диссертации.
// либо: для list-txt делаем подобъект, а эта штука пусть собирает files с себя и всех детей

feature "cv-select-files" {
  x: layer_object
    title="Набор файлов"
    files=(concat @x.own_files @x.child_files)
    own_files=[]
    child_files=(find-objects-bf root=@x "cv-list-txt" depth=1 
        | map_geta "files" | arr_concat )
    {
      gui {
       gui-tab "files" (m-eval {: files=@x.files | return `Файлы: ${files.length}`:}) {
         addbtn: button "Добавить файлы" class="important_button"

              cb: combobox dom_attr_size=(m-eval {: vals=@cb.values | return Math.min( 10, 2+vals.length ):})
                    values=( @x.files | map_geta {: f | return f?.name || f :} )
              row gap = "0.1em" {      
                r1: button "Удалить выбранный"
                r: button "Удалить все"
              }

            reaction @r1.click {: files=(param @x "own_files" manual=true) cbindex=@cb.output_index? |
               let arr  = (files.get() || [])
               if (cbindex >= 0)
                   arr.splice( cbindex, 1)
               files.set( [...arr] ) 
            :}
            reaction @r.click {: files=(param @x "own_files" manual=true) | files.set( [] ) :}
            reaction @addbtn.click (method @dlg "show")

       }
      } 

      // могут прислать снаружи
      reaction (event @x "add_new") (method @dlg "show")

      //cre: creator input={cv-list-txt | dump_to_manual) target=@x
      // %pain креатору надо как-то уметь руками вызывать dump-to-manual или что..
      // %pain креатору бы уметь передать параметр в окружение.. из события которое пришлем
      // креатору.. ну или из метода

      reaction (event @x "add_list_txt") {: list_url x=@x |
        // %pain создавать объекты из фич и чтобы они ручные были
         let a = x.vz.createObj( {parent:x, manual: true})
         a.manual_feature( "cv-list-txt" )

         a.setParam("manual",true,true)
         a.setParam("list_url",list_url?.url,true)
         
         a.manuallyInserted = true        
        :}

      dlg: add-files-dlg
      reaction (event @dlg "added") {: arr files=(param @x "own_files" manual=true) x=@x |
         if (arr.listtxt) {
           x.emit("add_list_txt",arr.listtxt)
           //console.log(555,arr.listtxt)
         }
         else
           files.set( (files.get() || []).concat( arr ) )
      :}
      reaction (event @dlg "added") (event @x "added")

      // выбор файла через ссылки
      // и тут начинается полный отстой.. если мы по списку файлов загружаемся..
      // и вначале что-то добавляется, или в серединке удаляется.. все начинают
      // съезжать ))))))))))
      // а ссылки сделаны прям на объекты вот эти.. 
      // так что по уму, по уму.. это находить как-то записи о файлах..
      // и привязываться.. причем как-то не по номеру, а по не знаю чему..

      repeater model=@x.files { |file|
        y: object title=(+ @x.title "/" @file.name)        
        {
          param-info "output" out=true

          let link_from_file = (find_link object=@y param_name="output" dir="from")
          //console-log "file=" @file "link_from_file=" @link_from_file

          if @link_from_file {
            console-log "THUS loading file" @file
            lf: load-file @file 
            reaction @lf.output (param @y "output")
            // так то: connect @lf.output @y.output, todo!
          }  
        }        
      }
      

    }
}    

feature "add-files-dlg" {
  x: dialog style="z-index: 12000; width: 600px;" {
    let new_files =(create_channel [])
    column style="width: 100%" {

      select: switch_selector_row index=0 items=["Локальные файлы","URL","Список URL","Загрузка списка"] {{ hilite_selected }}

      reaction (event @x "show") {: obj=@g2 |
        obj.dom.value = ""
      :}
      reaction (event @x "show") {: obj=@g3 |
        obj.dom.value = ""
      :}
      reaction (event @x "show") {: obj=@g |
        obj.dom.value = ""
      :}

      show-one index=@select.index style="padding:0.3em;" {
         g: files
         g2: input_string dom_attr_name="file_url"
         g3: input_strings dom_attr_name="file_url"
         g4: input_string dom_attr_name="list_url"
      }

      if (@select.index == 0) {
        reaction (param @g "output_value") @new_files existing=true
      }

      if (@select.index == 1) {
        reaction (param @g2 "output_value") {: url v=@new_files | 
            let sp = url.split('/');
            if (sp.at(-1) == '') sp.pop();
            let result = {name:(sp.at(-1) || ""),url:url}
            v.set( [result] ) 
         :} existing=true
      }      

      if (@select.index == 2) {
        reaction (param @g3 "output_value") {: urls v=@new_files | 
           let results = urls.map( url => {
            let sp = url.split('/');
            if (sp.at(-1) == '') sp.pop();
            let result = {name:(sp.at(-1) || ""),url:url}
            return result
           })
           v.set( results ) 
         :} existing=true
      }

      if (@select.index == 3) {
        reaction (param @g4 "output_value") {: url v=@new_files | 
            let sp = url.split('/');
            if (sp.at(-1) == '') sp.pop();
            let result = {name:(sp.at(-1) || ""),url:url}
            let arr = []
            arr.listtxt = result
            v.set( arr ) 
         :} existing=true
      }         

      addbtn: button "Добавить" class="important_button" style="margin-top: 1em;"

      reaction (event @addbtn "click") {: src=(read @new_files) dlg=@x | 
        let arr = src.get()
        
        if (Array.isArray(arr)) {
            //files.set( (files.get() || []).concat( arr ) )
            src.set( [] );
            dlg.emit( "added",arr )
            dlg.close()
        }
      :}
    }
  }
}

feature "add-files-dlg-old" {
  x: dialog {
    let new_files =(create_channel [])
    column {
      gui-files @new_files @new_files
      addbtn: button "Добавить" class="important_button"

      reaction (event @addbtn "click") {: src=(read @new_files) dlg=@x | 
        let arr = src.get()
        if (Array.isArray(arr)) {
            //files.set( (files.get() || []).concat( arr ) )
            src.set( [] );
            dlg.emit( "added",arr )
            dlg.close()
        }
      :}
    }
  }
}       
       

feature "cv-select-files-old" {
  qqe: layer_object
    title="Набор файлов"
    initial_mode=1
    url=""
    list_url=""
    files=[]
    {{ x-param-string name="url" }}
    {{ x-param-string name="list_url" }}
    {{ x-param-files  name="files" }}
    {{ x-param-switch name="src" values=["URL","Файл с диска","Папка list.txt","Папка с диска"] }}
    src=0

    output=(m_eval {: src=@qqe->src a=@qqe->url b=@qqe->files c=(@load_list_txt->output? or []) |
      
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
      :} )
    first_file =@qqe.output.0

    gui={ paint-gui @qqe }
    /*
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
    */
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
              column { 
                 //render-params-list object=@qqe list=["files"] 
                 gui-slot @qqe "files" gui={ |in out| gui-local-files @in @out}
              }
              column { 
                  render-params-list object=@qqe list=["list_url"] 
                  
                  text "found files:"
                  gui-text btn_title="Посмотреть" hint="Список url файлов построенный по указанному list.txt"
                    in=(m-eval {: arr=@load_list_txt.output? | return (arr || []).map( n => n.url ).join('\n') :} | create-channel) out=(create-channel)
                  //dom tag="textarea" dom_obj_value=(m-eval {: arr=@load_list_txt.output| return arr.map( n => n.url ).join('\n') :})
              }
              column { files }
            }

            addbtn: button "Добавить"
            reaction (event @addbtn "click") {: :}

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
    // todo добавить фильтрацию по комментариям например # или //
    let listing = (load-file file=@listing_file_url
                   | m_eval "(txt) => txt && txt.length > 0 ? txt.split('\\n').map( x => x.trim()).filter( x => x.length > 0) : []" @.->input);
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

///////////////////// фильтр датафрейма
coview-record title="Фильтр данных" type="cv_df_filter_bynum" cat_id="process"

// вопрос как передать addons в меш..
feature "cv_df_filter_bynum" {
  vp: process
   title="Фильтр данных"
   gui={ paint-gui @vp }
   output=(df-slice input=@vp->input start=@vp.index count=1) 
   index=0
   {
    param-info "input" in=true out=true // df-ка
    param-info "output" in=true out=true // df-ка
    param-info "index" in=true out=true

    gui debug=true {
      gui-tab "main" {
        gui-slot @vp "input" gui={ |in out| gui-df @in @out }

        gui-slot @vp "index" gui={ |in out| gui-slider @in @out min=0 max=(@vp.input.length - 1) step=1 }

        gui-slot @vp "output" gui={ |in out| gui-df @in @out }
      }
    }
  }
}

/////////////////////
/*
coview-record title="Поиск пересечений по клику" type="cv_intersect_mouse" cat_id="process"

feature "cv_intersect_mouse" {
  x: process
    title="Поиск пересечений по клику"
    ~have-scene-env
    scene_env = { |show_3d_scene_r opacity| 

       let cam = @show_3d_scene_r.camera.output
       let scene_items = @show_3d_scene_r.scene3d
       //let THREE=(import_js (resolve_url "../../../libs/lib3dv3/three.js/build/three.module.js"))

       reaction (dom-event-cell @show_3d_scene_r "click") { |event| 
                compute_intersect 
                  (m-eval {: event=@event domElement=@show_3d_scene_r.dom | 
                                           return { x: (event.clientX / domElement.clientWidth) * 2 - 1, y: -(event.clientY / domElement.clientHeight) * 2 + 1 } :})
                  @cam
                  @scene_items
                  @x
       }
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
// вот образец - люблю делать "готовое удобное"
//   а по факту это 2 вещи слеплены. ловилка кликов по поверхности ареа. и - реакция на это в форме вот указанной.
//   todo придумать как правильно "расшить" их
//

coview-record title="Поиск пересечений центра" type="cv_intersect_center" cat_id="process"

feature "cv_intersect_center" {
  x: cv-intersect-mouse
    title="Поиск пересечений центра"
    convert_fn = {: event domElement | return { x: 0, y: 0 } :}
}

// screen_coords - координаты [ -1..1, -1..1 ]
let THREE=(import_js (resolve_url "../../../libs/lib3dv3/three.js/build/three.module.js"))

jsfunc "compute_intersect" {: screen_coords threejs_camera scene_items obj THREE=@THREE |

        let raycaster = new THREE.Raycaster()
        ///let mouse = convert_fn( event, domElement )
        raycaster.setFromCamera(mouse, threejs_camera)

        const intersects = raycaster.intersectObjects( scene_items, true )

        //console.log( "intersects=",intersects)

        obj.setParam("output",intersects)

        if (intersects.length > 0) {
          let pt = intersects[0].point
          let coord_arr = [ pt.x, pt.y, pt.z ]  
          obj.setParam("successful_coords", coord_arr )
          //x.setParam("successful_coords", coord_arr ) 
          obj.emit("successful_coords_event", coord_arr ) // что тоже интересно
        }

        //console.log( "click", event_data, threejs_camera,scene_items,dom)
:}
*/

// послали сигнал perform получили результат на выходах
// но вообще это мудро. и формально - достаточно просто на input реагировать..
// либо этой штуке быть функцией
// на input реагировать не получится - меняются параметры камеры поэтому нужен внешний сигнал

// вообще этой штуке тут не место
feature "scene_intersector" {
  x: object 
    //scene_coords=[0,0]
    //threejs_camera=null
    //scene_items=[]
  {
    let THREE1=(import_js (resolve_url "../../libs/lib3dv3/three.js/build/three.module.js"))
    reaction (event @x "perform") {: screen_coords threejs_camera=@x.threejs_camera scene_items=@x.scene_items obj=@x THREE=@THREE1 |

        let raycaster = new THREE.Raycaster()
        ///let mouse = convert_fn( event, domElement )
        // учтем историю что там еще камера области..
        if (threejs_camera.children[0])
          threejs_camera = threejs_camera.children[0]; 

        raycaster.setFromCamera(screen_coords, threejs_camera)
        raycaster.layers.set( 0 );

        const intersects = raycaster.intersectObjects( scene_items, true )

        //console.log( "intersects=",intersects)

        let output={
          intersects: intersects,
          intersect: intersects[0]
        }

        if (intersects.length > 0) {
          let pt = intersects[0].point
          let coord_arr = [ pt.x, pt.y, pt.z ]
          output.coords_arr = coord_arr

          obj.setParam("successful_coords", coord_arr )
          //x.setParam("successful_coords", coord_arr ) 
          obj.emit("successful_coords_event", coord_arr ) // что тоже интересно

          // теперь поищем объект
          //console.log("intersects",intersects)
          let tgt_obj = intersects[0].object.$vz_object
          if (tgt_obj)
            output.obj = tgt_obj
        }

        // не понимаю - аутпут хорош но сложная структура к нему в визуальном редакторе пока не прицепишься
        obj.setParam("output",output)

        //console.log( "click", event_data, threejs_camera,scene_items,dom)
    :}

  }
}
