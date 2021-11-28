#!/usr/bin/env node
// [data.csv] file watching service/feature (actually a lib, not a feature?)

// https://github.com/pavelvasev/38parrots/blob/master/examples/_tutorial/5-websockets/fun-server.js

import WS from 'ws';
import * as FS from 'fs';
import * as path from 'path';
import * as http from 'http';

export default function startWatcherService(basedir,host) {
  //console.log(WS);

  // подключённые клиенты
  var clients = {};
  var fileSubscriptions = {}; // mapping filename => client_id (or client?)
  var srv = alloc( 5555, host, (webSocketServer) =>{

  //console.log( "started websocket server",webSocketServer._server );

  webSocketServer.on('connection', function(ws,request,client) {

    var id = Math.random();
    clients[id] = ws;
    console.log("новое соединение " + id, request.url );
    
    var filepath = path.join( basedir, request.url );
    console.log("starting watch to",filepath);
    FS.watch( filepath,(event,path) => {
      console.log("olalaa",event,path);
      ws.send("OLALA");
    });

    ws.on('close', function() {
      console.log('соединение закрыто ' + id);
      delete clients[id];
    });

  });
  
  } );

  return srv;
}

function alloc(port,host,cb) {

  // we create http server manually and pass it to WS.Server because
  // we need to allocate any available port and this is the only way
  // to do this is manually

  // from node_modules/ws/lib/websocket-server.js
  var server = http.createServer((req, res) => {
        const body = STATUS_CODES[426];

        res.writeHead(426, {
          'Content-Length': body.length,
          'Content-Type': 'text/plain'
        });
        res.end(body);
  });
  
  server.on('error', (e) => {
    if (e.code === 'EADDRINUSE') {
      console.log('WS Address in use, retrying...');
      port = port+1;
      server.listen( port,host, null );
      console.log("new listen established");
    }
  });
  server.listen( port,host, null );
  
  server.on("listening",() => {
    var p = new WS.Server({ server: server} );
    cb(p);
  });
  
  return server;
}

////////////////////////////////////////

/*
import * as FS from 'fs';
console.log("starting watch");
FS.watch( "data.csv",(event,path) => {
  console.log("olalaa",event,path);
});
*/

////////////////////////////////////////



