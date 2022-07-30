feature "loader"
{
  crit=(m_lambda "() => 0");
};

feature "load-dir" {
  qqe: visual_process
    editable-addons
    title="Загрузка каталога"
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