load files="lib3dv3 csv params io alfa.js gui render-params df
            scene-explorer-3d
            ";
//load files="gui";

mainparams: {
  cb1: param_combo values=["TSNE","MDS"];
  f1:  param_file value=@map->output {
             map: mapping 
                    values=["http://viewlang.ru/assets/majid/2021-11/TSNE_output.csv",
                            "http://viewlang.ru/assets/majid/2021-11/MDS_output.csv"]
                    input=@cb1->index;
  }
};

// робит dat: load-file file=@f1->value | parse_csv | rescale_rgb;
dat: load-file file=@mainparams->f1 | parse_csv | rescale_rgb;

register_feature name="rescale_rgb" {
  df_div column="R" coef=255.0 | df_div column="G" coef=255.0 | df_div column="B" coef=255.0;
};

debugger_screen_r;
 
mainscreen: screen auto-activate padding="1em" {
  column style="z-index: 3; position:absolute;" {
    dom tag="h3" innerText="Параметры" style="margin-bottom: 0.3em;";
    column gap="0.5em" padding="0em" {
      //objects-guis objects="** @showparams";
      //objects-guis objects="** @showparams";
      render-params input="@mainparams";
    };

    text text="test float";
    i1: input_float value=1555;
    console_log text="input value" input=@i1->value;

    column gap="0.5em" padding="0em" {
      dom tag="h4" innerText="Визуальные объекты";
      
      repeater model=@find_objs->output {
        column {
          button text=@btntitle->output cmd="@pcol->trigger_visible";
          /*
          render-params object=@..->modelData;

          btntitle: compute_output object=@..->modelData code=`
              return env.params.object?.ns.name;
            `;
            */

          
          pcol: column {
            render-params object=@../..->modelData;
            btntitle: compute_output object=@../..->modelData code=`
              return env.params.object?.ns.name;
            `;
          }
          
        };
      };

      find_objs: find-objects pattern="** myvisual";

      cb1: checkbox text="Show text";
    };

  };

  v1: view3d style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2";
  v2: view3d style="position: absolute; right: 20px; bottom: 20px; width:500px; height: 200px; z-index: 5;";

/*
  scene_explorer_graph input=@/ 
  | 
  scene-explorer-3d
    style="position: absolute; right: 20px; bottom: 220px; width:500px; height: 200px; z-index: 5;
           background-color: blue;";
*/           
    
  
  r1: render3d 
      bgcolor=[0.1,0.2,0.3]
      target=@v1
  {
    camera3d pos=[0,0,100] center=[0,0,0];
    orbit_control;

    @dat | linestrips myvisual;

    //text3d text="Privet Mir!" myvisual color=[1,0.2,0.3];
    // text3d_many lines=["Privet Mir!","Ya rad"] myvisual color=[1,0.2,0.3] positions=[-20,0,0,20,10,0];

    @dat | df_filter code=`(line) => line.TEXT?.length > 0` | text3d myvisual size=0.1 visible=@cb1->value; // color=[0,1,0];
  };

  render3d bgcolor=[1,0,0] 
    camera=@r1->camera
    target=@v2
    // input=@r1->scene // scene= почему-то не робит
  {
    //camera3d pos=[0,100,0] center=[0,0,0];
    orbit_control;

    @dat | points radius=0.15 myvisual;
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