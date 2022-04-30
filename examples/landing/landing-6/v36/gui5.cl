register_feature name="collapsible" {
  cola: 
  column
  {
    shadow_dom {
      btn: button text=@../..->text cmd="@pcol->trigger_visible";

      pcol: 
      column visible=@cola->expanded {{ use_dom_children from=@../..; }};
      // сохраняет состояние развернутости колонки в collapsible-е
      // без этого сохранения не получится т.к. содержимое колонки 
      // не проходит dump по причине что shadow_dom вычеркнул себя из списка детей.
      // возможно это стоит и полечить.
      link from="@pcol->visible" to="@cola->expanded" manual_mode=true;

      insert_features input=@btn  list=@cola->button_features;
      insert_features input=@pcol list=@cola->body_features;

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