# Здесь пишутся мелкие задачи возникающие перед языком

## Пайп мог бы пропускать команды в head
сейчас такое не работает:
```
  button text="get as svg file" style="position:absolute; z-index:2;" {
      generate_svg input=@svg1 | download_file_to_user filename="kartina.svg";
  };
```
и приходится:
```
  button text="get as svg file" style="position:absolute; z-index:2;" {
      sv1: generate_svg input=@svg1;
      download_file_to_user filename="kartina.svg" input=@sv1->output;
  };
```

## Фича active у 3д-отладчика и у генератора графа должна быть выписана явно
не "вписана" а сделана так, что если возникает желание ее поправить,
то не надо искать ее в кодах (размазанно) а сразу ясно куда идти.
это наше железнейшее требование, без него проект теряет половину смысла.
