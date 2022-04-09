load files="lib3dv3 csv params io gui render-params df scene-explorer-3d";

screen auto-activate
{

  column {

  text "рыба";

  text text="ела";

  button "курица" {
  };

  text @alfa->foo;

  alfa: foo=15;

  beta: slider;

  text @beta->value;

  };
  
  text (join "рубероид" (30 + 3) @alfa->foo @beta->value with=" - " (join "краси" "вое" ));
  
  //{{ onevent name="param_0_changed" code=`env.host; debugger;`; }};
  // следующее задание - покороче вот это делать
  
  if (@beta->value < 15) {
    text " и нарядное";
  };
};

debugger_screen_r;

register_feature name="join" code=`
  env.on("param_changed",(name) => {
    if (name == "output") return;
    compute();
  });
  
  function compute() {

    let count = env.params.args_count;
    let arr = [];
    for (let i=0; i<count; i++)
      arr.push( env.params[ i ] );
    let res = arr.join( env.params.with || "" ); // по умолчанию пустой строкой
    env.setParam("output",res );
  };
  
  compute();
`;

// кстати идея - а вызвать бы тут метод arr.join как-то.. а то вон какой длинный код 
// а так бы мостик соорудить - аргументы в массив в допом ключ..

// да и операцию + можно было бы выразить через это.. типа попарный reduce..

register_feature name="+" code=`

  env.on("param_changed",(name) => {
    if (name == "output") return;
    compute();
  });
  
  function compute() {
    
    let count = env.params.args_count;
    let acc = env.params[0];
    for (let i=1; i<count; i++)
      acc = acc + env.params[ i ];
    env.setParam("output",acc );
  };
  
  compute();
`;
// но вообще + и join это какие-то совместные вещи.. я к тому что вроде как + может выполнять join функцию.. но тогда без with..

register_feature name="<" {
  eval code="(a,b) => a<b";
};

register_feature name=">" {
  eval code="(a,b) => a>b";
};