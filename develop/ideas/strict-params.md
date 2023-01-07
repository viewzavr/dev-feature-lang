апарте codea - строгие параметры. т.е. сказать объекту что тебе можно параметры только из списка.
и равно как on - тоже, события ток из списка.

предполагается что это
а) добавит нам контроль ошибок когда пишем в неверный параметр
б) разгрузит описание объектов, а то все в куче в головном объекте это как-то тяжело
(но мб это просто мне си++ привичку привил)

В список добавлять в список как-то так:

 add-param "name" [value]
   {{ check-type "string" }}
   {{ gui "string" "tab1" }}

Например:

feature "data-load-files" {
  qqe: data-artefact title="Загрузка файлов" {
    add-param "initial_mode" 1
    add-param "url" ""
    add-param "files" []
    add-param "output" (m-eval ..... )

    add-param "gui" {
      column ~plashka {

        render-params-list object=@qqe list=["title"];

        param_field name="Источник" {

          column {
            render-params-list object=@qqe list=["src"];

            show-one index=@qqe->src style="padding:0.3em;" {
              column { render-params-list object=@qqe list=["url"];; };
              column { render-params-list object=@qqe list=["files"];; };
              column { files; };
            };
          };
        };

      };
    }


  }
}


вроде и неплохо.

ну и еще можно add-params и оно уже почти как let. но получится что - прицепить гуи или там проверку типов - это уже отдельно надо делать. т.е. {{}}-фичами не прицепиться. но может оно и хорошо.

feature "data-load-files" {
  qqe: data-artefact title="Загрузка файлов" {

    define-gui src={ gui-string } files={ gui-files } src={ gui-switch ["URL","Файл с диска","Папка"] }

    add-params 
      initial_mode=1
      url=""
      files=[]
      src=0
      output=(m_eval "(a,b,index) => {
        if (index == 0) {
          if (a) {
             let sp = a.split('/');
             if (sp.at(-1) == '') sp.pop();
             return [{name:sp.at(-1),url:a}];
          }
          return [];
        }
        return b;
        }" @qqe->url? @qqe->files? @qqe->src allow_undefined=true)

      gui={
        column ~plashka {

          render-params-list object=@qqe list=["title"];

          param_field name="Источник" {

            column {
              render-params-list object=@qqe list=["src"];

              show-one index=@qqe->src style="padding:0.3em;" {
                column { render-params-list object=@qqe list=["url"];; };
                column { render-params-list object=@qqe list=["files"];; };
                column { files; };
              };
            };
          };

        };
      } 
};

ну и это можно вроде и группировать неплохо:

define-gui name={ string }
add-param name="privet"

/////
но и кстати также вариант:
add-param one=1 two=2 type="int" type={ int {{ range min=0 max=10 }} } 
    gui={ slider min=0 max=10 }
и типа эта запись gui будет прицеплена к обоим параметрам. это неплохо.

а в целом нам получается что-то такое не помешает для определения структуры параметров.

и кстати: add-param .... gui={ | in out | ...... }
