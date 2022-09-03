load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc";

a: b=4 f=33;

screen auto_activate {
  row gap="1em" {
    text "privet";
    text @a.b;
    text @a.c?;
    text @a.d;
    text @a.f;
  };
};
