register_feature name="visual_layers"
{
  {
    linestr: title="Траектория линией" render3d-items={
        main: linestrips include_gui_inline input=@dat->output;
    };
    ptstr: title="Траектория точками" render3d-items={
        main: points include_gui_inline input=@dat->output;
    };
    axes: title="Оси координат" render3d-items={ 
       axes_box include_gui_inline size=100; 
    };
    prorej: title="Прореженная траектория" render3d-items={
        //N: param_slider value=10;
        //dat_prorej: @dat | df_skip_every count=@N->value;
        main: points include_gui_inline input=@dat_prorej->output;
    };
    pole: title="Земля 4кв км" render3d-items={
        //N: param_slider value=10;
        //dat_prorej: @dat | df_skip_every count=@N->value;
        main: mesh include_gui_inline 
          positions=[
           -1000,0,-1000,  1000,0,-1000, -1000,0,1000,
           -1000,0,1000,   1000,0,-1000,  1000,0,1000
          ]
          color=[0,0.25,0]
        ;
    };
    kvadrat: title="Квадрат места" render3d-items={
        //N: param_slider value=10;
        //dat_prorej: @dat | df_skip_every count=@N->value;
        main: mesh include_gui_inline 
          positions=[
           -30,1,-30, 30,1,-30,  -30,1,30,  
           -30,1,30,  30,1,-30,  30,1,30
          ]
          color=[1,1,1]
        ; // todo: polygon offset modifier
    };
    
    current_pos: title="Текущее положение" render3d-items={
        gltf: 
          render_gltf src="https://viewlang.ru/assets/models/Lake_IV_Heavy.glb" include_gui_inline
          positions=(@dat_cur_time | df_combine columns=["X","Y","Z"])
          rotations=(@dat_cur_time | df_combine columns=["RX","RY","RZ"])
          {{ scale3d coef=@gltf->uscale; }} 
          {{ param_slider name="uscale" min=1 max=10 value=1 }}
    };
  };
};

// todo: автоматом include_gui_inline и подавать @dat