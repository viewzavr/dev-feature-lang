Тестируем такую фичу:
```
  env arg1=( a: env; b: env; c: compute-something @a @b )
```
Здесь arg1 должен нами присвоиться значение c->output.
