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
  
  env.setParam("conns", env.create_cell() )
  
  function config() {
  if (wss) wss.close()
  wss = new WebSocketServer({
    port: env.params.port
  })

  wss.on('connection', function connection(ws) {
    let incoming = env.create_cell()
    let outgoing = env.create_cell()

    outgoing.on('assigned',(data) => {
      ws.send( JSON.stringify(data) )
    })

    ws.on('message', function message(data,bin) {
      //console.log('received: %s', data);
      data = JSON.parse( data )
      incoming.set( data )
      //env.emit('message',ws,data,bin)
    });

    env.emit( 'connection',incoming, outgoing )
    env.params.conns.set( [incoming, outgoing] )
  });
  }

  // todo: broadcast, get-clients, ...

  env.setParam("output",env.params.conns)
}

// url - ws://host:8080
export function ws_client( env ) {
  if (!env.paramAssigned('url'))
    env.setParam('url','ws://localhost:8080')

  let ws
  let connected
  env.onvalue("url",config )
  
  if (!env.paramAssigned("in"))
     env.setParam("in", env.create_cell() )
  if (!env.paramAssigned("out"))
    env.setParam("out", env.create_buffer_cell() )
    
  env.params.out.on('assigned',() => {
    send_all()
  })
  
  function send_all() {
    while (connected) {
      let data = env.params.out.consume();
      if (data == null) break;
      data = data[0]
      ws.send( JSON.stringify(data) )
    }
  }

  function config( url ) {
    if (ws) ws.close()
     ws = new WebSocket( url );
     ws.on('open', () => {
       //console.log(333)
       env.emit('open',ws)
       //env.setParam('channel',ws)
       connected = true
       send_all()
     })
     ws.on('message', function message(data, isBinary) {
       data = JSON.parse( data )
       //env.emit('message',ws,data,isBinary)
       env.params.in.set( data )
     })
  }

  env.setParam("output",env)
}