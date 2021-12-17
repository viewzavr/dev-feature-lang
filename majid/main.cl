load files="lib3dv2 csv params io alfa.js gui render-params";
//load files="gui";

mainparams: {
  cb1: combo 
       values=["http://viewlang.ru/assets/majid/2021-11/TSNE_output.csv",
               "http://viewlang.ru/assets/majid/2021-11/MDS_output.csv"];
  f1:  file_param value=@cb1->value;
};

// робит dat: load-file file=@f1->value | parse_csv | rescale_rgb;
dat: load-file file=@mainparams->f1 | parse_csv | rescale_rgb;

register_feature name="rescale_rgb" {
  df_div column="R" coef=255.0 | df_div column="G" coef=255.0 | df_div column="B" coef=255.0;
};
 
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

mainscreen: screen auto-activate padding="1em" {
  dom tag="h3" innerText="Параметры" style="margin-bottom: 0.3em;";
  column gap="0.5em" padding="0em" {
    //objects-guis objects="** @showparams";
    //objects-guis objects="** @showparams";
    render-params input="@mainparams";
  };
  
  r1: render3d 
     bgcolor=[0,1,0]
     style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2"
  {
    camera3d pos=[0,100,0] center=[0,0,0];
    orbit_control;

    @dat | linestrips;
  };

  render3d bgcolor=[1,0,0] style="position: absolute; right: 20px; bottom: 20px; width:30%; height: 35%; z-index: -1;" 
  //camera=@r1->camera
  input=@r1->scene // scene= почему-то не робит
  {
    camera3d pos=[0,100,0] center=[0,0,0];
    orbit_control;
  };
  
};

/*
    text text="PARAMETERS";
    edit-params input=@dasparams;
    text text="SCENE CODE";
    edit-params input="/";
*/

// @dat | linestrips;

//call cmd="@mainscreen->activate";

/*
action1: setparam target="@thecsv->file" value="TSNE_output.csv";
action2: setparam target="@thecsv->file" value="MDS_output.csv";
button text="TSNE_output.csv" cmd="@action1->perform";
    button text="MDS_output.csv" cmd="@action2->perform";
*/


/*
set Y=(log column="Y")

@thecsv | rescale_rgb;

feature name="rescale_rgb" {
  div column="R" value=255.0
  |
  div column="G" value=255.0
  |
  div column="B" value=255.0;
};
*/

//register_package name="df-utils" url="alfa.js";
//register_compolang name="sigma" url="sigma.txt";


//startq: slider min=0; max=
// | slice stat=@startq.value

/*
action1: action setparam target="@thecsv->file" value="TSNE_output.csv";
action2: action setparam target="@thecsv->file" value="MDS_output.csv";

button text="TSNE_output.csv" cmd=(setparam target="@thecsv->file" value="TSNE_output.csv");
button text="MDS_output.csv" cmd=(setparam target="@thecsv->file" value="MDS_output.csv");

    button text="TSNE_output.csv" cmd="@action1->perform";
    button text="MDS_output.csv" cmd="@action2->perform";
*/

/*
default_gui;

left_gui text="PARAMETERS" {
cb1:  
  param combo values=["TSNE_output.csv","MDS_output.csv"];

user_file: 
  param file value=@cb1->value;

s1:
  param slider min=0 max=100 step=10;
}

right_gui text="PARAMETERS" {
};

right_gui edit-objects path="** $extras";

*/