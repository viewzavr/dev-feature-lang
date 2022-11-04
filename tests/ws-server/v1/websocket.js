import WebSocket from 'ws';
const WebSocketServer = WebSocket.Server;

// https://www.npmjs.com/package/ws

export function setup(vz, m) {
  vz.register_feature_set( m );
}

export function ws_server( env ) {
  //console.log("WebSocketServer=",WebSocket)
  if (!env.paramAssigned('port')) env.setParam('port',8080 )
  
  let wss;
  
  env.onvalue("port",config)
  
  function config() {
  if (wss) wss.close()
  wss = new WebSocketServer({
    port: env.params.port
  })

  wss.on('connection', function connection(ws) {
    let orig_ws_send = ws.send;
    ws.send = (data) => orig_ws_send.call( ws, JSON.stringify(data) )

    ws.on('message', function message(data,bin) {
      //console.log('received: %s', data);
      data = JSON.parse( data )
      env.emit('message',ws,data,bin)
    });

    //ws.send('something');
    env.emit('connection',ws)
  });
  }

  // todo: broadcast, get-clients, ...
}

// url - ws://host:8080
export function ws_client( env ) {
  let ws
  env.onvalue("url",config )

  function config( url ) {
    if (ws) ws.close()
     ws = new WebSocket( url );
     ws.on('open', () => {
       //console.log(333)
       env.emit('open',ws)
       env.setParam('channel',ws)
       env.setParam('send', (arg) => { return ws.send( JSON.stringify(arg) ) } )
     })
     ws.on('message', function message(data, isBinary) {
       data = JSON.parse( data )
       env.emit('message',ws,data,isBinary)
     })
  }
}