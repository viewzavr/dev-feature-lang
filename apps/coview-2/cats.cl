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
    files=[]
    {{ x-param-string name="url" }}
    {{ x-param-files  name="files" }}
    {{ x-param-switch name="src" values=["URL","Файл с диска","Папка"] }}
    //{{ x-param-label name="output" }}
    src=0
    output=(m_eval "(a,b,index) => {
      if (index == 0) {
        if (a) {
           let sp = a.split('/');
           if (sp.at(-1) == '') sp.pop();
           return [{name:sp.at(-1),url:a}];
        }
        return [];
      }
      return b;
      }" @qqe->url? @qqe->files? @qqe->src allow_undefined=true)
    first_file =@qqe.output.0
     //{{ console-log "first_file=" @qqe.output.0 "@qqe.output=" @qqe.output "@qqe->output" @qqe->output "tt" (param @qqe "output" |get-value) }}
     //{{ console-log "@qqe" @qqe}}

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
              column { files; };
            };

            //text @qqe->output
          };
        };

      };
    }
    {
      gui { // на будущее
        gui-tab "main" {
          render-params-list object=@qqe list=["title"];

          param_field name="Источник" {

          column {
            render-params-list object=@qqe list=["src"];

            show-one index=@qqe->src style="padding:0.3em;" {
              column { render-params-list object=@qqe list=["url"];; };
              column { render-params-list object=@qqe list=["files"];; };
              column { files; };
            };

            //text @qqe->output
          };
          };
        } // main
        gui-tab "status" {
          gui-slot @qqe "first_file" gui={ |in out| gui-label @in @out }
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

