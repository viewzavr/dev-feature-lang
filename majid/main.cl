load files="lib3d csv params alfa.js";

dasparams: showparams {
  cb1: combo values=["TSNE_output.csv","MDS_output.csv"];
  f1:  file  value=@cb1->value;
};

dat: load-csv file=@f1->value | rescale_rgb;

register_feature name="rescale_rgb" {
  df_div column="R" coef=255.0 | df_div column="G" coef=255.0 | df_div column="B" coef=255.0;
};

 
register_feature name="df_div" code=`
  env.onvalue("input",process);
  env.onvalue("coef",process);
  env.onvalue("column",process);

  function process() {
    var df = env.params.input;
    if (!df || !df.isDataFrame || !df[ env.params.column ] || !env.params.coef) return;
    df = df.clone();
    df[env.params.column] = df[env.params.column].map( v => v / env.params.coef );
    env.setParam("output",df);
  }
`;

mainscreen: screen auto-activate {
  column gap="0.5em" padding="1em" {

    objects-guis objects="** @showparams";
    //objects-guis objects="** @showparams";

  };
  render3d {
    @dat | linestrips;
  };
  render3d {
    //@dat | points;
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