fs          = require 'fs'
path        = require 'path'
zlib        = require 'zlib'

async       = require 'async'
colors      = require 'colors'

_           = require 'lodash'

CleanCSS    = require 'clean-css'
cssshrink   = require 'cssshrink'
csso        = require 'csso'
uglifycss   = require 'uglifycss'
cssnano     = require 'cssnano'

sass        = require 'node-sass'
less        = require 'less'
stylus      = require 'stylus'

class BenchMark
    constructor: ->
        @timeStart      = undefined
        @timeFinish     = undefined
        @timeDelta      = undefined

    start: -> @timeStart = new Date().getTime()

    end: -> 
        @timeFinish = new Date().getTime()
        @timeDelta = @timeFinish - @timeStart

        return @timeDelta

CSSbench = (filename, opts)->
    # Options
    options = _.merge {
        title:      false
        saveRender: false
    }, opts

    async.waterfall [
        # ReadFile
        (callback)->
            fs.readFile filename, (err, data)->
                if err then return callback err, null
                file = data.toString()

                parsedFilename = path.parse filename

                callback null, parsedFilename, file
        # Render
        (parsedFilename, file, callback)->
            switch parsedFilename.ext
                when '.styl'
                    stylus.render file, (err, css)->
                        if err then return callback err, null
                        
                        callback null, parsedFilename, css

                when '.sass'
                    sass.render {
                        data: file
                    }, (err, result)->
                        if err then return callback err, null

                        css = result.css.toString()
                        callback null, parsedFilename, css
                when '.scss'
                    sass.render {
                        data: file
                    }, (err, result)->
                        if err then return callback err, null

                        css = result.css.toString()
                        callback null, parsedFilename, css
                when '.less'
                    less.render file, (err, output)->
                        if err then return callback err, null

                        css = output.css
                        callback null, parsedFilename, css
                else
                    css = file
                    callback null, parsedFilename, css
        # Test
        (parsedFilename, css, callback)->
            async.series {
                vanilla: (cb)->
                    zlib.deflate css, (err, buffer)->
                        if err then return cb(err)
                        fileLength = css.length
                        gzipfileLength = buffer.toString().length


                        cb null, {
                            size:       fileLength
                            gzipSize:   gzipfileLength
                            time:       0
                        }

                cleancss: (cb)->
                    bench = new BenchMark()

                    bench.start()
                    try
                        minified = new CleanCSS().minify(css).styles
                    catch e
                        bench.end()
                        return cb null, { error: e }
                    
                    delta = bench.end()

                    if options.saveRender
                        fs.writeFileSync  "#{parsedFilename.name}-cleancss.css", minified

                    zlib.deflate minified, (err, buffer)->
                        if err then return cb(err)
                        fileLength = minified.length
                        gzipfileLength = buffer.toString().length


                        cb null, {
                            size:       fileLength
                            gzipSize:   gzipfileLength
                            time:       delta
                        }

                cssshrink: (cb)->
                    bench = new BenchMark()

                    bench.start()
                    try
                        minified = cssshrink.shrink(css)
                    catch e
                        bench.end()
                        return cb null, { error: e }
                    delta = bench.end()

                    if options.saveRender
                        fs.writeFileSync "#{parsedFilename.name}-cssshrink.css", minified

                    zlib.deflate minified, (err, buffer)->
                        if err then return cb(err)
                        fileLength = minified.length
                        gzipfileLength = buffer.toString().length


                        cb null, {
                            size:       fileLength
                            gzipSize:   gzipfileLength
                            time:       delta
                        }

                csso: (cb)->
                    bench = new BenchMark()

                    bench.start()
                    try
                        minified = csso.minify(css)
                    catch e
                        bench.end()
                        return cb null, { error: e }
                    delta = bench.end()

                    if options.saveRender
                        fs.writeFileSync "#{parsedFilename.name}-csso.css", minified

                    zlib.deflate minified, (err, buffer)->
                        if err then return cb(err)
                        fileLength = minified.length
                        gzipfileLength = buffer.toString().length


                        cb null, {
                            size:       fileLength
                            gzipSize:   gzipfileLength
                            time:       delta
                        }

                uglifycss: (cb)->
                    bench = new BenchMark()

                    bench.start()
                    try
                        minified = uglifycss.processString(css)
                    catch e
                        bench.end()
                        return cb null, { error: e }
                    delta = bench.end()

                    if options.saveRender
                        fs.writeFileSync "#{parsedFilename.name}-uglifycss.css", minified

                    zlib.deflate minified, (err, buffer)->
                        if err then return cb(err)
                        fileLength = minified.length
                        gzipfileLength = buffer.toString().length


                        cb null, {
                            size:       fileLength
                            gzipSize:   gzipfileLength
                            time:       delta
                        }

                cssnano: (cb)->
                    bench = new BenchMark()

                    bench.start()
                    cssnano.process(css, {autoprefixer: false})
                        .then (result)->
                            minified = result.css
                            delta = bench.end()

                            if options.saveRender
                                fs.writeFileSync "#{parsedFilename.name}-cssnano.css", minified

                            zlib.deflate minified, (err, buffer)->
                                if err then return cb(err)
                                fileLength = minified.length
                                gzipfileLength = buffer.toString().length


                                cb null, {
                                    size:       fileLength
                                    gzipSize:   gzipfileLength
                                    time:       delta
                                }
                        .catch (err)-> 
                            cb null, { error: err }

            }, (err, res)-> callback err, res
    ], (err, res)->
        if err then console.log "[#{ colors.red "ERROR" }]: ", err.message

        results = []
        errors = []
        for cssName, cssVal of res
            if cssVal.error
                error = {
                    color:  'grey'
                    name:   cssName
                    error:  cssVal.error
                }

                errors.push error
                continue

            result = {}
            result = cssVal
            result.value = cssName

            switch cssName
                when 'vanilla'
                    result.name     = 'Vanilla'
                    result.color    = 'magenta'
                when 'cleancss'
                    result.name     = 'CleanCSS'
                    result.color    = 'green'
                when 'cssshrink'
                    result.name     = 'CssShrink'
                    result.color    = 'blue'
                when 'csso'
                    result.name     = 'Csso'
                    result.color    = 'cyan'
                when 'uglifycss'
                    result.name     = 'Uglifycss'
                    result.color    = 'magenta'
                else
                    result.name     = cssName
                    result.color    = 'grey'

            result.percent      = cssVal.size / res.vanilla.size
            result.gzipPercent  = cssVal.gzipSize / res.vanilla.gzipSize

            results.push result

        results.sort (a, b)-> a.percent > b.percent

        if options.title
            console.log colors.green(options.title.toUpperCase())

        for result in results
            percent = (100 - result.percent * 100).toFixed(2)
            gzipPercent = (100 - result.gzipPercent * 100).toFixed(2)

            console.log   "[#{ colors[ result.color ] result.name }]: \t"
                        , "size: #{ colors.yellow(result.size) }"
                        , "#{colors.grey("(")}-#{ colors.yellow(percent) }%#{colors.grey(")")}"
                        , "gzip: #{ colors.yellow(result.gzipSize) } "
                        , "#{colors.grey("(")}-#{ colors.yellow(gzipPercent) }%#{colors.grey(")")}"
                        , "time: #{ colors.yellow result.time }ms"

        for error in errors
            percent = (100 - result.percent * 100).toFixed(2)
            gzipPercent = (100 - result.gzipPercent * 100).toFixed(2)

            console.log   "[#{ colors[ error.color ] error.name }]: \t"
                        , colors.red error.error.toString()

        if options.title
            console.log "\n"

if !module.parent
    # Basic test
    CSSbench path.join(__dirname, "../example", "bootstrap.css"), {
        title: "bootstrap"
    }

    CSSbench path.join(__dirname, "../example", "foundation.css"), {
        title: "foundation 6"
    }

    CSSbench path.join(__dirname, "../example", "skeleton.css"), {
        title: "skeleton"
    }
else
    # Export
     module.exports = CSSbench