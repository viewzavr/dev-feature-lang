feature "if" 
code="
  let cnt=0;
  env.on('appendChild',(c) => {
    cnt++;
    if (cnt > 1 
        && c.ns.name !== 'arg_link_to' // тупняк конечно - чтобы разрешить условия вида if @alfa
        )
      console.warn('if: extra children found!',c.getPath());
  });
"
{
  i: 
    {
    generate
       list=(eval @i->0 @i->then @i->else allow_undefined=true
             code="(cond,t,e) => {
               return cond ? t : e
             };");
    };
};

register_feature name="get_query_param" code=`
    function getParameterByName(name) {
      name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
      var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
        results = regex.exec(location.search);
      //return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
      return results === null ? null : decodeURIComponent(results[1].replace(/\+/g, " "));
    }

    env.onvalue("name",(name) => {
      var v = getParameterByName(name);
      env.setParam("output",v);
    })  
`;

register_feature name="fill_parent" {
  style="position: absolute; width:100%; height: 100%; left: 0px; top: 0px;";
};

register_feature name="below_others" {
  dom_style_zIndex=-1;
};


// идея что оно получает input и команду apply?
// или просто input? и как поменялся - выдаем файл?

// downloads specified file to a users browser
// inputs: 
//  * input - text content,  
//  * filename - filename
// when input changed, a new file is downloaded

/*
  button {
    func {
      sv1: generate_svg input=@..->input;
      download_file_to_user filename="kartina.svg" input=@sv1->output;
    };
  };
*/

register_feature name="download_file_to_user" {
  js code=`
      // https://stackoverflow.com/a/30832210
    // Function to download data to a file
    function download(data, filename, type) {
        var file = new Blob([data], {type: type});
            var a = document.createElement("a"),
                    url = URL.createObjectURL(file);
            a.href = url;
            a.download = filename;
            document.body.appendChild(a);
            a.click();
            setTimeout(function() {
                document.body.removeChild(a);
                window.URL.revokeObjectURL(url);
            }, 0);
    }

    // это у нас синхро-сигнал
    env.onvalue("input",(input) => {
      if (!input || input.length == 0) {
        console.error("download_file_to_user: input is empty")
        return;
      }
      console.log("download_file_to_user: downloading");

      download( input, env.params.filename || "file")
    });
  `;
};


// мониторит указанные параметры params во входном массиве объектов input
// output равен входному массиву
// меняет свой output при обнаружении изменений
// вход: input - массив объектов
//       params - массив имен параметров. 

// пример: find-objects ... | monitor-params params=["alfa","beta"] | console_log;

register_feature name="monitor_params" {
  js code=`
    let unsub_arr = [];
    let unsub_func = ()=> { unsub_arr.forEach( (f)=>f() ); unsub_arr=[]; }

    env.feature("delayed");
    let sig_d = env.delayed( sig );

    env.onvalues(["input","params"],(arr,params) => {
      unsub_func();
      for (let cenv of arr) {
        let cunsub = cenv.onvalues( params, sig_d );
        unsub_arr.push( cunsub );
      };
      sig_d();
    })

    env.on("remove",unsub_func);

    function sig() {
      env.setParam("output", env.params.input.slice() );
    }
  `;
};

// аналог monitor_params но мониторит все параметры.

register_feature name="monitor_all_params" {
  js code=`
    let unsub_arr = [];
    let unsub_func = ()=> { unsub_arr.forEach( (f)=>f() ); unsub_arr=[]; }

    env.feature("delayed");
    let sig_d = env.delayed( sig );

    env.onvalue("input",(arr) => {
      unsub_func();
      for (let cenv of arr) {
        let cunsub = cenv.on("param_changed", sig_d)
        unsub_arr.push( cunsub );
      };
      sig_d();
    })

    env.on("remove",unsub_func);

    function sig() {
      env.setParam("output", env.params.input.slice() );
    }
  `;
};

// timeout 
// паузит передачу input на заданное время 
// если происходит дополнительное изменение input, то таймер рестартует
// таким образом для частых изменений input вообще никогда не пройдет output

// это кстати все начинает напоминать rxjs
// только там промежуточные вещи съедаются, а у нас хранятся...

register_feature name="timeout" code=`

  let t;
  env.feature("timers");
  env.onvalue("input",(i) => {
     if (t) t(); // очистим

     t = env.setTimeout( () => {
        env.setParam("output", env.params.input );
        t = null;
     }, env.params.ms || 1000 );
  });

  /*

  env.feature("delayed");

  let tpass = env.delayed( pass );

  env.onvalue("input",tpass);

  env.onvalue("ms",(ms) => {
    debugger;
    tpass = env.delayed( pass, ms );
  })

  function pass() {
     env.setParam("output", env.params.input );
  }
  */
`;