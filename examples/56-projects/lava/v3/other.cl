

/*
   типа как render_layers_inner но на один объект детей управлять

    render_layers_mc 
         title="Визуальные объекты" 
         root=@vroot
         items=[ {"title":"Объекты данных", find":"guiblock datavis","add":"linestr"},
                 {"title":"Статичные","find":"guiblock staticvis","add":"axes"}
               ];
*/

feature "render_layers_mc" {

rl_root: 
    column text=@.->title
    style="min-width:250px" 
    style_h = "max-height:80vh;"
    {
     s: switch_selector_row {{ hilite_selected }} 
         items=(@rl_root->items | arr_map code="(v) => v.title")
         plashka style_qq="margin-bottom:0px !important;"
         ;
        
     ba: button_add_object add_to=@rl_root->root
                       add_type=(@rl_root->items | get @s->index | get "add");

     objects_list:
     find-objects-bf (@rl_root->items | get @s->index | get "find") 
                     root=@rl_root->root
                     recursive=false
                     include_root=false debug=true
     | sort_by_priority;
     ;

     /// выбор объекта

     cbsel: combobox style="margin: 5px;" dom_size=5 
       values=(@objects_list->output | arr_map code="(elem) => elem.$vz_unique_id")
       titles=(@objects_list->output | map_param "title")
       visible=( (@cbsel->values |geta "length") > 0)
       ;

    /// параметры объекта   

     co: column plashka style_r="position:relative; overflow: auto;"  
            input=(@objects_list->output | get index=@cbsel->index?)
            visible=(@co->input?)
      {
        row visible=((@co->input?  | geta  "sibling_types" | geta "length" default=0) > 1) 
        {
          object_change_type input=@co->input?
            types=(@co->input?  | geta  "sibling_types" )
            titles=(@co->input? | geta "sibling_titles")
            //types=(@co->input  | geta  "items" | geta (i_call_js code="Object.keys"))
            //titles=(@co->input  | geta  "items" | geta (i_call_js code="Object.values"))
            ;
        };

        column {
          insert_children input=@.. list=(@co->input? | geta "gui" default=[]);
        };

        if (has_feature input=@co->input? name="editable-addons") then={
          manage_addons input=@co->input?;
        };

        button "x" style="position:absolute; top:0px; right:0px;" 
        {
          lambda @co->input? code=`(obj) => { obj.removedManually = true; obj.remove(); }`;
        };

     };


  };   

};




// рисовалка набора vtk-точек
// использует vtk-vis-1
feature "vtk-vis" {
  vp: visual_process
  title="Изображение VTK"
  columns=(@vp->input | geta "colnames")
  input=@vtkdata->output
  show_source=true

  gui={
    //render-params @vp;
    column style="padding-left:1em;" {

    collapsible "Источник данных" visible=@vp->show_source {
        render-params @vtkdata plashka;
    };

    manage-content @scene 
       vp=@vp
       title="Слои" 
       items=[{"title":"Скалярные слои", "find":"vtk-vis-1","add":"vtk-vis-1"}]
       ;

       manage-addons @scene;
    };
    
  }

  scene3d=@scene->output
  output=@scene->output

  generated_processes=(@scene | find-objects-bf features="vtk-vis-1")
  sub_processes=@vp->generated_processes

  {
    vtkdata: find-data-source initial_link=@vp->initial_input_link?; // гуи выбора входных данных

    scene: node3d editable-addons 
      {

        vtk-vis-1 
              input=@vp->input 
              title=@.->selected_column
              show_source=false
        ;

/*
        // это должно быть разовым действием - добавление всех колонок
      @vp->columns | repeater {
         rep: output=@vv->output {
            vv: vtk-vis-1 
              input=@vp->input 
              selected_column=@rep->input title=@rep->input
              ;
            };  
      };
*/      

    };

    insert_children input=@scene->addons_container active=(is_default @scene) list={
        effect3d-delta dz=5;
    };

/*
     @vp->generated_processes | filter_geta "visible" | repeater {
        rep: x-modify {
          effect3d-pos z=(@rep->input_index * @vp->delta);
        };
      };
*/      
  };

};
