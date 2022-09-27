import * as Viewzavr from "./viewzavr-core/init.js";
import * as compomachine from "./compolang/machine.js";
import * as packages_api from "./player-stuff/packages-api.js";
import * as save_state_to_window_hash from "./player-stuff/window-hash-p.js";
import * as timers from "./player-stuff/timers.js";

// коды инициализации Vrungel/Compalang
export function init() {

    var vz = Viewzavr.create();

    //////////////////////////// feature lang
    
    compomachine.setup( vz, compomachine );
    packages_api.setup( vz, packages_api );
    save_state_to_window_hash.setup( vz, save_state_to_window_hash );
    timers.setup( vz, timers );    
    
    var vzPlayer = vz.createObj();
    window.vzPlayer = vzPlayer;
    
    vzPlayer.feature("packages_load packages_table save_state_to_window_hash");

    var htmldir = vz.getDir(import.meta.url)  
    register_packages( htmldir );

  // странно что он возвращает объект "машины". мог бы и промису возвращать..
  vzPlayer.start_v1 = (file,perform_restore=true) => {
    //var filedir = Vrungel.add_dir_if( vz.getDir( file ), htmldir );
    var filedir = vz.getDir( file );
    
    let obj = vz.createObj();

    fetch( file ).then( (res) => res.text() ).then( (txt) => {
        //console.log(txt)
        
        window.vzRoot = obj; // ну это нам для консоли.. хак конечно..
        obj.feature("compolang_machine");
        obj.setParam("base_url",filedir);
        obj.setParam("diag_file", file );
        obj.setParam("text",txt);

        //obj.feature("timers")

        // типа оно не сразу отработает, на это одна надежда
        // но вообще надо нормальный метод с промисом. 
        // потому что нам и отработать надо 1 раз всего..

        if (perform_restore)
        obj.on("machine_done",(res) => {
          //console.log("done catched",res)

          obj.delayed( vzPlayer.restore_state,2 )(); 
          // все ссылки отработают (им нужен 1 такт)
          // но хотя и это спорно
        });
    });
    
    return obj;

  }; //vzPlayer.start
  
  // obj это ну машина компаланга, сиречь корневой объект
  vzPlayer.restore_state = (obj) => {
    return vzPlayer.loadFromHash("vrungel",obj).then( () => {
        // console.log("restored. emitting global dump-loaded");
        // vzPlayer.getRoot().emit("dump-loaded");
        //vzPlayer.getRoot().setParam("dump_loaded",true);
        vzPlayer.setParam( "dump_loaded",true );
        vzPlayer.startSavingToHash("vrungel",obj);
    });
  };

  return { vz, vzPlayer };
}

// наполнение таблицы пакетов стандартной библиотеки
// возможно стоит перенести просто в файл в каталоге libs
export function register_packages( htmldir ) {

    vzPlayer.addPackage( {code:"lib3d",url:(htmldir + "./libs/lib3d/lib3d.js")});
    vzPlayer.addPackage( {code:"csv",url:(htmldir + "./libs/csv/features.js")});

    vzPlayer.feature("register_compolang_func");
    vzPlayer.register_compalang( "params",(htmldir + "./libs/params/params.cl"));

    // короче идея такая что загружать из стандартного чего-то типа list.txt или еще что
    // а то получается знание из пакета кочует сюда и это коряво. пусть пакет живет в папке, это можно пережить..
    // например как альтернативный вариант..
    vzPlayer.register_compalang( "gui",(htmldir + "./libs/gui/init.cl"));
    vzPlayer.register_compalang( "io",(htmldir + "./libs/io/init.cl"));
    vzPlayer.register_compalang( "render-params",(htmldir + "./libs/render-params/init.cl"));

    vzPlayer.register_compalang( "lib3dv2",(htmldir + "./libs/lib3dv2/init.cl"));
    vzPlayer.register_compalang( "lib3dv3",(htmldir + "./libs/lib3dv3/init.cl"));
    vzPlayer.register_compalang( "df",(htmldir + "./libs/df/init.cl"));
    vzPlayer.register_compalang( "misc",(htmldir + "./libs/misc/init.cl"));
    vzPlayer.register_compalang( "svg",(htmldir + "./libs/svg/init.cl"));
    vzPlayer.register_compalang( "set-params",(htmldir + "./libs/set-params/init.cl"));
    vzPlayer.register_compalang( "new-modifiers",(htmldir + "./libs/new-modifiers/init.cl"));
    vzPlayer.register_compalang( "imperative",(htmldir + "./libs/imperative/init.cl"));

    vzPlayer.register_compalang( "scene-explorer-3d",(htmldir + "./libs/scene-explorer-3d/init.cl"));
    vzPlayer.register_compalang( "56view",(htmldir + "./libs/56view/init.cl"));
}

 ////////////////////////////
export   function getParameterByName(name) 
   {
      name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
      var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
          results = regex.exec(location.search);
      
      return results === null ? null : decodeURIComponent(results[1].replace(/\+/g, " "));
    };

    // эта функция есть и в compolang.js бо взята оттуда
export function add_dir_if( path, dir ) {
      if (path[0] == "/") return path;
      if (path.match(/\w+\:\/\//)) return path;
      if (path[0] == "." && path[1] == "/") path = path.substring( 2 );
      if (path.trim() == "") return null; // if blank path specified, that means no data should be displayed. F-BLANK
      return dir + path;
    }