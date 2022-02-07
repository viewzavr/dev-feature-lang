register_feature name="visual_layers"
{
  linestr: title="Траектория линией" render3d-items={
      main: linestrips include_gui_inline input=@dat->output;
  };
  ptstr: title="Траектория точками" render3d-items={
      main: points include_gui_inline input=@dat->output;
  };
  axes: title="Оси координат" render3d-items={ 
     axes_box include_gui_inline size=100 include_gui_here; 
  };
};