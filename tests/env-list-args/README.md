Here we test an ability to pass env lists as args. Example:
```
  env arg1={ env; env; env; } arg2={ env... }
```
Here `arg1` will have value with a list of environments.
Same for `arg2`.

1. Нам нужна функция deploy для активации этих переданных аргументов.
2. Надо что-то делать с lexicalParent.
3. Надо чтобы deploy умел вставлять не только в фичу, но и в аттачед-фичи.