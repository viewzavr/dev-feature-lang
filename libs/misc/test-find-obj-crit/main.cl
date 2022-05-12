load files="lib3dv3 csv params io gui render-params df scene-explorer-3d misc imperative";

s: arr=[1,2,3,4,5]
  {
  alfa: beta=15;
  teta: env1 {
    zita: r=4;
    tuta: env2 js={"a":5, "b":4};
  };
};

screen auto_activate {
    column {

      text (join "result is s? " ( find-one-object input="@/s" | geta "getPath"));

      text (join "result is alfa,teta? " ( find-objects-by-pathes root=@s
        input="@alfa,@teta" | map_geta "getPath"));

      text (join "result is alfa,teta? " ( find-objects-by-pathes 
        input="@/s/alfa , @/s/teta" | map_geta "getPath"));
      

      text (join "result is alfa,teta? (crit test)" ( find-objects-by-crit 
        input="@/s/alfa , @/s/teta" | map_geta "getPath"));

      text (join "result is teta? (crit test+ft)" ( find-objects-by-crit 
        input="@/s env1" | map_geta "getPath"));
     

      text (join "result is teta? (crit test+ft)" ( find-objects-by-crit 
        input="env1" | map_geta "getPath"));      

      text (join "result is teta and tuta? (crit test+ft)" ( find-objects-by-crit 
        input="@/s env1, @/s/teta env2" | map_geta "getPath"));

      text (join "result is blank? (crit test+ft)" ( find-objects-by-crit 
        input="@/s2 env1, @/s3/teta env2" | console_log_input "blank?"));
        //| map_geta (i-call-js code="() => JSON.stringify(env.params.input)")));
    };

};
