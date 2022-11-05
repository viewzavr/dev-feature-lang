#!/usr/bin/env node

Error.stackTraceLimit = 50;

// import * as S from "./local-data-server/server-lib.mjs";
import { fileURLToPath } from 'url';
import { dirname } from 'path';
const __dirname = dirname(fileURLToPath(import.meta.url)) + "/";

// import * as process from 'process';
// в переменной INIT_CWD присылают стартовый каталог npm run scriptname
if (process.env.INIT_CWD)
    process.chdir( process.env.INIT_CWD );

import './vrungel-node-fetch-fix.js';
import './vrungel-node-console-fix.js';
//import './vrungel-node-console-fix-objs.js';

/*
console.log({__dirname});
S.run_server( "Vrungel","main.cl","/vrungel",__dirname);
*/

import * as Vrungel from "./vrungel.js";

let { vz, vzPlayer } = Vrungel.init();

    //var htmldir = vz.getDir( import.meta.url )
    //var file = Vrungel.getParameterByName("src") || (vz.getDir( import.meta.url ) + "code.txt" );
let file = process.argv[2] || "main.cl";
// добавляя полный путь, мы обеспечиваем возможность внутрях вычислить текущий каталог из него и тогда хорошо отрабатывает загрузчики внутренние
file = "file://" + Vrungel.add_dir_if( file, process.cwd() + "/" );
// file = "file://" + file;

vzPlayer.start_v1( file,false );
