`#!/usr/bin/env node
`
fs              = require 'fs'

cssbench        = require '../app.js'
argv            = require('minimist') process.argv[2...]

cssbench argv['_'][0], {
    saveRender: argv['s']? ? true or false
}