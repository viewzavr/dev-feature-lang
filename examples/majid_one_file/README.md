
***** Visalization task

* Visualize CSV as following.
* CSV should be specified in query param.

****** Solution

Входной файл должен быть указан в query-строке в параметре csv_file

Пример запуска:
http://127.0.0.1:8080/vrungel/index.html?src=http://127.0.0.1:8080/vrungel/examples/majid_one_file/main.cl&csv_file=http://viewlang.ru/assets/majid/2021-11/TSNE_output.csv

****** Setup and Embedding

Task: use 100% local installation and show it inside IFRAME.

1. Download `Vrungel` project as following:
```
git clone https://github.com/viewzavr/vrungel.git
cd vrungel
git submodule update --init --recursive
```

2. Create an IFRAME code as following.

```
<h1>Hello world!</h1>

<iframe
  width="640" height="480"
  src="/vrungel/index.html?src=/vrungel/examples/majid_one_file/main.cl&csv_file=http://viewlang.ru/assets/majid/2021-11/TSNE_output.csv"
  >
</iframe>
<br/>
<a target="_blank" href="/vrungel/index.html?src=/vrungel/examples/majid_one_file/main.cl&csv_file=http://viewlang.ru/assets/majid/2021-11/TSNE_output.csv">Fullscreen</a>

```

Here in src attribute:
* "/vrungel/" is a web path to Vrungel project.
* `src` parameter is a path to Vrungel script `main.cl` which describes visualization.
* `csv_file` parameter is a path to CSV file according to specs.


************ Testing.

For testing, there is (test-iframe.html) file.

* Start web server so vrungel is on "/vrungel" path.
> For example using nodejs: `http-server --cors`

* Open http://127.0.0.1:8081/vrungel/examples/majid_one_file/test-iframe.html
