#!/usr/bin/env node

// import * as S from "./local-data-server/server-lib.mjs";
import { fileURLToPath } from 'url';
import { dirname } from 'path';
const __dirname = dirname(fileURLToPath(import.meta.url)) + "/";

// import * as process from 'process';
// в переменной INIT_CWD присылают стартовый каталог npm run scriptname
if (process.env.INIT_CWD)
    process.chdir( process.env.INIT_CWD );

import './vrungel-node-fetch-polyfill.js';

/*
console.log({__dirname});
S.run_server( "Vrungel","main.cl","/vrungel",__dirname);
*/

import * as Vrungel from "./vrungel.js";

let { vz, vzPlayer } = Vrungel.init();

    //var htmldir = vz.getDir( import.meta.url )
    //var file = Vrungel.getParameterByName("src") || (vz.getDir( import.meta.url ) + "code.txt" );
let file = process.argv[2] || "main.cl";
// file = "file://" + Vrungel.add_dir_if( file, __dirname );
///file = Vrungel.add_dir_if( file, __dirname );
file = "file://" + file;

vzPlayer.start_v1( file,false );
