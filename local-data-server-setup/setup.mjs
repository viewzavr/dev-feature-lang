#!/usr/bin/env node

// this script adds hooks to operating system explorers to start vr-cinema
// this is actual a switching algorithm to call appropriate script for current os.

//console.log( process.argv );
var cmd = (process.argv[2] == "off" ? "uninstall" : "install");

import * as CP from 'child_process';


import * as path from 'path';
import { fileURLToPath } from 'url';

function localpath( name ) {
  const __dirname = fileURLToPath(import.meta.url)
  const d2 = path.dirname( __dirname );
  return path.join( d2, name );
//  var p = (new URL(name, import.meta.url)).pathname;
//  if (process.platform === "win32") return p.substr(1);
//  return p;
}

var isWin = process.platform === "win32";
console.log("cmd=",cmd,"isWin=",isWin );
                                    

if (isWin) {
  var n = localpath( `setup-windows/${cmd}.cmd` );
  console.log("calling",n);
  var p = CP.exec(n);
  p.stdout.pipe(process.stdout);
  p.stderr.pipe(process.stderr);
}
else
{
  var n = localpath( `setup-linux/${cmd}.sh` );
  console.log("calling",n);
  var p = CP.exec(n);
  p.stdout.pipe(process.stdout);
  p.stderr.pipe(process.stderr);
}


/*
var url = (new URL('.', import.meta.url));
var dir = url.pathname;
console.log(dir);
*/

/*

//////////////////////////////////////////////
import { readdir } from 'fs/promises';
import * as path from 'path';
//const path = require('path');

function findFiles( startdir, cb )
{
  readdir( startdir,{withFileTypes:true} ).then( (arr) => {
    arr.forEach( f => {
      if (f.isDirectory())
        findFiles( path.join(startdir, f.name), cb );
      else
        cb( path.join(startdir, f.name) );
    } );
  });
}

findFiles( dir, function(f) {
  console.log(f);
});
*/

/*
try {
  const files = await readdir(dir);
  for await (const file of files)
    console.log(file);
} catch (err) {
  console.error(err);
}
*/
