class как в html попробовать.

some-obj class="alfa beta gamma"
// ну и варинат с массивом
other-obj {
  append-class "gamma teta"
}

find-by-class "gamma"
find-by-class "teta sigma"
// ну это кстати реально как фичи...

ну и далее напрашивается уже язык селекторов полноценный как в css.
а сейчас мы умеем искать по id, по фиче, по набору фич в поддереве id..

---
но с другой стороны, не мудрствуя лукаво:
find-by-class "red" | assign-params color=[1,0,0]

ну то есть эта некая история про модификаторы.
здесь класс это критерий поиска,
а assign-params уже модификатор.
хм.