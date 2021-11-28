#!/usr/bin/env node

import { URL } from 'url'; // in Browser, the URL in native accessible on window
import { dirname } from 'path';
import { fileURLToPath } from 'url';
import * as path from 'path';
import { createRequire } from 'module';
import * as E from './explore.mjs';
import WF from "./feature-watch-file.mjs";

export function run_server( project_name, main_file,project_local_url="/local-vr-cinema",project_dir ) {
var project_local_url_length = project_local_url.length;

const __dirname = dirname(fileURLToPath(import.meta.url));

/*
  https://github.com/cloudhead/node-static
  https://github.com/jfhbrook/node-ecstatic/issues/259
  https://www.npmjs.com/package/ws#sending-binary-data
  https://github.com/pavelvasev/38parrots/blob/master/examples/_tutorial/5-websockets/fun-server.js
*/


const require = createRequire(import.meta.url);
var fs = require('fs');
var process = require('process');


// F-PRINT-PROJECT-VERSION
  //import {version} from './../package.json';
  // - not supported by node, for some reason
  //const version = process.env.npm_package_version;
  // - npm_package_version is sometimes defined and sometimes not, not stable method.
// thus just reading from file:
const packageJson = fs.readFileSync( path.join(__dirname, '../package.json'))
const version = JSON.parse(packageJson).version || 0
console.log(`${project_name} local_data_server, version", version || "[from source]`);

var dir = process.argv[2] || "."; // R-DIR-MODE, R-AUTO-GUESS-MODE
var url_arg;

for (let i=2; i<process.argv.length; i++) {
 if (process.argv[i] == "--dir" || process.argv[i] == "-d") {
    dir = process.argv[i+1];
    break;
 }
 else
 if (process.argv[i] == "--url" || process.argv[i] == "-u") {
    dir = undefined;
    url_arg = process.argv[i+1];
    break;
 }
}

if (dir && dir.startsWith("http")) {
  url_arg = dir;
  dir = undefined;
}

var dir_mode = dir ? true : false;

if (dir_mode) {
  //console.log( process.argv );
  console.log("serving dir:",dir );

  // R-SECURE
  if (fs.existsSync( path.join( dir,".ssh"))) {
    console.log("It seems you are running from user home dir. This is not recommended because all your files might be visible via HTTP, including .ssh credentials. Exiting." );
    process.exit(1);
  }

  if (!fs.existsSync(dir)) {
  console.log("It seems directory is not exist. Exiting.");
    process.exit(1);
  }
}
else
  console.log("opening url: ",url_arg );

var nstatic = require('node-static');
var nstatic_opts = {
                     cache: 0 // should be 0 so node-static will respond with Cache-control: max-age=0 and that is what we need, F-FRESH-FILES
                   }
/*  
var headers = {
             "Access-Control-Allow-Origin" : "*",
             "Access-Control-Allow-Headers": "Origin, X-Requested-With, Content-Type, Accept, Authorization, Cache-Control, If-Modified-Since, ETag",
             "Access-Control-Allow-Methods": "GET,HEAD,OPTIONS,POST,PUT",
            }  
*/            
  
var fileServer = dir_mode ? new nstatic.Server( dir,nstatic_opts ) : null;

// F_LOCAL_CINEMA {
  //var projectDir = path.resolve( __dirname + "/../" );
  //project_dir ||= path.resolve( __dirname + "/../" );
  console.log("project dir:",project_dir);
  var fileServerCinema = new nstatic.Server( project_dir,nstatic_opts ); // F-LOCAL-CINEMA
// F_LOCAL_CINEMA }

var server = require('http').createServer( reqfunc );

//import url from 'url';

function reqfunc(request, response) {
    console.log(request.url, request.method );
    
    //for (var k in nstatic_opts.headers) 
    if (request.headers.origin) {
        //const u =  url.parse ( request.headers.referer );
        response.setHeader( "Access-Control-Allow-Origin",request.headers.origin ); // F-REQESTER-CORS
        response.setHeader( "Access-Control-Allow-Headers","Origin, X-Requested-With, Content-Type, Accept, Authorization, Cache-Control, If-Modified-Since, ETag" );
        response.setHeader( "Access-Control-Allow-Methods","GET,HEAD,OPTIONS,POST,PUT" );
    }
    
    if (request.url == "/" && dir_mode)
      return E.explore( server, dir, request, response, explore_params );

    // F-OPEN-FOLDER
    if (request.url.startsWith("/opendir") && dir_mode)
      return E.opendir( server, dir, request, response, explore_params );
    
    if (request.method == "POST") {
      var filepath = path.join(dir,request.url);
      // R-SECURE
      var relative = path.relative( dir, filepath );
      var is_inside = relative && !relative.startsWith('..') && !path.isAbsolute(relative);

      // F-PREVIEW-SCENES
      if (["viewzavr-player.json","preview.jpg","preview.png"].indexOf(path.basename( filepath )) < 0 || !is_inside) {
        console.log("POST to invalid url, breaking");
        response.end();
        return;
      }
      
      let body = new Buffer('');
      console.log("method is post, will write file",filepath);
      request.on('data', (chunk) => {
          body = Buffer.concat([body, chunk]);
      });
      request.on('end', () => {
          fs.writeFile( filepath,body, function (err) {
            if (err) return console.log(err);
            console.log("data saved");
          } );

          //response.setHeader( "Access-Control-Allow-Origin","*");
          //response.write('OK');
          response.end();
      });
    }
    else
    if (request.method == "OPTIONS") {
          // https://stackoverflow.com/a/55979796
          // probably we should change our file serving method (e.g. node-static)
          // response.setHeader( "Allow","OPTIONS, GET, HEAD, POST");
          // https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/OPTIONS
          //for (var k in nstatic_opts.headers) response.setHeader( k,nstatic_opts.headers[k] );
          // response.write('OK'); 
          response.end();
    }
    else
    request.addListener('end', function () {

        let url = new URL(request.url,'http://localhost');
        if (url.pathname.startsWith(project_local_url)) {
          url.pathname = url.pathname.substring( project_local_url_length );
          request.url = url.toString();
          console.log("serving as viewer file",request.url, url.pathname);
          fileServerCinema.serve(request, response); // F-LOCAL-CINEMA
        }
        else {
          if (dir_mode) {
            console.log("serving as dir file");
            fileServer.serve(request, response);
          }
          else
          {
             request.end("unserved");
          }
        }
    }).resume();
}

var port = 0; // auto-detect
var host = process.env.VR_HOST || '127.0.0.1'; // only local iface

/////////// feature: watch files


var watcher_server = dir_mode ? WF( dir, host ) : null;
var watcher_port = 0;

///////////
//var vr_cinema_url = (host == "127.0.0.1" ? "https://viewzavr.com/apps/vr-cinema" : "http://viewzavr.com/apps/vr-cinema");
var viewer_url     = (serveraddr,main_file_path) => `${serveraddr}${project_local_url}/index.html?src=${main_file_path}`; // F-LOCAL-CINEMA
var explore_params = {watcher_port, viewer_url, main_file };

//////////// feature: port scan. initial port value should be non 0
port = 8080;
server.on('error', (e) => {
  if (e.code === 'EADDRINUSE') {
    console.log('Address in use, retrying...');
    port = port+1;
    server.listen( port,host );
  }
});

/////////// feature: open bro

var opener = require("opener");

if (dir_mode) {

  watcher_server.on("listening",() => {
   watcher_port = watcher_server.address().port;
   console.log("websocket server listening on port",watcher_port );

    server.on("listening",() => {

      var opath;
      var datacsv_file_path = path.join( dir, main_file ); // F-AUTOOPEN-ONE-SCENE
      if (fs.existsSync(datacsv_file_path)) {
        opath = E.vzurl( server,"",explore_params );
      }
      else
      {
        opath = `http://${server.address().address}:${server.address().port}/`;
      }
        console.log("opening in bro:",opath);
        opener( opath );
    });

  });

}
else
{
  server.on("listening",() => {
    if (url_arg.endsWith("/")) url_arg = url_arg + main_file;
    // if local_vr_cinema mode ...
    url_arg = url_arg.replaceAll("https://","http://"); // it will not load https from localhost..

    var opath = E.vzurl_view( server,url_arg,explore_params );
    console.log("opening in bro:",opath);
    opener( opath );
  });
}



//////////////////////////

server.listen( port,host );
// it seems we don-t need it in url + remote viewzavr mode.

server.on("listening",() => {
  console.log('server started: http://%s:%s', server.address().address, server.address().port);
  //console.log(server.address());
});

}