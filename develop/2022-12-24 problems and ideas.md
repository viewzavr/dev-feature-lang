2022-12-24 problems.md

добавлять аттрибуты верхнего уровня в scope

----------
монстрообразно выглядит:

button "Удалить" 
  on_click=(m-lambda [[[
    (obj) => { console.log('removing',obj); obj.removedManually = true; obj.remove(); }
  ]]] @co->input?)

понять что тут к чему и почему. идеи
- убрать on_click перейти на reaction
- понять отчего конкретно каждый монстр  

------
удивительно что uni не сохраняет ссылок когда вызывает make.. что она делает тогда?

---
