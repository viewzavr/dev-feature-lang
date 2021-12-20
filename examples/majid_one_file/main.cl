load files="lib3dv3 csv params io gui render-params df misc";

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

  column padding="1em" style="z-index: 3; position:absolute;"{
    if condition=@pq->output {
      column gap="0.5em" {
        dom tag="h3" innerText="Визуальные объекты" style="margin:0;";
        render-guis objects=@find_objs->output;
        find_objs:  find-objects pattern="** myvisual";
      };
      text text="Укажите файл в параметре csv_file" style="color:red";
    }
  };

  view: view3d style="position: absolute; width:100%; height: 100%; z-index:-2";

};

//////////////////////////////////////

register_feature name="rescale_rgb" {
  df_div column="R" coef=255.0 | df_div column="G" coef=255.0 | df_div column="B" coef=255.0;
};