load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

let arr=[1,2,3,4,5];

screen auto_activate {
  column gap="0.2em" {
    text "privet";
    @arr | repeater { |input index|
      row {
        text "item";
        text @index;
        text "=";
        text @input;
      };  
    };
    
    b: button "click" on_click=(make-func { @arr->cell | set-cell-value [3,2,3] });

    // этот метод остается:
    //find-objects-bf .... | get-cell "click" | c-on ...;    
    
    // это можно будет сделать..
    //button "click2" on_click="(arg) => alert(15);";
    // плюс интрига года но это уже ловить записи, парсить.. а этого хотелось бы избежать..
    //button "click2" on_click="(arg) => arr = [3,2,3];";
    // ну или хотя бы тогда:
    //button "click2" on_click="(arg) => arr.set( [3,2,3] );";
    // это в принципе можно вместе с with выполнять.. ну придется договориться тогда что в scope сидят ячейки, set get им..
    // button "click2" on_click="(arg) => console.log( arr.get() );";
    // хотя это можно попробовать кстати на m_eval с каким-то флагом типа with_scope=true ну или фичей {{ with_scope }}

  };
  
};
