
mainparams: {
  //f1:  param_file value="phase_yScaled2.csv";
  f1:  param_file value="http://viewlang.ru/assets/other/landing/2021-10-phase.txt";

  y_scale_coef: param_slider min=1 max=200 value=1;

  time: param_combo values=(@_dat | df_get column="T");
  // todo исследовать time: param_combo values=(@dat | df_get column="T");

  step_N: param_slider value=10 min=1 max=1000;
};

dat0: load-file file=@mainparams->f1 
       | parse_csv separator="\s+";

_dat: @dat0 | df_set X="->x[м]" Y="->y[м]" Z="->z[м]" T="->t[c]"
              RX="->theta[град]" RY="->psi[град]" RZ="->gamma[град]"
            | df_div column="RX" coef=57.7
            | df_div column="RY" coef=57.7
            | df_div column="RZ" coef=57.7;


dat: @_dat | df_div column="Y" coef=@mainparams->y_scale_coef;       

dat_prorej: @dat | df_skip_every count=@mainparams->step_N;

dat_cur_time: @dat | df_slice start=@time->index count=1;

/*
_dat: load-file file=@mainparams->f1 
       | parse_csv separator=","
       | df_div column="RX" coef=57.7
       | df_div column="RY" coef=57.7
       | df_div column="RZ" coef=57.7;
*/