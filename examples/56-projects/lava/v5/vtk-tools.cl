// туду добавка это. а 2-я версия вообще ако скрипт
register_feature name="compute_magnitude_col" code=`
      env.onvalue("input",(df) => {

        if (!df || !df.isDataFrame) {
          env.setParam("output",[]);
          return;
        }

        let v0 = df.get_column( "velocity0" );
        let v1 = df.get_column( "velocity1" );
        let v2 = df.get_column( "velocity2" );
        if (!(v0 && v1 && v2)) {
          env.setParam("output",df);
          return;
        }

        df = df.clone();
        let arr = new Float32Array( df.get_length() );
        for (let i=0; i<arr.length; i++)
          arr[i] = Math.sqrt( v0[i]*v0[i] + v1[i]*v1[i] + v2[i]*v2[i] );

        df.add_column( "magnitude", arr, df.get_column_names().indexOf( "velocity2" )+1 );
        env.setParam("output",df);
      });
`;

feature "vtk-vis-file" {
    vis: vis-group title="Колонки данных VTK" 
        //auto_gui3
        //gui={}
        find="vtk-vis-1" 
        //add="vtk-vis-connected-l"
        add={ 
           vtk-vis-1 
              input=@load->output 
              title=@.->selected_column 
              selected_column=@vis->default_column
              color=@vis->color
              show_source=false; 
        } 
        default_column="XYZ"
        points_loaded=(@load->output | geta "length")
        {{ x-param-label-small name="points_loaded" }}
        {{ x-param-label-small name="file_name" }}
        file_name=(@vis->file | geta "name")
        gui0={ render-params plashka @vis filters={ params-hide list=["title","visible"]; }; }
        addons={effect3d-delta dz=5}
        {{ x-param-color "color" }}
        color=[1,0,0]
        {


          vtk-vis-1 
                input=@load->output
                title=@.->selected_column
                selected_column=@vis->default_column
                color=@vis->color
                show_source=false;
          

          load: load-vtk-file input=@vis->file;
        };
};

// input - путь к файлу или объект файла
// output - df-ка с данными
feature "load-vtk-file" {
  loader: df56 visual-process title="Загрузчик файла VTK"
        gui={
          column plashka {
            render-params @loader filters={ params-hide list="title"; };
          };
        }
        {{ x-param-label-small name="points_loaded"}}
        points_loaded=(@loader->output | geta "length")
        output= @l->output
        {
        l: load_file_binary file=@loader->input
            | parse_vtk_points
            | compute_magnitude_col; // туду это должна быть добавка
        }    
};

// тут у нас и раскраска и доп.фильтр встроен. ну ладно.
// и это 1 штучка

feature "vtk-vis-1" {
  avp: visual_process
  //title="Визуализация VTK точек"
  input=@vtkdata->output
  output=@avp->scene3d
  show_source=true
  color=[1,0,0]
  title=(@avp->selected_column or "Слой точек")

    columns=(@avp->input | geta "colnames")
    selected_data = (geta input=@avp->input @avp->selected_column default=[])
    selected_column=""

    {{ x-param-combo name="selected_column" values=@avp->columns }}
    //{{ selected_column: param_combo values=@avp->columns index=0; }}

  gui={
    
    ko: column plashka {

      // render-params-list object=@avp list=["visible"];
      //checkbox "visible" value=@avp->visible
      //{{ x-on "user-changed" "(obj) => obj.setParam('visible',!obj.params.visible, true) " }}

      collapsible "Источник данных" visible=@avp->show_source{
        render-params @vtkdata;
      };

      render-params-list object=@avp list=["selected_column"];
      //render-params @avp;

      collapsible "Раскраска данных" {
        render-params @arrtocols;
      };

      show_sources_params 
        input=(find-objects-by-crit "visual-process" root=@scene include_root=false recursive=false)
        auto_expand_first=false
      ;
    };
  }

  gui1={
    
    ko: column plashka {

      //render-params-list object=@avp list=["visible"];

      collapsible "Раскраска данных" {
        render-params @arrtocols;
      };

      show_sources_params 
        input=(find-objects-by-crit "visual-process" root=@scene include_root=false recursive=false)
        auto_expand_first=false
      ;
    };
  } 

  gui3={
    render-params @avp;
  }
  scene3d=@scene->output
  scene2d=@scene2d->output

  {

    vtkdata: find-data-source; // гуи выбора входных данных

    scene2d: dom {
            text tag="h3" style="color:white;margin:0;" @avp->selected_column;
    };

    scene: node3d visible=@avp->visible {{ force_dump }}
    {

       // 218 201 93 цвет 0.85, 0.78, 0.36
       @avp->input | pts: points_vp
         radius=1 
         color=@avp->color
         colors=( @avp->selected_data | arrtocols: arr_to_colors gui_title="Цвета"  ) // color_func=(color_func_white)
         ;

       //insert_children input=@pts->addons_container active=(is_default @pts->addons_container) list={
         // F-PIXEL-PRESET
         // effect3d_sprite sprite="disc.png";
       //};

       // вообще может оказаться что это будет отдельный визуальный процесс - "антураж"
       //ab: axes_view size=1;

/*
       tx: text3d_vp text=@avp->selected_column
       {{
          box: get_coords_bbox input=@pts->output;
          effect3d-pos x=(@box->max | geta 0) y=(@box->max | geta 1) z=(@box->max | geta 2);
       }};
*/       

    };
  };
};