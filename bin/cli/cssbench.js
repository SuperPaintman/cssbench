#!/usr/bin/env node
;
var argv, cssbench, fs;

fs = require('fs');

cssbench = require('../app.js');

argv = require('minimist')(process.argv.slice(2));

cssbench(argv['_'][0], {
  saveRender: argv['s'] ? true : false
});
