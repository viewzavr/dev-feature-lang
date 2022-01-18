/*
  Example usage:

  button text="get as svg file" style="position:absolute; z-index:2;" {
      download_svg;
  };
*/

// function. when called, outputs svg to user browser
register_feature name="download_svg" {
  func {
    sv1: generate_svg input=@..->input;
    download_file_to_user filename="kartina.svg" input=@sv1->output;
  };
};

// input: svg element
// output: it's text representation
register_feature name="generate_svg" {
  func code=`
    
    let input_elem = env.params.input;
    if (!input_elem) return;

    if (!input_elem.dom) return;
    
    // фишка - оказывается надо чтобы в этом svg был явно указан xmlns="http://www.w3.org/2000/svg" 
    // F-NEED-EXPLICIT-XMLNS-IN-SVG-TAG
    input_elem.dom.setAttribute("xmlns","http://www.w3.org/2000/svg");

    let txt = input_elem?.dom?.outerHTML;
    env.setParam("output",txt);
  `;
};

// идея что оно получает input и команду apply?
// или просто input? и как поменялся - выдаем файл?

// downloads specified file to a users browser
// inputs: 
//  * input - text content,  
//  * filename - filename
// when input changed, a new file is downloaded

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
      if (!input || input.length == 0) return;

      download( input, env.params.filename || "file")
    });
  `;
};