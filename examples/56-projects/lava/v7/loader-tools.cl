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

      insert_loader: insert_children input=@qqe->project;

      l0: csp {
        console_log "welcome to l0";

        when @files "param_output_changed" then={ |dir|
          l1: loader_from_dir_logic files=@dir;

          when @l1 "parsed" then={ |code|
             set_param target="@insert_loader->list" value=@code;

             when @insert_loader "after_deploy" then={ 
               console_log "point 2";
               // теперь у нас есть загрузчик и мы можем передать ему управление
               // через loaders logic, как ни странно
               k: loaders_logic dir=@dir project=@qqe->project active_view=@qqe->active_view;
               when @k "done" then={

                 // стираем загрузчик..
                 set_param target="@insert_loader->list" value=[];

                 restart @l0;
               };
             };
          };

          when @l1 "missing" then={

             console_log "point 2";
             k: loaders_logic 
                    dir=@dir project=@qqe->project 
                    active_view=@qqe->active_view;
             when @k "done" then={
               restart @l0;
             };
          };
        };  
      };

      // todo попробовать обратно переписать на иф-ах

    };
};

// пытается загрузить loader.cl из папки
// параметр files
feature "loader_from_dir_logic" { 

  logic: {
    console_log "welcome to loader_from_dir_logic";
    
    console_log "loader_from_dir_logic see new files " @logic->files;

    loader_file: find_file @logic->files "loader\.cl";

      when @loader_file "found" then={ |loader_file|
        console_log "loader found" @loader_file;
        console_log "files still are" @files;

        load_loader: load-file file=@loader_file;

        when @load_loader "param_output_changed" then={ |content|
          //console_log "loader.cl content loaded" @content;

          parser: compalang input=@content;

          // парсер быстрее чем when. понять что с этим делать..
          when_value @parser->output then={ |parsed_loader|
            q: m_eval "(obj,dir,parsed) => obj.emit('parsed',parsed,dir)" @logic @logic->files @parsed_loader;
          };

        };

      };

      when @loader_file "not-found" then={
        q: m_eval "(obj,dir) => { obj.emit('missing',dir) }" 
           @logic @logic->files;
      };


  };          
};

// отвечает за передачу управления загрузчику
feature "loaders_logic" {
  logic: {
    loaders_arr: find-objects-bf features="loader" root=@logic->project;
    console_log "welcome to loaders-logic. dir is" @logic->dir;

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

    /// todo: а как в ксп записывается if?
    /// ну типа значение пришло а надо понять какое оно и от этого плясать
    /// как вариант when_if (bool expression) data { |data| .... }
    //// но эт не сработает пока m_eval не рассчитался... ну тогда надо его computed-событие ждать
    /// и уже анализировать чего там...

    when @best "computed" then={ |ldr|
      console_log "best loader determined" @ldr;

      if (@ldr) then={

          //insert_children input=@logic->project list=@ldr->load @logic->dir @logic->project;
          //call @ldr "load" 
          mmm: m_eval "(ldr,dir,project,av) => {
            //ldr.params.load(dir,project)
            // ха вопрос а как оно сотрет когда станет ненадо
            ldr.vz.callParamFunction( ldr.params.load, project, false, project.$scopes.top(), dir, project, av);
            return 1;
          }  
          " @ldr @logic->dir @logic->project @logic->active_view
          |
          m_eval "(obj) => obj.emit('done');" @logic;
          ;
/*
          console_log "eee";

          when @mmm "computed" then={
             //restart @logic { select-files-logic };
             //call @logic "done";
             m_eval "(obj) => obj.emit('done');" @logic;
          };
*/          
       }
       else={
         // fail
         console_log "no best loader";
         m_eval "(obj) => obj.emit('done');" @logic;
       };  
    };
  };
};

feature "emit" {
  args: {};

  m_eval "(obj,name) => obj.emit(name);" @args->0 @args->1;
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