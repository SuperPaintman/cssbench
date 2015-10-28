fs          = require 'fs'
path        = require 'path'

async       = require 'async'
chalk       = require 'chalk'

CleanCSS    = require 'clean-css'
cssshrink   = require 'cssshrink'
csso        = require 'csso'
uglifycss   = require 'uglifycss'

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

module.exports = (filename, opts)->
    options = 
        saveRender: opts?.saveRender ? false

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
            do(css, callback)->
                async.series {
                    vanilla: (cb)->
                        fileLength = css.length
                        cb null, {
                            length: fileLength
                            time:   0
                        }

                    cleancss: (cb)->
                        bench = new BenchMark()

                        bench.start()
                        minified = new CleanCSS().minify(css).styles
                        delta = bench.end()

                        if options.saveRender
                            fs.writeFile  "#{parsedFilename.name}-cleancss.css", minified

                        fileLength = minified.length
                        cb null, {
                            length: fileLength
                            time:   delta
                        }

                    cssshrink: (cb)->
                        bench = new BenchMark()

                        bench.start()
                        minified = cssshrink.shrink(css)
                        delta = bench.end()

                        if options.saveRender
                            fs.writeFile "#{parsedFilename.name}-cssshrink.css", minified

                        fileLength = minified.length
                        cb null, {
                            length: fileLength
                            time:   delta
                        }

                    csso: (cb)->
                        bench = new BenchMark()

                        bench.start()
                        minified = csso.minify(css)
                        delta = bench.end()

                        if options.saveRender
                            fs.writeFile "#{parsedFilename.name}-csso.css", minified

                        fileLength = minified.length
                        cb null, {
                            length: fileLength
                            time:   delta
                        }

                    uglifycss: (cb)->
                        bench = new BenchMark()

                        bench.start()
                        minified = uglifycss.processString(css)
                        delta = bench.end()

                        if options.saveRender
                            fs.writeFile "#{parsedFilename.name}-uglifycss.css", minified

                        fileLength = minified.length
                        cb null, {
                            length: fileLength
                            time:   delta
                        }

            }, (err, res)-> callback err, res
    ], (err, res)->
        if err then console.log "[#{ chalk.red "ERROR" }]: ", err.message

        results = []

        for cssName, cssVal of res
            result = {}
            result = cssVal
            result.value = cssName

            switch cssName
                when 'vanilla'
                    result.name     = 'Vanilla'
                    result.color    = 'magenta'
                    result.percent  = 1
                when 'cleancss'
                    result.name     = 'CleanCSS'
                    result.color    = 'green'
                    result.percent  = cssVal.length / res.vanilla.length
                when 'cssshrink'
                    result.name     = 'CssShrink'
                    result.color    = 'blue'
                    result.percent  = cssVal.length / res.vanilla.length
                when 'csso'
                    result.name     = 'Csso'
                    result.color    = 'cyan'
                    result.percent  = cssVal.length / res.vanilla.length
                when 'uglifycss'
                    result.name     = 'Uglifycss'
                    result.color    = 'magenta'
                    result.percent  = cssVal.length / res.vanilla.length

            results.push result

        results.sort (a, b)-> a.percent > b.percent

        for result in results
            console.log "[#{ chalk[ result.color ] result.name }]: \t", 
                        "length: #{ chalk.yellow result.length } \t", 
                        "compression: #{ chalk.yellow (100 - result.percent * 100).toFixed 2 }% \t"
                        "time: #{ chalk.yellow result.time }ms"
