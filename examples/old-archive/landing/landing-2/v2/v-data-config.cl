
mainparams: {
  f1:  param_file value="http://viewlang.ru/assets/other/landing/2021-10-phase.txt";

  y_scale_coef: param_slider min=1 max=200 value=10;

  time: param_combo values=(@_dat | df_get column="T");

  step_N: param_slider value=10 min=1 max=1000;
};

dat0: load-file file=@mainparams->f1 
       | parse_csv separator="\s+";

_dat: @dat0 | df_set X="->x[м]" Y="->y[м]" Z="->z[м]" T="->t[c]"
              RX="->theta[град]" RY="->psi[град]" RZ="->gamma[град]";

dat: @_dat | df_div column="Y" coef=@mainparams->y_scale_coef;

dat_prorej: @dat | df_skip_every count=@mainparams->step_N;

dat_cur_time: @dat | df_slice start=@time->index count=1;
