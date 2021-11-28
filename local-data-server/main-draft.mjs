#!/usr/bin/env node

/* idea is to have commands like 
   * npx vr-cinema setup
   * npx vr-cinema help
   so on

   thus we create extra file and route commands to sub-files.

   btw it is better just to use modules and functions from them. thus app has to be refactored a little. 
   todo.

   btw 'shelljs' adds 1 mb of code; and if we use modules we just dont need it at all.
*/

import { createRequire } from 'module';
const require = createRequire(import.meta.url);

import * as path from 'path';
var fs = require('fs');
var process = require('process');

// F-PRINT-PROJECT-VERSION
//import {version} from './../package.json';
const version = process.env.npm_package_version;
console.log("VR-Cinema npm package", version || "");

//////////////////////////

// F-RUN-OTHER-SCRIPTS-FROM-MAIN
var cmd = process.argv[2];
//console.log({cmd})

if (!cmd) cmd = "start";

// https://stackoverflow.com/a/36434589
if (cmd) {
  var shell = require("shelljs");

  shell.exec(`npm run ${cmd}`);

  process.exit(0);
}
else
console.log("command is empty");

