// вот это похоже уже не надо

// объект который дает диалог пользвателю 
// а в output выдает найденный dataframe отмеченный меткой df56
// todo предикат ф-ю
feature "find-data-source" {
   findsource: object
      //data_length=(@findsource->output | geta "length")
      input_link=@datafiles_vals.output.0
      features="df56"
      {{
          datafiles: find-objects-bf features=@findsource->features;
                        //| arr_map code="(v) => [ v.getPath()+'->output', v.params.title || v.getPath() ]";
                        
          datafiles_vals: read @datafiles->output 
                      | arr_map code="(v) => v.getPath()+'->output'";
          datafiles_titles: read @datafiles->output 
                      | map_geta "title" default=null;

          x-param-combo
           name="input_link" 
           values=@datafiles_vals->output 
           titles=@datafiles_titles->output 
           ;

          x-param-option
           name="input_link"
           option="priority"
           value=10;

           x-param-option
           name="data_length"
           option="priority"
           value=12;

           //x-param-label-small name="data_length";
      }}
    {
      link from=@findsource->input_link to="@findsource->output";
    };
};

// input - dfка
// output - колонка (т.е. массив данных)
feature "select-source-column" {
  s: object
  {{ x-param-combo name="selected_column" values=@s->columns }}
  columns=(@s->input | geta "colnames")
  selected_column=""
  output=( @s->input | geta @s->selected_column default=[])
};

// вход:
// init_input - начальное значение (адрес вида /obj/path->paramname)
// выход:
// output - выбранная колонка (т.е. массив)
feature "find-data-source-column" {
  it: object 
  gui={
    render-params @s1 visible=@it->show_input;
    render-params @s2;
  }
  show_input=true
  selected_column=""
  output=@s2->output
  output_column_name=@s2->selected_column
  source_df=@s1->output?
  {
     s1: find-data-source input_link=@it->init_input?;
     s2: select-source-column input=@it->source_df selected_column=@it->selected_column;
  };
};
