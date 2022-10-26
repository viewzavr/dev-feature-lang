export function setup(vz, m) {
  vz.register_feature_set(m);
}

export function packages_table( x ) {

  var packagesTable = {};
  // a table of records: { code, title, url, info, ... }
  
  // opts = { code: codename, url: package-url }
  x.addPackage = function(opts,arg2) {
    if (Array.isArray(opts)) {
      opts.forEach( function(rec) { x.addPackage(rec); } );
      return;
    }
    if (typeof(opts) === "string") {
       opts = { code: opts, url: arg2 }
    }
    packagesTable[ opts.code ] = opts;
  }
  x.addPackagesTable = function(table) {
    Object.keys(table).forEach( function(key) {
      var record = Object.assign( {}, table[key], {code: key} );
      x.addPackage( record );
    });
  }

  x.getPackagesTable = function() { return packagesTable };
  
  x.getPackageByCode = function(code) {
    var t = x.getPackagesTable();
    return t[code];
  }
  
  x.loadPackageByCode = function(code) {
    if (Array.isArray(code))
    {
      var arr = code;
      var promises = [];
      for (var i=0; i<arr.length; i++) {
        try {
          promises.push( x.loadPackageByCode( arr[i] ) );
        } catch (err) {
          console.error("vr-player-v1: failed to import",arr[i],err );
        }
      }
      return Promise.allSettled( promises );
    }

    var m = x.getPackageByCode(code);
    if (!m) {
      console.error("loadPackageByCode: Package not found for code=",code);
      return;
    }
    var url = m.url;
    return x.loadPackage( url );
  }
  
  // feature: single API for all
  // btw we don't need array iteration then!
  var orig = x.loadPackage;
  x.loadPackage = function(url_or_code) {
    if (x.getPackageByCode(url_or_code))
      return x.loadPackageByCode(url_or_code);
    return orig( url_or_code );
  }
  
  
  // feature: track loaded packages
  var loadedPackagesTable = {};
  x.isPackageLoaded = function(code) {
    return !!loadedPackagesTable[code];
  }
  var orig1 = x.loadPackageByCode;
  x.loadPackageByCode = function(code) {
    var q = orig1(code);
    q.then( () => {
      loadedPackagesTable[code] = true;
    });
    return q;
  }
  
  
  /* а зачем нам это? тем более тогда надо с массивами разбираться
     пусть пока в аргументах будет. см выше.
     
  // feature: track loaded packages by code or by url
  // actually it was developed for packages with codes
  // but as it now considers urls too, probably it is
  // better move to dedicated feature file
  var loadedPackagesTable = {};
  x.isPackageLoaded = function(path) {
    return !!loadedPackagesTable[path];
  }
  var orig1 = x.loadPackage;
  x.loadPackage = function(path) {
    var q = orig1(path);
    q.then( () => {
      loadedPackagesTable[path] = true;
    });
    return q;
  }
  */
}

