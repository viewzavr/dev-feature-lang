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
      //url="http://127.0.0.1:8080/vrungel/public_local/Kalima/list.txt"
      //dictionary_urls=["http://127.0.0.1:8080/vrungel/public_local/Kalima/list.txt"]
      //url="https://viewlang.ru/assets/lava/Etna/list.txt"
    //url="http://127.0.0.1:8080/vrungel/public_local/Etna/list.txt"
    url="http://127.0.0.1:8080/vrungel/public_local/Kalima/v2/vtk_8_20/list.txt"
    
    {{ x-param-label-small name="all_files_count"}}
    all_files_count=(@files->output | geta "length")
    {
      files: select-files url=@qqe->url;

      loader_file_obj: m_eval "(arr) => {
        let loader_file = arr.find( elem => elem[0] == 'loader.cl' );
        if (!loader_file) {
          console.warn('loader.cl not found in dir',arr)
          return null;
        }
        if (!loader_file[1]) {
          console.warn('loader.cl found but content is undefined',loader_file)
          return null;
        }
        console.warn('loader.cl is found in dir',loader_file)
        return loader_file[1];
      }" @files->output;

      loaded_content: load-file file=@loader_file_obj->output;

      parsed: compalang input=@loaded_content->output;

      r1: insert_children 
              input=@qqe->project 
              list=@parsed->output;

      @r1 | x-modify {
        x-on "after_deploy" {
          m_lambda "(active_view,emitter,created_objects) => {
            created_objects.forEach( obj => {
              if (obj.is_feature_applied('visual_process'))
                active_view.append_process( obj );
            })
          }" @qqe->active_view;
        };
      };


      @r1->output | x-modify { x-set-params dir=@files->output; };

      /*
      //r1: insert_children input=@loader_cl_content list=@parsed->output {{ console_log_life "recre1"}};
      loader_cl_content: teta=5;
      loader: insert_children input=@qqe->project 
              list=(@loader_cl_content | console_log_input | get_child name="loader" | console_log_input 'i2') {{ console_log_life "recre2"}};
      @loader->output? | x-modify { x-set-params dir=@files->output };
      */

      /*

      //loaded_dump: compalang input=@loaded_content->output;
      //insert_children input=@.. list=@loaded_dump->output;

      //console_log @loaded_content->output;

      @cm | x-modify { 
          x-set-params text=@loaded_content->output base_url="?";
        };

      cm: compolang_machine 
      
      //{{ x-on 'machine_done' {
      //   m_lambda "(machine,dir) => {
      //      let loader_feature = machine.ns.getChildByName("loader");
      //      let loader = machine.vz.createSyncFromDump( loader_feature, null, machine.ns.parent );
      //      loader.setParam( "dir", dir)
      //   }" @files->output;
      // } }}
      
      ;

      loader: recreator list=(@cm | get_child name="loader") {{ console_log_life "recre2"}};
      @loader->output? | x-modify { x-set-params dir=@files->output };
      */
    };
};

feature "find-file" {
  r: output=@mm->output {

  mm: m_eval "(arr,crit) => {

        let regexp = new RegExp( crit,'i' );
        let file = arr.find( elem => elem[0].match( regexp ) );
        if (!file) {
          return null;
        }
        return file;
      }" @r->0 @r->1;
  };
};

feature "find-files" {
  r: output=@mm->output {
  mm: m_eval "(arr,crit) => {
        let regexp = new RegExp( crit,'i' );
        let files = arr.filter( elem => elem[0].match( regexp ) );
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
          let filename = elem[0];
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
        console.log('b c',blocks_arr)
        return blocks_arr;
      }" @r->0 @r->1;
  };
};