find-objects-bf features="the_view_types" recursive=false 
|
insert_children { 
  value="the_view_uni_grid" title="Сетка (uni)"; 
};


feature "the_view_uni_grid"
{
  tv: the-view-uni
    show_view={
      show_visual_tab_uni_grid input=@tv; 
    }
};

feature "show_visual_tab_uni_grid" {
   svr: dom_group
      screenshot_dom = @rrviews->dom
   {

    show_sources_params input=(@svr->input | geta "sources");

    rrviews: dom style="position: absolute; top: 0; left: 0; width:100%; height: 100%; z-index:-2;
        display: grid; grid-template-columns: repeat(2, 1fr);"
    {
      repa: repeater input=(@svr->input | geta "visible_areas") {
          show_area;
        }; // repeater of areas

      }; // global row rrviews

   }; // domgroup

}; // show vis tab