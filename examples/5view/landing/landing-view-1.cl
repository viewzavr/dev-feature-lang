// визуальный процесс "Возвращение"
// надо с терминами разобраться. это даж не визуальный процесс а процесс вида отображения.
// причем это часть вида отображения, хоть и существенная. потому что потом мы их комплексируем всяко.
// ну ладно главное нАчать

feature "landing-view-1" 
{

  view: visual_process title="Возвращение" 

  scene3d=@scene->output
  scene2d=@screen_space->output

  gui={
	
  	column plashka {
      text "";
      render-params  input=@timeparams;
    };

    collapsible text="Файл данных"
    {
		column plashka {
		    text "Укажите текстовый файл с данными";
		    render-params  input=@fileparams;
	    };
	};

    collapsible text="Параметры отображения"
    {
        render-params  input=@mainparams plashka;
    };

	render_layers title="Визуальные объекты" 
           root=@view
           items=[ { "title":"Объекты данных", 
                     "find":"datavis",
                     "add":"linestr",
                     "add_to": "@scene->."
                   },

                   {"title":"Статичные",
                    "find":"staticvis",
                    "add":"axes",
                    "add_to": "@scene->."
                   },

                   {"title":"Текст",
                    "find":"screenvis",
                    "add":"curtime",
                    "add_to":"@screen_space->."
                   }
                 ]
           ;    


  }

  {

	timeparams: {
	  time_index: param_slider
	           min=0 
	           max=(@internal_columns_dat->output | get "length" | @.->input - 1)
	           step=1 
	           value=@timeparams->time
	           ;

	      time: param_combo 
	           values=(@internal_columns_dat | df_get column="T")
	           index=@timeparams->time_index
	           ;
	};   	

	fileparams: {
	  //f1_info: param_label "Укажите текстовый файл с данными";
	  f1:  param_file value="https://viewlang.ru/assets/other/landing/2021-10-phase.txt";
	  lines_loaded: param_label (@loaded_data | get name="length");

	  loaded_data: load-file file=@fileparams->f1
	         | parse_csv separator="\s+";

	  // on изменение в выборе файла - перейти в вид1
	  // но опять же - при старте программы это изменение тоже происходит.. 

	};


	data_compute:
	{

	  internal_columns_dat: @loaded_data | df_set X="->x[м]" Y="->y[м]" Z="->z[м]" T="->t[c]"
	                RX="->theta[град]" RY="->psi[град]" RZ="->gamma[град]"
	              | df_div column="RX" coef=57.7
	              | df_div column="RY" coef=57.7
	              | df_div column="RZ" coef=57.7;

	  dat: @internal_columns_dat | df_div column="Y" coef=@mainparams->y_scale_coef;

	  dat_prorej: @dat | df_skip_every count=@mainparams->step_N;

	  dat_cur_time: @dat       | df_slice start=@timeparams->time_index count=1;

	  dat_cur_time_orig: @loaded_data | df_slice start=@timeparams->time_index count=1; 	              

	};

	mainparams: 
	  {

	    see_lines: param_label value=(@_dat | get name="length");

	    // todo исследовать time: param_combo values=(@dat | df_get column="T");

	    y_scale_coef: param_slider min=1 max=200 value=50;

	    step_N: param_slider value=10 min=1 max=100;
	  };

  find-objects-bf root=@scene features="datavis" 
      | x-modify { 
      x-set-params
       data_link_values = ["","@dat->output","@dat_prorej->output","@dat_cur_time->output"]
       data_link_titles = ["","Траектория","Прореженная","Текущее время"]
       ;
    };

  find-objects-bf root=@screen_space features="screenvis" 
      | x-modify { 
      x-set-params
       time=@timeparams->time
       df=@dat_cur_time_orig->output
       ;
      };

    scene: node3d {
        linestr 
             input_link="@dat->output";

        ptstr radius=2 
             input_link="@dat->output";

        models 
             input_link="@dat_cur_time->output";

        axes;
        pole;
        kvadrat;
        stolbik;
	};  	

    // ну вот... как бы это.. а мы бы хотели...

    screen_space: dom {

    };
    /*
	insert_children input=@view1->scene2d list={
		text "привет";
	};	
	*/

  };
	

};

///////////////////////////
///////////////////////////
/////////////////////////// наполнение

linestr: feature {
  main: linestrips datavis 
     gui={ 
       render-params input=@main;
      };
};

ptstr: feature {
  main: points datavis gui={ render-params input=@main };
};
    
    // вход input это dataframe
models: feature {
    root: node3d datavis gui={ render-params input=@root  }
          {
            param_slider name="radius" min=1 max=10 value=3;
            param_color  name="hilight_color" value=[0,0,0];
            param_label  name="count" value=(@rep->input | get name="length");

            @root->input | df_slice count=100 | df_to_rows | rep: repeater {
              gltf:
                render_gltf
                src="https://viewlang.ru/assets/models/Lake_IV_Heavy.glb" 
                positions=(@gltf->input | df_combine columns=["X","Y","Z"])
                rotations=(@gltf->input | df_combine columns=["RX","RY","RZ"])
                
                {{ scale3d coef=@root->radius ; }}
                color=@root->hilight_color;
            };
        };
};

