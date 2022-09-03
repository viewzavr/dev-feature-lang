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
    
    b: button "click";
    @b | get-cell "click" |  c-on (make-func { @arr->cell | set-cell-value [3,2,3] });
  };
  
};
