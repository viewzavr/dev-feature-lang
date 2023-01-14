 find-objects-bf features="render_project" recursive=false 
  |
  insert_children { 
    k: column style="background-color: green; border: 1px solid lime; color: white; padding: 0.2em;" 
        style_pos="position:absolute; right: 1em; bottom: 1em;"
        style_mh="max-height:100px; overflow-y: auto;"
        style_op="transition: opacity 1.0s ease-in-out;"
        dom_style_opacity=(m_eval "(f) => f && f.length > 0 ? '85%' : '0%'" @k->loading_files)
        //opacity=( if ( (@/->loading_files | geta "length") > 0) then={"85%"} else={"0%"} )
        //visible=( (@/->loading_files? | geta "length") > 0 )
        //style_q="opacity: 85%;"
        loading_files=(@/->loading_files? or [])
    {
      text "Идёт загрузка...";
      repeater input=@k->loading_files {
        r: text (m_eval "(s) => { return s.name ? s.name : s; }" @r->input);
      };
    };
  }