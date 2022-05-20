load "lib3dv3 csv params io gui render-params df scene-explorer-3d";

mainparams: {
  f1:  param_file value="http://viewlang.ru/assets/other/landing/2021-10-phase.txt";
  y_scale_coef: param_slider min=1 max=200 value=40;
  time: param_combo values=(@_dat->output | df_get column="T");
  step_N: param_slider value=10 min=1 max=1000;
};

dat0: load-file file=@mainparams->f1 | parse_csv separator="\s+";

_dat: @dat0->output | df_set X="->x[м]" Y="->y[м]" Z="->z[м]" T="->t[c]"
                     RX="->theta[град]" RY="->psi[град]" RZ="->gamma[град]"
                    | df_div column="RX" coef=57.7
                    | df_div column="RY" coef=57.7
                    | df_div column="RZ" coef=57.7;

dat:       @_dat->output | df_div column="Y" coef=@mainparams->y_scale_coef;
dat_prorej: @dat->output | df_skip_every count=@mainparams->step_N;
dat_cur_time: @dat->output | df_slice start=@time->index count=1;

r1: render3d bgcolor=[0.1,0.2,0.3] target=@v1
  {
    camera3d pos=[0,0,100] center=[0,0,0];
    orbit_control;

    axes_box size=100;
    @dat->output | points;

    @dat_cur_time->output | models_gltf src="https://viewlang.ru/assets/models/Lake_IV_Heavy.glb" {{ scale3d coef=5 }};
    /*
    render_gltf
                src="https://viewlang.ru/assets/models/Lake_IV_Heavy.glb".
                positions=(@dat_cur_time->output | df_combine columns=["X","Y","Z"])
                rotations=(@dat_cur_time->output | df_combine columns=["RX","RY","RZ"])
                {{ scale3d coef=5 }};
                */

  };

mainscreen: screen auto-activate {
  render-params @mainparams;
  v1: view3d style="position: absolute; width: 100%; height: 100%;";
};