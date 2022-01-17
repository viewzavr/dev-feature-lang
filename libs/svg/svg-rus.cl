/////////////// перевод цветов на русский язык

register_feature name="translate_color" {
  compute code=`
    let colors = {
      "красный":"red",
      "синий":"blue",
      "зеленый":"green",
      "фиолетовый":"purple",
      "оранжевый" :"orange",
      "голубой":"cyan",
      "серый":"grey",
      "белый":"white",
      "черный":"black",
      "коричневый":"brown"
    }; 
    // todo может быть стоит найти какую-то библиотеку цветов?

    // такая идея = вот мы эту таблицу тут копим. а хотелось бы уметь еще доп-ом ее распределенно копить
    // итого нужна операция "добавить-в-таблицу( цветов, новые-записи )"
    
    env.onvalue("input",(c) => {
      
      let res = colors[c] || c;
      env.setParam("output",res);
    })
  `;
};

////////////// перевод примитивов и их параметров на русский язык

register_feature name="новое" {
  register_feature name=@.->имя;
};

register_feature name="группа" {
   group;
};

register_feature name="занять_родителя" {
   fill_parent;
};

register_feature name="свггруппа" {
   svggroup
       x=@.->икс
       y=@.->игрек
       z=@.->зет
       width=@.->ширина
       height=@.->высота
       ;
};

register_feature name="круг" {
   circle
       fill=(translate_color input=@.->цвет)
       stroke=(translate_color input=@.->цвет_контура)
       цвет_контура="черный"
       cx=@.->центр_икс
       cy=@.->центр_игрек
       r =@.->радиус
       stroke_width=@.->ширина_контура
       ;
};

register_feature name="прямоугольник" {
   rect
       fill=(translate_color input=@.->цвет)
       stroke=(translate_color input=@.->цвет_контура)
       цвет_контура="черный"
       x=@.->икс
       y=@.->игрек
       width=@.->ширина
       height=@.->высота
       stroke_width=@.->ширина_контура
       ;
};

register_feature name="квадрат" {
  прямоугольник высота=@.->ширина цвет="красный";
};

register_feature name="справа" {
  right to=@~->от;
};

register_feature name="слева" {
  left to=@~->от;
};

register_feature name="сверху" {
  top to=@~->от;
};

register_feature name="снизу" {
  bottom to=@~->от;
};

register_feature name="вертикаль" {
  y_align to=@~->как;
};

register_feature name="горизонталь" {
  x_align to=@~->как;
};

register_feature name="подсчет_размеров" {
  compute_width_height;
};