feature "axes"  {
       main: axes_box size=100 staticvis; 
};

feature "pole" {
        main: mesh gui={ render-params input=@main; } staticvis
          positions=[
           -1000,-0.5,-1000,  1000,-0.5,-1000, -1000,-0.5,1000,
           -1000,-0.5,1000,   1000,-0.5,-1000,  1000,-0.5,1000
          ]
          color=[0,0.25,0]
        ;
};

feature "setka" {
        main: lines gui={ render-params input=@main; } staticvis
          color=[0.7, 0.7, 0.8]
          positions=(eval code="() => {
            let step=100;
            let k = 10;
            let d = k*step;
            let acc=[];
            for (let i=-k; i<=k; i++) {
              acc.push( i*step, 0, -d );
              acc.push( i*step, 0, +d );
            };
            for (let i=-k; i<=k; i++) {
              acc.push( -d, 0, i*step );
              acc.push( +d, 0, i*step );
            };
            return acc;
          }")
        ;
};

feature "kvadrat" {
        main: mesh gui={ render-params input=@main; } staticvis
          positions=[
           -30,0,-30, 30,0,-30,  -30,0,30,  
           -30,0,30,  30,0,-30,  30,0,30
          ]
          color=[0.4, 0.4, 0.4]
        ; // todo: polygon offset modifier
    };

feature "stolbik" {
      main: 
        lines gui={ render-params input=@main; } staticvis
          positions=(compute_output h=@.->h code=`
            return [-30,0,-30, -30, env.params.h,-30 ]
          `)
          color=[1,1,1] 
          {
            param_slider name="h" min=5 max=100 value=5;
          };
    };


/////////////////////////////// надписи для экрана
// todo опора на vroot
// 

// параметр: time
feature "curtime" {
  sv: screenvis dom tag="h2" style="color: white; margin: 0;"
        innerText=(eval @sv->time code="(t) => 'T='+(t || 0).toFixed(3)");
};

// параметр: df - датафрейм для вывода данных. выводится 1я строка.
feature "allvars" {
  sv: screenvis 
        dom style="color: white; display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
                   min-width: 400px; font-size: larger"
        innerHTML=(eval @sv->df code="(df) => {
           
           let str='';
           df ||= {};
           
           for (let n of (df.colnames || [])) {
             let val = df[n][0];
             if (isFinite(val)) {
                 val = val.toFixed(3);
                 str += `<span>${n}=${val}</span>`;
             }
           }
           
           return str;
        }");
};

// параметр: df - датафрейм для вывода данных. выводится 1я строка.
feature "selectedvars" {
  sv: screenvis       
        dom 
        style="color: white; display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
                   min-width: 300px; font-size: larger"
        innerHTML=@qq->output 
        gui={ render-params input=@selected; } 
        {

          selected: gui_title="Выбрать" 
             {{ 
             x-on name="param_changed" cmd="@qq->recompute";
             x-on name="gui-added" cmd="@qq->recompute";
             }}
          {

              @sv->df | get name="colnames" | repeater 
              {
                param_checkbox name=@.->input value=true;
              };

              qq: eval @sv->df @selected code="(df,selected) => {
               let str='';
               df ||= {};
               if (!selected) return '';
               
               for (let n of (df.colnames || [])) {
                 let f = selected.getParam( n );
                 if (!f) continue;
                 let val = df[n][0];
                 if (isFinite(val)) {
                     val = val.toFixed(3);
                     str += `<span>${n}=${val}</span>`;
                 }    
               }
               return str;
               }";

              
          };
        }
    };

/////////////////////////// суммарная информация

datavis: feature {
  rt: {{
    x-set-params sibling_types=["linestr","ptstr","models"] 
      sibling_titles=["Линии","Точки","Модели"] 
      data_link_values=[1]
      data_link_titles=[1];

    x-param-combo
         name="input_link" 
         values=@rt->data_link_values 
         titles=@rt->data_link_titles; // {{ param-priority 0 }};
    x-param-option
         name="input_link"
         option="priority"
         value=10;

    link to=".->input" from=@.->input_link tied_to_parent=true soft_mode=true;
  }}
};

staticvis: feature {
  rt: sibling_types=["axes","pole","kvadrat","stolbik","setka"] 
      sibling_titles=["Оси","Земля","Квадрат","Масштабный столбик","Сетка"];
};

screenvis: feature {
  rt: sibling_types=["curtime","allvars","selectedvars"] 
      sibling_titles=["Текущее время","Все переменные","Переменные по выбору"];
};