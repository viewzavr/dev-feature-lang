#!/usr/bin/env node

// import * as S from "./local-data-server/server-lib.mjs";
import { fileURLToPath } from 'url';
import { dirname } from 'path';
const __dirname = dirname(fileURLToPath(import.meta.url)) + "/";

import './vrungel-node-fetch-polyfill.js';

/*
console.log({__dirname});
S.run_server( "Vrungel","main.cl","/vrungel",__dirname);
*/

import * as Vrungel from "./vrungel.js";

let { vz, vzPlayer } = Vrungel.init();

    //var htmldir = vz.getDir( import.meta.url )
    //var file = Vrungel.getParameterByName("src") || (vz.getDir( import.meta.url ) + "code.txt" );
let file = process.argv[2];
file = "file://" + Vrungel.add_dir_if( file, __dirname );
///file = Vrungel.add_dir_if( file, __dirname );

vzPlayer.start_v1( file,false );
