load files="csv params io gui render-params df scene-explorer-3d misc svg";

screen auto_activate {
  text text="Hello";

  свггруппа занять_родителя {
    штука1: 
       абстракция_номер_2;

    абстракция_номер_2 {{ 
      справа от=@штука1; 
    }};

    svg tag="circle" dom_cx=50 dom_cy=50 dom_r=30 dom_fill="red" dom_stroke="blue" dom_stroke-width="5";           

    /*
    svg tag="rect" dom_x=50 dom_y=50 dom_width=30 dom_height=120 
           dom_fill="red" dom_stroke="blue" dom_stroke-width="5";
    */           
  };

};


debugger_screen_r;

//новое имя="абстракция_номер_2" {
register_feature name="абстракция_номер_2" {  
  свггруппа подсчет_размеров {
    абстракция_номер_1 икс=0 игрек=0 {{ 
      сверху от=@кмал; 
      горизонталь как=@кмал; 
    }};
    кмал: квадрат_малевича икс=100 игрек=100 ширина=300;    
  };
};

register_feature name="абстракция_номер_1" {
 свггруппа подсчет_размеров {
    круг1: круг   цвет="зеленый" 
                  контур="orange"
                    ширина_контура=5
                  центр_икс=50
                  центр_игрек=130
                  радиус=30
                  глазик;

    п1: прямоугольник цвет="голубой" ширина=150 высота=10 обводка="серый"
        {{ справа от=@круг1; 
           вертикаль как=@круг1; 
        }};

    круг цвет="#f5f5dc" радиус=15 {{ справа от=@п1; вертикаль как=@п1; }};

      //круг цвет="черный" радиус=5 {{ вертикаль как=}}

    квадрат ширина=50 {{ снизу от=@п1; горизонталь как=@п1; }};
  }
};

/// квадрат_малевича
register_feature name="квадрат_малевича" {
  гр: свггруппа высота=@.->ширина {
    квчер: квадрат цвет="черный" ширина="100%" высота="100%" {{
      clicked {
        setter target="@квчер->цвет" value="синий";
      };
    }};;
    квбел: квадрат цвет="белый" ширина="40%" икс="40%" игрек="40%" {{
      clicked {
        setter target="@квбел->цвет" value="красный";
      };
    }};
  };
};

/*
register_feature name="круг-с-глазом" {
   env {
      кр1: круг;
      круг цвет="черный" {{ вертикаль как=@кр1; горизонталь как=@кр1; }}
   }
}
*/

register_feature name="глазик" {
   родитель: {
      круг цвет="черный" {{ вертикаль как=@родитель; горизонталь как=@родитель; }}
   }
}


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
      "черный":"black"
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

