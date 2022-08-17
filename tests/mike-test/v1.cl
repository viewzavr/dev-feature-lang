/* пример рисует на экране трехмерную сцену, наполняя ее объектами из json-файла
   и ряд кнопок, при нажатии на которые объекты сцены меняют цвет.
*/

screen {
  col: row {
    button "make red" c=[1,0,0];
    button "make blue" c=[0,0,1];
    button "make white" c=[1,1,1];
  };

  @col | get_children_arr | get-cell "click" | c-on (make-func { |btn|
    @scene3d | get_children_arr | get-cell "color" | set-cell-value @btn->c;
  });

  v: view3d;

  render3d target=@v {
    let content = (load_file "data.json" | parse_json);
    @content | repeater { |rec|
      create-object @rec->TYPE {{ x-set-params __from=@rec }};
    };
  };
};
