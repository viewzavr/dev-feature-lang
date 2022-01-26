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
  style="position: absolute; width:100%; height: 100%; left: 0px; top: 0px;"
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


////////
// вход:
// input - массив
// code  - функция проверки что элемент подходит

// выход:
// output - массив с элементами прошедшими проверку

// пример: @arrsource | arr_filter code="(val,index) => index%3 == 0" | console_log

register_feature name="arr_filter"
  code=`
  env.onvalues(["input","code"],process);

  function process(arr,code) {
    if (!Array.isArray(arr)) {
      env.setParam("output",[]);
      return;
    }
    //var f = new Function( "line", code );
    //var res = dfjs.create_from_df_filter( df, f );
    
    var f = eval( code );

    let res = [];
    arr.forEach( (v,index) => {
       let check = f( v,index );
       if (check) res.push( v );
    })
    env.setParam("output",res);
  }
`;


register_feature name="arr_find_min_max" code=`
  env.onvalues(["input"],process);

  env.addCmd("refresh",() => process( env.params.input ));

  function compute_array_minmax( arr,min=10e10,max=-10e10 ) {
    for (var i=0; i<arr.length; i++) {
      var v = arr[i];
      if (v < min) min = v;
      if (v > max) max = v;
    }
    return {min: min, max:max, diff: (max-min)};
  }

  function isTypedArray(obj)
  {
    return !!obj && obj.byteLength !== undefined;
  }

  function process(arr) {

    if (!(Array.isArray(arr) || isTypedArray(arr))) {
      console.error("arr_find_min_max: not an array on input",arr);
      return;
    }

    let res = compute_array_minmax( arr );

    
    env.setParam("min",res.min);
    env.setParam("max",res.max);
    env.setParam("diff",res.diff);

    env.setParam("output",res)
  }
`;