export function packages_load(p) {
  // loads viewzavr package
  // this means load file and call it's exported `setup` function
  // url may be:
  // * path to js file
  // * an array of pathes
  // * txt file, where each line is a path to js or txt file
  // returns promise that is resolved when all url data is processes (wherever successfully or not)
  p.loadPackage = function( url ) {
    if (Array.isArray(url)) 
    {
      var arr = url;
      var promises = [];
      for (var i=0; i<arr.length; i++) {
        try {
          promises.push( p.loadPackage( arr[i] ) );
        } catch (err) {
          console.error("vr-player-v1: failed to import",arr[i],err );
        }
      }
      return Promise.allSettled( promises );
    }
    
    if (url.indexOf(".txt") >= 0) {
      return new Promise( function( resolv, rej ) {
    
      //fetch(url,{credentials: 'include'}).then((response) => {
      //seems credentials are useless now - until we will consider credentials of import..
      fetch(url).then((response) => {
        return response.text();
        })
      .then((data) => {
        //console.warn("loaded txt:",data);
        var dir = url.substr( 0, url.lastIndexOf("/") ) + "/";
        var things_to_load = data.split("\n")
             .map( l => l.split("#")[0].trim() ) // # комментарии
             .filter( l => l.length > 0 )        // непустые строки
             .map( function(line) {
                 // проверим может это ссылка на известный пакет
                 if (p.getPackageByCode( line ))
                    return line; // ссылка на пакет - грузим как внешний пакет
                 // на будущее - еще можно разделить на / и проверять по первому символу
                 // и если это там то это подпакет.. 
                 return dir + "./" + line;
             })
        p.loadPackage( things_to_load ).then( function(res) { 
           resolv( res ); // we provide empty {} object to resolv - so module arg will not be null (see below)
        } );
      });
        // todo errors!
      });
      
    }

    return new Promise( function( resolv, rej ) {
      var url2 = formatSrc( url ); // TODO this is hack based on viewlang function formatSrc
      //console.log("import url2=",url2)
      import( url2 ).then( function(mod) {
        var setup = mod.setup || mod.default; // спорно, что юзаем default
        if (setup) {
          var s = setup( p.vz, mod );
          if (s instanceof Promise)
            s.then( function() { resolv(mod) } );
          else
            resolv( mod );
        }
        else {
          // todo = тут надо выставить что setup-а не случилось. Чтобы загрузчики могли это понимать.
          resolv( mod );
        }
      }).catch( rej );
    });
  };

};


////////////
function formatSrc(src) {
  // console.log("formatSrc src=",src);
  if (src.indexOf("https://github.com/") == 0) {
     // обработка случая, когда загружают qmldir прямо из корня репозитория с пропуском метки /master, вынесена в qmlweb в import.js::readQmlDir, т.к. надо там фиксить урли файлов
     src = src.replace("/blob/","/");
     src = src.replace("https://github.com/","https://raw.githubusercontent.com/");
  }
  //src = src.replace("https://raw.githubusercontent.com","http://win.lineact.com/github");
  if (typeof(window) !== "undefined")
      src = src.replace("https://raw.githubusercontent.com",window.location.protocol+"//viewlang.ru/github");
  
  if (src.indexOf("https://gist.github.com/") == 0) {
     // добрый дядя gist помещает имя файла в хэш-часть урля...
     var filepart = src.split( "#file-" );
     if (filepart[1]) filepart[1] = filepart[1].replace("-",".");
     // таким образом преобразовали 
     // https://gist.github.com/pavelvasev/d41aa7cedaf35d5d5fd1#file-apasha2-vl
     // https://gist.github.com/pavelvasev/d41aa7cedaf35d5d5fd1#file-apasha2.vl 
     
     src = filepart.join("/raw/");
     // а теперь получили https://gist.github.com/pavelvasev/d41aa7cedaf35d5d5fd1/raw/apasha2.vl 

     if (!src.match(/\/raw(\/*$|\/)/) ) src = src + "/raw";
     // проверим, есть ли уже вставка /raw/ в урль.
     // если на входе было только https://gist.github.com/pavelvasev/d41aa7cedaf35d5d5fd1
     // то теперь получили https://gist.github.com/pavelvasev/d41aa7cedaf35d5d5fd1/raw

     
     src = src.replace("https://gist.github.com/","https://gist.githubusercontent.com/");
     // и заменили на raw-версию с гиста:
     // https://gist.githubusercontent.com/pavelvasev/d41aa7cedaf35d5d5fd1/raw/apasha2.vl 
     // https://gist.githubusercontent.com/pavelvasev/d41aa7cedaf35d5d5fd1/raw
  }
  //src = src.replace("https://gist.githubusercontent.com","http://win.lineact.com/gist");
  src = src.replace("https://gist.githubusercontent.com","http://viewlang.ru/gist");
  //console.log("formatSrc result=",src);
  return src;
}