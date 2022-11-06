let orig_log = console.log
console.log = function() {
 return orig_log( ...fix([...arguments]) )
}

let orig_log2 = console.warn
console.warn = function() {
 return orig_log2( ...fix([...arguments]) )
}

let orig_log3 = console.error
console.error = function() {
 return orig_log3( ...fix([...arguments]) )
}

function fix( arr ) {
  //orig_log('fixing', arr.length )
  for (let i=0; i<arr.length; i++)
    if (arr[i]?.getPath) arr[i] = `obj[${arr[i].$vz_unique_id}]:${arr[i].getPath()}`;
  return arr
}

/*
let orig_warn = console.warn;

console.warn = function() {
 return orig_warn( chalk.bgYellow( arguments[0] ), ...[...arguments].slice(1) )
}

let orig_err = console.error;

console.error = function() {
 return orig_err( chalk.bgRed.black( arguments[0] ), ...[...arguments].slice(1) )
}
*/