// v3 - версия с новыми экранами и камерами

load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative";
load "56view";
load "landing-view.cl";

project: the_project active_view_index=1 default_animation_parameter="project/lv1/timeparams->time_index"
{
  
  insert_children input=@project active=(is_default @project) manual=true list={

    lf: landing-file;
    lv1: landing-view-1;
    lv2: landing-view-2;

    sync_time: esync1 synced_param_name="time_index";

    lv_t_cur: landing-view-base title="Вывод T" scene2d_items={ curtime; };

    lv_t_select: landing-view-base title="Вывод переменных" scene2d_items={ selectedvars; };

    v0: the-view-uni title="Данные" {
       area sources_str="@lf";
    };        

    v1: the-view-uni title="Общий вид" {
        area sources_str="@lv1,@lv_t_cur"    camera=@c1;
    };

    v2: the-view-uni title="Вид на ракету" {
        area sources_str="@lv2,@lv_t_select" camera=@c2;
      };

    c1: camera3dt title="Главная камера" 
          center=[0,0,0] pos=[0,300,1000];
    c2: camera3dt title="Камера у начала координат" 
          center=[0,0,0] pos=[101.97743440722813, 111.82726702985235, 155.1388566634926];
        
  };

};
// мб будет полезно и такой "дефолтный проект" абстрагировать.
// чтобы по команде пользователя его применять.



//////////////////////////////////////////////////////// главное окно программы

screen1: screen auto-activate  {
  render_project @project active_view_index=1;
};

// debugger-screen-r;