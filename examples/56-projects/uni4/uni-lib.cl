load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative";
load "56view";

feature "compatible_visual_processes_for" {
  k: object 
    curart=@.->0 
    output=(
      @vis_makers_codes
      |
      repeater { | codes |
        create_objects input=@codes @k.curart
      }
s      |
      map_geta "output" default=null // возьмем выходы create-objects-ов
      | 
      map_geta 0 default=null // там ж массив.. хотя это как бы намек что мы мейкеров можем вообще создавать пачкой сразу
      | 
      filter_geta "possible"
     );
};

load "lib/init.cl";

feature "vismaker";

let vis_makers_list=(find-objects-bf features="vismaker");
let vis_makers_codes=(@vis_makers_list | map_geta "code");


// обязательный параметр project
feature "addvis" {
  x: visual_process title="Добавить визуализацию"

    gui={
      column ~plashka gap="0.4em" {
        text "Артефакт данных";
        cb: combobox style="max-width:230px"
              titles=(@artefacts | map_geta "title_path" default='?') 
              values=(@artefacts | map_geta "getPath" fok=true | arr_map code="v => v()" )
              index=0;
        text "Образ";
        ct: combobox 
                titles=(@compatible_visual_processes | map_geta "title" default=[])
                index=0
        ;
        let active_template = (@compatible_visual_processes | geta @ct->index | geta "make" default=null);
        //button "Добавить";
        ba: button_add_object_t "Добавить" 
           add_to=@x->project
           add_template=@active_template?
           dom_obj_disabled=(not @active_template?)
           {{
             created_add_to_current_view curview=@x->active_view;
           }};

        let curart=(@artefacts | geta @cb->index default=null);
        //console-log "QQQQQQQQ curart=" @curart "compat procs=" @compatible_visual_processes;
        //let compatible_visual_processes = (compatible_visual_processes_for @curart);
        let compatible_visual_processes=(@curart | geta "vis_makers");
      };
    }
    {{
       let artefacts0 =(concat @empty_artefact 
                         (find-objects-bf features="data-artefact" root=@x->project)
                         (find-objects-bf features="data-artefact" root=@x->viewer) 
                         );
       // console-log "VIEW ARTEFACTS" (find-objects-bf features="data-artefact" root=@x->viewer) @x->viewer;
       // там артефакты рендеринга.. но кстати временные..

       //let artefacts=@artefacts0;

       //console-log "EEEE artefacts0" @artefacts0 "found procs" @all_art_compatible_visual_processes "passed artefacts" @artefacts;

       /*
       let all_art_compatible_visual_processes = (@artefacts0 | repeater debug=true {
          k: output=(compatible_visual_processes_for @k->input);
          //((compatible_visual_processes @k->input) | geta "length") > 0;
       } | map_geta "output" default=null);

       let artefacts = (m_eval "(arts,procs_arr) => arts.filter( (x,index) => procs_arr[index]?.length > 0)" 
                               @artefacts0 @all_art_compatible_visual_processes);
       */
       let all_art_compatible_visual_processes = (@artefacts0 | map_geta "vis_makers" default=null);
       let artefacts = @artefacts0;

/*
       let artefacts = (m_eval "(arts,procs_arr) => arts.filter( (x,index) => procs_arr[index]?.length > 0)" 
                               @artefacts0 @all_art_compatible_visual_processes);
*/       
    }};
};

////////////////

feature "an-empty-artefact";

empty_artefact:
      data-artefact 
      title="Не выбран"
      output=null
      ~an-empty-artefact
      ;

//compatible_visual_processes_for @empty_artefact | console-log-input "TEST1";

feature "x-art-ref" {
  k: x-modify crit="data-artefact" {
    x-param-objref-3 name=@k->name values=(concat @empty_artefact (find-objects-by-crit @k->crit))
    // root=@x->project
    // (find-objects-by-crit @k->crit)
    title_field="title_path"
    ;
    x-param-option name=@k->name option="always_manual" value=true;
  };
};