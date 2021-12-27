load files="lib3dv3 csv params io gui render-params df misc";

pq:  get_query_param name="csv_file";
dat: load-file file=@pq->output | parse_csv | rescale_rgb;

/// рендеринг 3D сцены

render3d bgcolor=[0.1,0.2,0.3] target=@view
{
    orbit_control;
    camera3d pos=[0,0,40] center=[0,0,0];

    @dat | linestrips;

    @dat 
      | df_filter code="(line) => line.TEXT?.length > 0"
      | text3d size=0.2 visible=@cb1->value color=[0.9, 0.9, 0.9 ];
};

/// интерфейс пользователя gui

screen auto-activate {

  column padding="1em" style="z-index: 3; position:absolute;"{
    if condition=@pq->output {
      column gap="0.5em" padding="0.5em" style="background-color: rgba(255 255 255 / 45%)" {
        dom tag="h3" innerText="Visual settings" style="margin:0;";
        cb1: checkbox text="Show titles";
      };
      text text="Please specify path to CSV file in <b>csv_file</b> query parameter." style="color:red";
    }
  };

  view: view3d style="position: absolute; width:100%; height: 100%; z-index:-2";

};

//////////////////////////////////////

register_feature name="rescale_rgb" {
  df_div column="R" coef=255.0 | df_div column="G" coef=255.0 | df_div column="B" coef=255.0;
};