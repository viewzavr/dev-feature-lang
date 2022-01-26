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
// performs only when `apply` cmd is called
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

