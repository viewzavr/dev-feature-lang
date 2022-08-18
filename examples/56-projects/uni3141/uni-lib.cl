load "lib3dv3 csv params io gui render-params df scene-explorer-3d new-modifiers imperative";
load "56view";
load "lib/init.cl";

feature "vis" {
  ai: type=@.->0
      title=( @ai->1? or @ai->type )
      crit=(m_lambda "() => true");
};

vis_list: (find-objects-bf features="vis");

// обязательный параметр project
feature "addvis" {
  x: visual_process title="Добавить визуализацию"

    gui={
      column plashka gap="0.4em" {
        text "Артефакт данных";
        cb: combobox style="max-width:230px"
              titles=(@artefacts | map_geta "title_path" default='?') 
              values=(@artefacts | map_geta "getPath")
              index=0;
        text "Образ";
        ct: combobox 
                titles=(@compatible_visual_processes | map_geta "title" default=[])
                values=(@compatible_visual_processes | map_geta "type" default=[])
                index=0; // {{ console_log_params}}
        ;
        //button "Добавить";
        ba: button_add_object "Добавить" 
           add_to=@x->project
           add_type=@ct->value?
           dom_obj_disabled=(not @ct->value?)
           {{
             created_add_to_current_view curview=@x->active_view;
           }};
        @ba | get_cell "created" | c-on "(obj,art) => {
          
          if (Array.isArray(obj)) 
             obj=obj[0]; // todo че за массив
          if (Array.isArray(obj)) 
             obj=obj[0]; // todo че за массив 2   
          //obj.setParam('element',art);
          //obj.setParam('input',art.params.output);
          //obj.setParam('input',art.params.output);
          obj.linkParam( 'input',art.getPath() + '->output',false, true);
          // и это кстати создаст нам запомнит стрелочку в составе проекта
          // но вообще по идее - obj.bindParam но это не сохранится.. плюс там нужна идентификация ячеек
          // так что это тож самое что linkParam
        }" @curart;

        curart: (@artefacts | geta @cb->index default=null);
        //console_log "curart" @curart;

        let compatible_visual_processes = (m_eval "(list,elem) => {
            console.log('evl called',elem,list)
            // if (!elem) return [];
            let res = list.filter( it => { let qq=it.params.crit( elem ); /*console.log(it,qq);*/ return qq;} )
            // console.log('filtered',res)
            return res;
          }" @vis_list (@curart | geta "output" default=null));
      };
    }
    {{
       let artefacts0 =(concat @empty_artefact (find-objects-bf features="data-artefact" root=@x->project));
       // фича фильтрации - оставляем ток те артефакты для которых есть что прицепить (визуализацию)
       let artefacts= (@artefacts0 | m_eval '(arts,outputs, list) => {
          return arts.filter( (art,index) => {
            let elem = outputs[index]; // данные артефакта
            // список применений
            let res = list.filter( it => { let qq=it.params.crit( elem ); /*console.log(it,qq);*/ return qq;} )
            return res.length > 0;
          } );
       }' (@artefacts0 | map_geta "output" default=null) @vis_list);
    }};
};

////////////////

empty_artefact:
      title="Не выбран"
      output=null
      data-artefact;