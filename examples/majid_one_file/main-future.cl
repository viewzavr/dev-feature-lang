load files="lib3dv2 csv params io gui render-params";

pq:  get_query_param name="csv_file";
dat: load-file file=@pq->output | parse_csv | rescale_rgb;

/// рендеринг 3D сцены

render3d bgcolor=[0.1,0.2,0.3] target=@view
{
    orbit_control;
    camera3d pos=[0,100,0] center=[0,0,0];

    @dat | linestrips myvisual;
};

/// интерфейс пользователя gui

screen auto-activate {

  column style="z-index: 3; position:absolute;"{
    if condition=@pq->output {
      column gap="0.5em" {
        dom tag="h4" innerText="Визуальные объекты";
        render-guis objects=@find_objs->output;
        find_objs:  find-objects pattern="** myvisual";
      }
      text text="Укажите файл в параметре csv_file" style="color:red";
    }
  };

  view: view3d style="position: absolute; width:100%; height: 100%; z-index:-2";

};

//////////////////////////////////////

register_feature name="df_div" code=`
  env.onvalue("input",process);
  env.onvalue("coef",process);
  env.onvalue("column",process);

  function process() {
    var df = env.params.input;
    if (!df || !df.isDataFrame || !df[ env.params.column ] || !env.params.coef) {
      env.setParam("output",[]);
      return;
    }
    df = df.clone();
    df[env.params.column] = df[env.params.column].map( v => v / env.params.coef );
    env.setParam("output",df);
  }
`;

register_feature name="rescale_rgb" {
  df_div column="R" coef=255.0 | df_div column="G" coef=255.0 | df_div column="B" coef=255.0;
};

register_feature name="get_query_param" code=`
    function getParameterByName(name) {
      name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
      var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
        results = regex.exec(location.search);
      //return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
      return results === null ? null : decodeURIComponent(results[1].replace(/\+/g, " "));
    }

    env.onvalue("name",(name) => {
      var v = getParameterByName(name);
      env.setParam("output",v);
    })  
`;