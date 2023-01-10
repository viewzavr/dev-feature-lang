coview-record title="Загрузчик файлов" type="data-load-files" id="data-io"

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

coview-record title="Прочитать файл" type="load-text" id="compute"

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



///////////////////////////////////////// летнее

feature "find-file" {
  r: object output=@mm->output {

  mm: m_eval "(arr,crit,obj) => {
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
      }" @r->0 @r->1 @r;
  };
};

feature "find-files" {
  r: object output=@mm->output {
  mm: m_eval "(arr,crit) => {
        if (!arr) return [];
        if (!Array.isArray(arr)) arr=[arr];
        let regexp = new RegExp( crit,'i' );
        let files = arr.filter( elem => elem?.name?.match( regexp ) );
        return files;
      }" @r->0 @r->1;
  };
};

// по набору имен файлов определяет подпоследовательности файлов
// вход: 1 аргумент массив файлов 
//       2 регулярное выражение с 2 скобочками, первая для имени блока вторая для номера файла
// выход: массив вида [ [имяблока,[массив-файлов]],[имяблока,[массив-файлов]],.. ]

// update - слишком хитрая штука, с встроенной сортировкой
feature "detect_blocks" {
  r: object output=@mm->output {
  mm: m_eval "(arr,crit) => {
        let regexp = new RegExp( crit,'i' );
        let blocks = {};
        arr.forEach( elem => {
          let filename = elem.name;
          let res = filename.match( regexp );
          if (res && res[1]) {

            blocks[ res[1] ] ||= [];

            if (res[2]) // сохраним чиселку для сортировки
                elem.num = parseFloat( res[2] );
            else
                elem.num = 0;

            blocks[ res[1] ].push( elem );
          }
        });
        let blocks_arr = [];
        let block_names = Object.keys( blocks ).sort();
        for (let bn of block_names) {
          let files = blocks[bn].sort( (a,b) => a.num - b.num );
          blocks_arr.push( [ bn, files] );
        }

        return blocks_arr;
      }" @r->0 @r->1;
  };
};

// вход input массив файлов, arg0 = маска с регулярным выражением где 1-я скобочка дает число
// выход output
feature "sort_files" {
  r: object output=@mm->output {
  mm: m_eval "(arr,crit) => {
        let regexp = new RegExp( crit,'i' );
        let blocks = {};
        arr.forEach( elem => {
          let filename = elem.name;
          let res = filename.match( regexp );
          if (res && res[1]) {
            // сохраним чиселку для сортировки
            elem.num = parseFloat( res[1] );
          }
          else elem.num = 0;
        });
        arr = arr.sort( (a,b) => a.num - b.num );
        return arr;
      }" @r->input @r->0;
  };
};


////////////////////////////// загружчик каталога
/*
artmaker
  code={ |art|
    m: object 
    list_file=(m_eval "(url) => {
      if (!url?.find) return null;
      let k = url.find( elem => elem?.name=='list.txt' );
      return k;
      }" @art.output?)
    possible=@m->list_file?
    make={ art-load-list-txt file=@m->list_file };
  };

feature "art-load-list-txt" {
  x: data-artefact 
    title="Каталог файлов"
    output=@result
   {
    let listing_file_url=@x->file;
    let listing = (load-file file=@listing_file_url 
                   | m_eval "(txt) => txt && txt.length > 0 ? txt.split('\\n') : []" @.->input);
    let listing_file_dir = (m_eval "(str) => str?.url ? str.url.split('/').slice(0,-1).join('/') : ''" @listing_file_url);
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
*/

//////////////////////////////