feature "loader" {};

feature "load-dir" {
  qqe: visual_process
    title="Загрузка каталога"
    project=@..
    gui={
      column plashka {
        
        column {
          insert_children input=@.. list=@files->gui;
        };

        render-params @qqe filters={ params-hide list="title"; };
      };
    }
    url="http://127.0.0.1:8080/vrungel/public_local/Kalima/v2/vtk_8_20/list.txt"
    
    {{ x-param-label-small name="all_files_count"}}
    all_files_count=(@files->output | geta "length")
    {
      files: select-files url=@qqe->url index=0;

      insert_loader: insert_children input=@qqe->project {{ console_log_life }};

      logic: {
        when @files "param_output_changed" { |files| 
          console_log "see new files " @files;

          loader_file: find_file @files "loader\.cl";

          when @loader_file "found" { |loader_file|
            console_log "loader found" @loader_file;

            load_loader: load-file file=@loader_file;

            when @load_loader "param_output_changed" { |content|
              //console_log "loader.cl content loaded" @content;

              parser: compalang input=@content;

              // парсер быстрее чем событие. понять что с этим делать..
              when_value @parser->output { |parsed_loader|
                console_log "parsed loader content. inserting" @parsed_loader;

                //ic: insert_children @qqe->project list=@parsed_loader;
                /*
                @insert_loader | x-modify {
                  x-set-params list=@parsed_loader __manual=true;
                };
                */
                set_param target="@insert_loader->list" value=@parsed_loader;

                when @insert_loader "after_deploy" {
                  loaders_logic dir=@files project=@qqe->project;
                };
              };

            };

          };

          when @loader_file "not-found" {
            console_log "loader NOT found";
          };

        };
      };
      

    };
};

feature "loaders_logic" {
  logic: {
    loaders_arr: find-objects-bf features="loader" root=@logic->project | console_log_input "EEE";
    console_log "welcome to loaders-logic" @best->output;

    best: m_eval "(loaders,dir) => {
        console.log('computing best loaders',loaders,dir)
        let best_i = -1;
        let best_value = 0;
        for (let i=0; i<loaders.length; i++) {
          let res = loaders[i].params.criteria( dir );
          if (res > best_value) { best_value = res; best_i = i; }
        }
        return loaders[ best_i ];
      }" @loaders_arr->output @logic->dir;

    when_value @best->output { |ldr|
      console_log "best loader determined" @ldr;
      //insert_children input=@logic->project list=@ldr->load @logic->dir @logic->project;
      //call @ldr "load" 
      m_eval "(ldr,dir,project) => ldr.params.load(dir,project)" @ldr @logic->dir @logic->project;
    };
  };
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