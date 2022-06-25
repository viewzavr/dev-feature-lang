load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

//feature "some-env" { |alfa, beta, gamma|};

// в этом случае похоже надо заворачивать позиционные аргументы...
// а функция вроде как и не нужна
// так стоп. для этого случая это непригодно.
// потому что конкретно вот feature - она опирается на параметры окружения которые и передает в свою первую фичу
// такая вещь пригодна для тех, кто готов управлять параметрами, например репитером.

/*
feature "crect" { |color|
  dom style="width:100px; height: 100px; border: 1px solid white;" dom_style_background=@color;
};
*/

feature "crect" {
  dom style="width:100px; height: 100px; border: 1px solid white;" dom_style_background=@.->0;
};

test1: alfa={ |color| text "privet" color=@color; }
       beta={ |color| rect color=@color; }

screen auto_activate {
  row {
    text text="result =";
    //insert_children input=@.. list=@test1->beta;
    //insert_children input=@.. list={ crect "red" };
    
    list "red" "green" "blue"| repeater2 { |input|
      crect @input;
    };
  };
};

//debugger_screen_r; // hotkey='s';