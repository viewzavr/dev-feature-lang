/* тут у нас заготовки на тему сохранения параметров программы в windows hash
   замысел - вытащить это из vzplayer в управление пользователем
   * пример мониторинга ниже
   * надо еще на загрузке - применить параметры
*/

monitor_tree_params root=@of->output action={
  pause_apply {
    console_log text="eeeeeee";
    //emit_event object=@of name="save_state";
  }
};


feature "monitor_tree_params" {
  root: {
    f: func {
      insert_children input=@f list=@root->action;
      // о поздравляю генератор таки ))) ну ибо func различает своих по другому смыслу.
    };

    find-objects-bf root=@root->root features="" recursive=true include_subfeatures=false
    //{{ console_log_params "UUUUUUUUUUUUUUUUUUUUU"}}
      | pause_input
      | console_log_input "modify input for param-changed"
      | x_modify {
      
          rt: x_on 'param_changed' {
            //lambda @rt->host @f code="() => { console.log(33)}";
            
            lambda @f code="(obj,f,name) => {
                //console.log('see param change in', name,obj);
                if (obj && f) {
                    let m = obj.getParamManualFlag( name );
                    let i = obj.getParamOption(name,'internal')
                    if (m && !i) {
                      //console.log('see manual param change in', name,obj);
                      f.callCmd('apply',obj,name);
                    }
                }
            };";
            
          };
    };    
  }
};

feature "pause_input" code=`
  env.feature("delayed");
  let pass = env.delayed( () => {
    env.setParam("output", env.params.input);
  },1000/30);

  env.onvalue("input",pass);
`;


feature "pause_apply" {
  r: func timeout=100 {{ delay_execution timeout=@r->timeout }};
};


/*
feature "timeout" code=`
  env.feature("delayed");
  let pass = env.delayed( () => {
    
  },1000/30);

  env.addCmd("apply",() => {
     pass();  
  })
`;
*/