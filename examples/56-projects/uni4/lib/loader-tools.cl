// todo переименовать этот файл и файл с vismakers

feature "data-artefact" {
  x:
    title_path=(join (@x | get_parent | geta "title_path" default="") @x->title with=' / ')
    vis_makers=(compatible_visual_processes_for @x)
};

// оказалось фишка в том что vismakers держат scope и он меняется вслед за сменой активного артефакта
// поэтому полезно их просто один раз создать для каждого артефакта всей пачкой да ивсе.

feature "dataset" {
  x: visual_process title="Входные данные"
    gui={
      column plashka {
        
        ba: button_add_object
              add_to=@x
              add_type="data-entity"
              ;

        show-inner-objects @x find="data-artefact";
      };
    };
};

feature "artmaker";

////////////////////////////// рост артефактов

let art_makers_list=(find-objects-bf features="artmaker");
let art_makers_codes=(@art_makers_list | map_geta "code");

//@art_makers_codes | console-log "MAKER CODES";

// назначение - по входному артефакту выявить нарожать артефактов, которые могут парсить этот
// т.е. рожаем образы чтения
// input - входной артефакт (объект data-artefact)
// level - уровень глубины графа. чтобы не зациклиться.

// output - список созданных артефактов. не знаю может его деревом лучше показать..
// кстати где-то у меня уже был обход дерева.. walk_objects

feature "grow-artefacts" {
  x: level=0 
     {
        let making_artefacts = (
              @art_makers_codes
              | // создаем новые artmaker-ы
              repeater target_parent=@x {
                create_objects @x.input
              }
              |
              map_geta "output" default=null // возьмем выходы create-objects-ов
              | 
              map_geta 0 // там ж массив.. хотя это как бы намек что мы мейкеров можем вообще создавать пачкой сразу
              | 
              filter_geta "possible"
              |
              map_geta "make"
              );

        let new_arts = (@making_artefacts | repeater target_parent=@x { // создаем новые артефакты
          //create_objects;
          k: output=(insert_children input=@x->input list=@k->input) 
        } | map_geta "output" default=null | map_geta 0 default=null);

        // если мы ушли недалеко - подключаем автогенерацию новым артефактам..
        if (@x->level < 3) then={
          @new_arts | repeater {
            grow-artefacts level=(@x->level + 1); 
          };
        };

  }; // x
};

// это наша стартовая сущность которую пользователь добавляет в проект
// а data-artefact это уже взгляд на нее. (ну как бы..)
feature "data-entity" {
  qqe: visual_process
    editable-addons
    title="Артефакт данных"
    project=@..
    initial_mode=1
    //output=@files->output
    {{ x-param-string name="url" }}
    {{ x-param-files name="files" }}
    {{ x-param-switch name="src" values=["URL","Файл с диска","Папка"] }}
    src=0
    //output=( (list (list @qqe->url?) @qqe->files?) | geta @qqe->src default=null | console-log "entity output")
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
    data-artefact

    gui={
      column plashka {

        render-params-list object=@qqe list=["title"];

        param_field name="Источник" {

          column {
            render-params-list object=@qqe list=["src"];

            /*
            sa: switch_selector_row index=0
              items=["URL","Файл с диска","Папка"] {{ hilite_selected }} 
              ;
            */  

            show-one index=@qqe->src style="padding:0.3em;" {
              column { render-params-list object=@qqe list=["url"];; };
              column { render-params-list object=@qqe list=["files"];; };
              column { files; };
            };
          };
        };

        // render-params @qqe filters={ params-hide list="title"; };

        param_field name="Обнаруженные данные:" {
          column {
            @found_artefacts | repeater {
              q: text (@q->input | geta "title_path");
            };
          };
        };

        button "Удалить артефакт" {
          m_lambda "(obj) => obj.remove()" @qqe;
        };

        // пока остановимся на полном построении карты возможностей
        // manage-addons @qqe title="Тип данных";
      };
    }
    //url="http://127.0.0.1:8080/vrungel/public_local/Kalima/v2/vtk_8_20/list.txt"
    //url="https://viewlang.ru/assets/lava/Etna/list.txt"
    //url=""
    {
     
     //files: select-files url=@qqe->url? index=@qqe->initial_mode;
     //insert_children input=@qqe list=(@files->output | types_from_files);
     
     @qqe | grow-artefacts;

     let found_artefacts=(find-objects-bf "data-artefact" root=@qqe include_root=false);
    };
};


/////////////////////////////////////////

feature "find-file" {
  r: output=@mm->output {

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
  r: output=@mm->output {
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
  r: output=@mm->output {
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
  r: output=@mm->output {
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


////////////////////////////// загружалка каталога

artmaker
  code={ |art|
    m: list_file=(m_eval "(url) => {
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

//////////////////////////////