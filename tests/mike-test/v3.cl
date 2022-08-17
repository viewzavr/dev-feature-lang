/* пример рисует на экране трехмерную сцену, наполняя ее объектами из json-файла
   и ряд кнопок, при нажатии на которые объекты сцены меняют цвет.
*/

screen {
  r: row {
    button "make white" c=[1,1,1];
    button "make blue" c=[0,0,1];
    button "make red" c=[1,0,0];
  };

  @r->children | get-cell "click" | c-on (make-func { |btn|
    @scene->children | get-cell "color" | set-cell-value @btn->c;
  });

  scene: show3d {
    load_file "data.json" | parse_json | repeater { |rec|
      create-object @rec->TYPE modifiers={x-set-params __from=@rec };
    };
  };
};