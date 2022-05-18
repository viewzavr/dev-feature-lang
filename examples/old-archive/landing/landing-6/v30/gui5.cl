register_feature name="collapsible" {
  cola: 
  column
  {
    shadow_dom {
      btn: button text=@../..->text cmd="@pcol->trigger_visible";

      pcol: 
      column visible=false {{ use_dom_children from=@../..; }};

      deploy_features input=@btn  features=@cola->button_features;
      deploy_features input=@pcol features=@cola->body_features;
    };

  };
};

register_feature name="plashka" {
  style_p="background: rgba(99, 116, 137, 0.86); padding: 5px;"
  style_b="border-left: 8px solid #00000042;
                      border-bottom: 1px solid #00000042;
                      border-radius: 5px;
                      margin-bottom: 5px;
                     ";
}  