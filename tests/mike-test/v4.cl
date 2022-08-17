/* пример рисует на экране трехмерную сцену, 
   наполняя ее объектами с координатами из json-файла,
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

  let dat = (load_file "data.json" | parse_json);
  scene: show3d {
    points positions=@dat->pt_coords_1;
    points positions=@dat->pt_coords_2;
    lines positions=@dat->ln_coords;
  };
};