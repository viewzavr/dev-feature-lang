feature "data-artefact" {
  x:
    title_path=(join (@x | get_parent | geta "title_path" default="") @x->title with=' / ')
};

feature "loader"
{
  crit=(m_lambda "() => 0");
};

feature "dataset" {
  x: visual_process title="Набор данных"
    gui={
      column plashka {
        
        ba: button_add_object
              add_to=@x
              add_type="data-entity"
              ;

        show-inner-objects @x find="data-entity";
        /*
        find-objects-bf "data-entity" root=@x | repeater {
          b: button (@b->input | geta "title") {
            dialog {
              text 123;
            };
          };
        };
        */
      };
    };
};

feature "art"
{
  title=@.->0
  crit=(m_lambda "() => 0")
  ;
};

art title="Каталог" crit=(m_lambda "(url) => {
  if (typeof(url) == 'string' && url.indexOf('list.txt') > 0) return 1;
  return 0;
  }") code={art-load-list-txt};

feature "art-load-list-txt" {
  x: data-artefact 
    title="Каталог файлов"
    output=@result
   {
    let listing_file_url=@x->input;
    let listing = (load-file file=@listing_file_url 
                   | m_eval "(txt) => txt && txt.length > 0 ? txt.split('\\n') : []" @.->input);
    let listing_file_dir = (m_eval "(str) => str ? str.split('/').slice(0,-1).join('/') : ''" @listing_file_url);
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

  

// запись art type= title= crit= это о возможности применения очередного генератора артефактов
art_generators_list: (find-objects-bf features="art");

// назначение - по входному артефакту выявить нарожать артефактов, которые могут парсить этот
// т.е. рожаем образы чтения
// input - входной артефакт (объект data-artefact)
// level - уровень глубины графа. чтобы не зациклиться.

// output - список созданных артефактов. не знаю может его деревом лучше показать..
// кстати где-то у меня уже был обход дерева.. walk_objects
feature "grow-artefacts" {
  x: level=0 

     {
        let artefact_output=(@x->input | geta "output" default=null);
        let compatible_artefact_generators = (or (m_eval "(list,elem,level) => {
            // защита
            if (level > 3) return [];
            let res = list.filter( it => it.params.crit( elem ) > 0 );
            // console.log('gro arts res',res)
            return res;
          }" @art_generators_list @artefact_output @x->level) []);

      @compatible_artefact_generators | repeater {
        r: {
          @x->input | ic: insert_children list=(@r->input | geta "code") | x-modify {
            // нарожали - получите параметр input. пока такой протокол.
            x-set-params input=@artefact_output;
          };
          grow-artefacts input=(@ic->output | geta 0 default=null) level=(@x->level + 1); 
          // получается мы считаем что эта штука должна нам порождать data-artefact-ы
        };
      };

  }; // x
};

// это также можно развернуть в такую схему:
/*
find-objects-bf "data-artefact" limit=100 | get-compatible-generators | repeater {
  r: {
     @someroot | insert_children list=(@r->input | geta "code") | x-modify {
          x-set-params input=(@r->input | geta "artefact");
        };
     };  
};
*/

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
    output=( (list @qqe->url @qqe->files) | geta @qqe->src default=null | console-log "entity output")
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
              q: text (@q->input | geta "title");
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

feature "load-dir" {
  qqe: visual_process
    editable-addons
    title="Папка файлов"
    project=@..
    initial_mode=1
    output=@files->output
    gui={
      column plashka {
        
        column {
          insert_children input=@.. list=@files->gui;
        };

        render-params @qqe filters={ params-hide list="title"; };

        manage-addons @qqe title="Визуализация";
      };
    }
    //url="http://127.0.0.1:8080/vrungel/public_local/Kalima/v2/vtk_8_20/list.txt"
    //url="https://viewlang.ru/assets/lava/Etna/list.txt"
    url=""
    
    {{ x-param-label-small name="all_files_count"}}
    all_files_count=(@files->output | geta "length")
    {
      files: select-files url=@qqe->url index=@qqe->initial_mode;
      insert_children input=@qqe list=(@files->output | types_from_files);
    };
};

// пытается загрузить loader.cl из папки
// параметр files
feature "types_from_files" { 
  t: output=(load-file file=(find_file @t->input "uni2\.cl") | compalang)
};

/////////////////////////////////////////

feature "find-file" {
  r: output=@mm->output {

  mm: m_eval "(arr,crit,obj) => {

        let regexp = new RegExp( crit,'i' );
        let file = arr.find( elem => elem.name.match( regexp ) );
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
        let regexp = new RegExp( crit,'i' );
        if (!arr) return [];
        if (!Array.isArray(arr)) return [];
        let files = arr.filter( elem => elem.name.match( regexp ) );
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