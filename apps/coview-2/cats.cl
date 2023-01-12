load "gui-system/init.cl"

// Конкретные категории

coview-category title="Слои" id="layer"

coview-category title="Загрузка" id="data-io"
coview-category title="Программы" id="process"
coview-category title="Расчёты" id="compute"
coview-category title="Основное" id="basic" 
coview-category title="Экраны" id="screen"


coview-record title="Оси координат" type="axes-view" cat_id="basic"

coview-record title="Загрузчик файлов" type="data-load-files" cat_id="data-io"

// это наша стартовая сущность которую пользователь добавляет в проект
// а data-artefact это уже взгляд на нее. (ну как бы..)

// включевое поле output это массив вида [ {name,url}, {name,url}, fileobject, ... ]

feature "data-load-files" {
  qqe: data-artefact
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

coview-record title="Прочитать файл" type="load-text" cat_id="compute"

feature "load-text" {
  x: computation 
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
coview-record title="Сферы" type="spheres_vp_3d" cat_id="basic"

// вопрос как передать addons в меш..
feature "spheres_vp_3d" {
  vp: visual-process
   ~editable-addons
   title="Сферы"
   gui={ paint-gui @vp }
  ~spheres {
    param-info "input" in=true // df-ка

    //console-log "vvv" @vp.output

    gui {
      gui-tab "main" {
        gui-slot @vp "input" gui={ | in out| gui-df @in @out }
      }
      gui-tab "view" {
      render-params @vp
             filters={ params-hide list="title"; };
       render-params @vp->mesh
             filters={ params-hide list="visible"; };
      }
      gui-tab "addons" {
    manage-addons @vp->mesh;
      }
    }
  }
};
