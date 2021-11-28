// feature F-EXPLORE
// probable bug if search is too deep. maybe restrict it by count or time or depth?

import { readdir } from 'fs/promises';
import * as fs from 'fs'; // F-PREVIEW-SCENES
import * as path from 'path';

function findFiles( startdir, cb )
{
  var res = new Promise( function (resolv, rej) {

  readdir( startdir,{withFileTypes:true} ).then( (arr) => {
    var acc = [];
    arr.forEach( f => {
      if (f.isDirectory())
        acc.push( findFiles( path.join(startdir, f.name), cb ) );
      else
        cb( path.join(startdir, f.name) );
    } );
    Promise.allSettled( acc ).then( () => resolv() );
  });
  
  });
  
  return res;
}

export function vzurl_view( server, main_file_url, options={} ) {
    var opath = options.viewer_url( `http://${server.address().address}:${server.address().port}`,main_file_url )
    return opath;
}

export function vzurl( server, viewer_relative_dir,options={} ) {
    var datapath = `http://${server.address().address}:${server.address().port}${viewer_relative_dir}/${options.main_file}`;
    var storepath = `http://${server.address().address}:${server.address().port}${viewer_relative_dir}/viewzavr-player.json`;

    var opath = vzurl_view( server, datapath, options ) + `&settings=${storepath}&storepath=${storepath}`;
    // +feature watch file
    if (options.watcher_port) {
       var wpath = `ws://${server.address().address}:${options.watcher_port}${viewer_relative_dir}/${options.main_file}`;
       opath = opath + `&cmdpath=${wpath}`;
       // может быть нужен другой подход.. сделать за всеми data.csv...?
    }
    return opath;
}

export function explore( server, dir, request, response, options={} )
{
  var txt = "";
  var counter=0;
  //var lasturl; // I-AUTOOPEN-ONCE-SCENE
  var urls = [];
  findFiles( dir, function(f) {
    //console.log(f,path.basename(f).toLowerCase());
    if (path.basename(f).toLowerCase() == options.main_file) {
      console.log("match",f);
      var rel = path.relative( dir, f );
      var reldir = path.dirname( rel );
      var url = vzurl( server,"/"+reldir, options );

      // F-PREVIEW-SCENES {
      var preview_url;
      let preview_path = path.join( path.dirname(f), "preview.png" );
      if (fs.existsSync(preview_path))
        preview_url = "/"+reldir + "/preview.png"; 
      // F-PREVIEW-SCENES }

      urls.push( {url,reldir,preview_url} );
      //lasturl = url; // I-AUTOOPEN-ONCE-SCENE
      //txt = txt + `<li><a target='_blank' href='${url}'>${reldir}</a></li>`
      counter++;
    }
  }).then( function() {
    /*
      if (counter == 1) { // I-AUTOOPEN-ONCE-SCENE
        response.writeHead(301,{Location: url});
        response.end();
      }
      else
      {
        */
        urls = urls.sort( (r1, r2) => {
            if (r1.reldir > r2.reldir) return 1;
            if (r1.reldir < r2.reldir) return -1;
            return 0;
        });
        
        var txt = vis2( urls,request );

        response.setHeader('Content-Type', 'text/html');
        console.log("listing sent");
        response.end( txt );
      //}
  });
}

function vis0( urls ) {
  var counter = urls.length;
  var txt = urls.map( (rec) => `<li><a target='_blank' href='${rec.url}'>${rec.reldir}</a></li>`).join("\n");
  txt = `<h3>There are ${counter} projects(s) found</h3> <ul class='list_noimages'>${txt}</ul> ${txtimg}`;
  return txt;
}

function vis1( urls ) { // F-PREVIEW-SCENES
  var counter = urls.length;
var txt = urls.map( (rec) => {
          let i = rec.preview_url ? `<br/> <img src='${rec.preview_url}' width=240/>` : "";
          let ii = rec.preview_url ? "with_img" : "";
          return `<li class='${ii}'><a target='_blank' href='${rec.url}'>${rec.reldir} ${i}</a></li>`
        } ).join("\n");
        txt = `<h3>There are ${counter} project(s) found</h3> 
<style>
  ul li.with_img { 
    display: inline-block; 
  }
</style>        
<ul class='list_noimages'>${txt}</ul>`;

return txt;
}

function vis2( urls, request ) { // F-PREVIEW-SCENES
  var counter = urls.length;
var txt = "", txtimg = "";
        urls.forEach( (rec) => {
         let desktop = "";

         if (islocal(request)) { // F-OPEN-FOLDER
            desktop = `<a href='#' title='Open this directory in explorer' onclick='fetch("/opendir?dir=${rec.reldir}")'>&#128187;</a>`;
         }

          if (rec.preview_url)
            txtimg += `
  <span style="display:inline-block">
    
    <a title='Run visualization' target='_blank' href='${rec.url}'>
    <img src='${rec.preview_url}' width=240/>
    </a>
    <br/>
    ${desktop} 
    <a title='Run visualization' target='_blank' href='${rec.url}'>
      ${rec.reldir}
    </a>
  </span>
  `;
          else
            txt += `<li>${desktop} <a title='Run visualization' target='_blank' href='${rec.url}'>${rec.reldir}</a></li>`
        })
        txt = `<h3>There are ${counter} project(s) found</h3> <ul class='list_noimages'>${txt}</ul> ${txtimg}`;  
return txt;
}


///////////////// F-OPEN-FOLDER
import { URL } from 'url';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
var opener = require("opener");
export function opendir( server, dir, request, response, options={} )
{
  if (!islocal(request)) {
    return response.end("notlocal");
  }
  let url = new URL(request.url,'http://localhost');
  let reldir = url.searchParams.get("dir");
  let finaldir = path.join( dir, reldir );
  opener( finaldir );
  response.end("done");
}

function islocal( request ) {
  return (request.socket.remoteAddress == "127.0.0.1");
}