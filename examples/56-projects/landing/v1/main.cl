load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative";
load "view56";
load "landing-view.cl";

project: the_project active_view_index=1 
{

  insert_default_children input=@project list={

    lf: landing-file;

//  попробуем разабстрагировать, мб временно..
//    lv1: landing-view-1;
//    /lv2: landing-view-2;

    lv1: landing-view-base title="Приземление, общий вид"
    scene3d_items={
        linestr 
             data_adjust="traj";

        ptstr radius=2 
             data_adjust="traj";

        models 
             data_adjust="curtime";

        axes;
        pole;
        kvadrat;
    };

    lv2: 
    landing-view-base title="Приземление, вид на объект"
    file_params_modifiers={
      xx: x-set-params project_x=true project_y=true project_z=true scale_y=false;
    }
    scene3d_items={
        models 
             data_adjust="curtime";

        // вроде как не нужны - смотрелкой добавляются.. axes;
        setka;
        axes;
    }
    scene2d_items={
      //selectedvars;
    }
    ;    

    lv_t_cur: landing-view-base title="Вывод T" scene2d_items={ curtime; };

    lv_t_select: landing-view-base title="Вывод переменных" scene2d_items={ selectedvars; };

    // lv: landing-view;
    //a1: axes-view size=100;
    //a2: axes-view title="Оси координат 2";

    v0: the-view-mix3d title="Данные" 
        sources_str="@lf";

    v1: the-view-mix3d title="Общий вид" 
        sources_str="@lv1";

    v2: the-view-mix3d title="Вид на ракету" 
        sources_str="@lv2";
  };

};


//////////////////////////////////////////////////////// главное окно программы

screen1: screen auto-activate  {
  render_project @project active_view_index=1;
};

debugger-screen-r;