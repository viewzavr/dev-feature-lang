feature "auto_gui" {
  vp:
  gui={
    render-params plashka @vp filters={ params-hide list="title"; };

    manage-content @vp
       root=@vp
       allow_add=false
       title=""
       vp=@vp
       items=[{"title":"Визуальные слои", "find":"visual-process"}];
  };
};

feature "auto_gui2" {
  vp:
  gui={
    render-params plashka @vp filters={ params-hide list="title"; };

    column style="" {
      show_sources_params input=@vp->subprocesses;
    };
  }
  subprocesses=(find-objects-bf root=@vp features="visual-process" include_root=false recursive=false)
  visible_subprocesses = (@vp->subprocesses | filter_geta "visible")
  scene3d= (@vp->visible_subprocesses | map_geta "scene3d" default=null)
  scene2d= (@vp->visible_subprocesses | map_geta "scene2d" default=null)
  ;
};

feature "auto_gui3" {
  vp:
  gui={}
  gui2={
    render-params plashka @vp filters={ params-hide list="title"; };

    column style="" {
      show_sources_params input=@vp->ag_subprocesses;
    };
  }
  ag_subprocesses=(find-objects-bf root=@vp features="visual-process" include_root=false recursive=false)
  ;
};