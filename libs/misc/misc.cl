register_feature name="get_query_param" code=`
    function getParameterByName(name) {
      name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
      var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
        results = regex.exec(location.search);
      //return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
      return results === null ? null : decodeURIComponent(results[1].replace(/\+/g, " "));
    }

    env.onvalue("name",(name) => {
      var v = getParameterByName(name);
      env.setParam("output",v);
    })  
`;