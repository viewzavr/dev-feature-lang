load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

  t1: template {
    button text="Privet";
    button text="Mir";
  };

  console_log text=@t1->output;

  screen auto_activate {
    column {
      deploy_many input=@t1->output;
      deploy_many input=@t1->output;
      row gap="0.5em" {
        deploy_many input={
          text text="Salut";
          text text="mira!";
        };
      };
    };
  };