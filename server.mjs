#!/usr/bin/env node

import * as S from "./local-data-server/server-lib.mjs";
import { fileURLToPath } from 'url';
import { dirname } from 'path';
const __dirname = dirname(fileURLToPath(import.meta.url));
console.log({__dirname});
S.run_server( "Vrungel","main.cl","/vrungel",__dirname);
