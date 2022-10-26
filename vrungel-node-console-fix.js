// упрощенная заглушка для nodejs чтобы ошибок и варнингов печатать цветным
// https://github.com/hadnazzar/nodejs-chalk-example/blob/master/index.js
// https://github.com/chalk/chalk

import chalk from 'chalk';

let orig_warn = console.warn;

console.warn = function() {
 return orig_warn( chalk.bgYellow( arguments[0] ), ...[...arguments].slice(1) )
}

let orig_err = console.error;

console.error = function() {
 return orig_err( chalk.bgRed( arguments[0] ), ...[...arguments].slice(1) )
}
