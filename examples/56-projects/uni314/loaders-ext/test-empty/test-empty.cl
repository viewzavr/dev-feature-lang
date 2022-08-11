vis "t1" "Тестовый образ 1" crit=(m_lambda "(dir) => dir ? 0 : 1");

feature "t1"
{
  v:  
      visual_process 
      auto_gui2
      title="Тестовый образ 1"
      {
         console-log "scene3d is " @pt->scene3d;
         pt: points_vp positions=(m_eval "(count) => {
           let acc = [];
           for (let i=0; i<count*3; i++)
             acc.push( Math.random() );
           return acc;  
         }" 1000);
      }
      ;
};

