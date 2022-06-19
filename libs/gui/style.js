// предназначение - быть экраном

export function setup( vz, m ) {
  vz.register_feature_set( m );
}

export function add_css_style( env ) {
  var styleSheet = document.createElement("style");
  styleSheet.type = "text/css"; 
  document.head.appendChild(styleSheet)
  env.onvalue(0,(v) => env.setParam('content',v));
  env.onvalue("content",(styles) => {
    styleSheet.textContent = styles;  
  });
}

export function add_css_style_href( env ) {
  var styleSheet = document.createElement("style");
  styleSheet.type = "text/css"; 
  document.head.appendChild(src)
  env.onvalue("file",(src) => {
    styleSheet.href = src;
  });
}

// но вообще, что-то типа dom tag="style" dom_textContent=``;
// или даже
// dom tag="style" dom_type="text/css" dom_textContent=``;
// и тогда эти фичи будут не нужны..
// и это было бы наверное даже офигеть как удобно, так-то.. не нужны вообще никакие html-вещи
// ну кроме как для обработки обратных значений от них..
// dom( tag="style" type="text/css" textContent=`` );
// но тут мы видим вариант, который я только что предлагал для screen.env("some-named-env").feature(...)
// и это тупняковато..
