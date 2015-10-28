###
Requires
###
fs              = require 'fs'

gulp            = require 'gulp'
gulpsync        = require('gulp-sync')(gulp)

clean           = require "gulp-clean"
zip             = require 'gulp-zip'

mocha           = require 'gulp-mocha'

CronJob         = require('cron').CronJob
colors          = require 'colors'

# Server
coffee          = require 'gulp-coffee'
cson            = require 'gulp-cson'

jsdoc           = require "gulp-jsdoc"

###
=====================================
Пути
=====================================
###

# Папки где находится проект
folders = 
    server:
        development:    "development"
        production:     "bin"

    general:
        docs:           "docs"
        backup:         "backup"
        release:        "release"

times =
    backup: 30

# Пути до задач
paths =
    # Серверные файлы
    server:
        coffee:
            from: [
                "./#{folders.server.development}/**/*.coffee"
            ]
            to:     "./#{folders.server.production}/"

        cson:
            from: [
                "./#{folders.server.development}/**/*.cson"
            ]
            to:     "./#{folders.server.production}/"

    # Остальное
    general:
        # Документация
        jsdoc:
            from: [
                "./#{folders.server.production}/**/*.js"
                "!./#{folders.server.production}/node_modules/**/*.js"
            ]
            to: "./#{folders.general.docs}/"
        # Бэкапы
        backup:
            from: [
                "./#{folders.server.development}/**/*"
                "./#{folders.general.release}/**/*"
                "./*.*"
                "!./"
                "!./#{folders.general.docs}/**/*"
                "!./#{folders.general.backup}/**/*"
                "!./#{folders.server.production}/**/*"
            ]
            to: "./#{folders.general.backup}/"
        # Релизы
        release:
            from: [
                "./#{folders.server.production}/**/*"
                "./*.{json,js,yml,md,txt}"
                "!./"
                "!./#{folders.server.development}/**/*"
                "!./#{folders.general.docs}/**/*"
                "!./#{folders.general.backup}/**/*"
                "!./#{folders.general.release}/**/*"
            ]
            to: "./#{folders.general.release}/"
        # Очистка предыдущей сборки
        clean:
            from: [
                "./#{folders.server.production}/**/*"
            ]
        # Тестирование
        test:
            from: [
                "./#{folders.server.production}/test/**/test*.js"
            ]

###
=====================================
Функции
=====================================
###

###*
 * Обработчик ошибок
 * @param  {Error} err - ошибка
###
error = (err)->
    console.log err.message
    @.emit 'end'

###*
 * Получение версии пакета
 * @param  {String} placeholder - строка которая заменит версию пакета, если JSON файл поврежден
 * @return {String}             - версия пакета
###
getPackageVersion = (placeholder)->
    try
        packageFile = fs.readFileSync("./package.json").toString()
        packageFile = JSON.parse packageFile

        if packageFile?.version?
            version = "v#{packageFile.version}"
        else
            version = null
    catch e
        error e
        version = null

    if !version and placeholder
        version = "#{placeholder}"
    else if !version
        version = "v0.0.0"

    return version

###*
 * Преобразует минуты в cron
 * @param  {Number} min - период бекаров
 * @return {String}     - cron date
###
getCronTime = (min)->
    return "0 */#{min} * * * *"

###
=====================================
Задачи
=====================================
###
###
-------------------------------------
Сервер
-------------------------------------
###
# Coffee
gulp.task 'development:coffee', (next)->
    gulp.src paths.server.coffee.from
        # Рендер Coffee
        .pipe coffee({bare: true}).on 'error', error
        # Сохранение
        .pipe gulp.dest paths.server.coffee.to
        .on 'error', error
        .on 'finish', next

    return

# Cson
gulp.task 'development:cson', (next)->
    gulp.src paths.server.cson.from
        # Рендер Cson
        .pipe cson().on 'error', error
        .pipe gulp.dest paths.server.cson.to
        .on 'error', error
        .on 'finish', next

    return

###
-------------------------------------
General
-------------------------------------
###
# Документация
gulp.task 'general:jsdoc', (next)->
    gulp.src paths.general.jsdoc.from
        # Рендер Cson
        .pipe jsdoc.parser().on 'error', error

        # Сохраниение в формате JSON
        # .pipe gulp.dest paths.general.jsdoc.to
        # Рендер в HTML документ
        .pipe jsdoc.generator paths.general.jsdoc.to
        .on 'error', error
        .on 'finish', next
    
    return

# Удаление сборки
gulp.task 'general:clean', (next)->
    gulp.src paths.general.clean.from, {read: false}
        # Удаление всего
        .pipe clean()
        .on 'error', error
        .on 'finish', next

    return

# Backup
gulp.task 'general:backup', (next)->
    time = new Date().getTime()
    version = getPackageVersion()

    gulp.src paths.general.backup.from, { base: './' }
        .pipe zip "bu-#{version}-#{time}.zip"
        .pipe gulp.dest paths.general.backup.to
        .on 'error', error
        .on 'finish', next

    return

gulp.task 'general:backup:cron', (next)->
    new CronJob getCronTime times.backup, ->
        console.log "#{colors.green '[CRON]'} Start make backup"
        gulp.start 'general:backup'
    , null, true, "America/Los_Angeles"

    next()
    return

# Release
gulp.task 'general:release', (next)->
    time = new Date().getTime()
    version = getPackageVersion()

    gulp.src paths.general.release.from, { base: './' }
        .pipe zip "release-#{version}-#{time}.zip"
        .pipe gulp.dest paths.general.release.to
        .on 'error', error
        .on 'finish', next
    
    return

###
-------------------------------------
Test
-------------------------------------
###
# Mocha
gulp.task 'test:mocha', (next)->
    gulp.src paths.general.test.from, {read: false}
        .pipe mocha {
            reporter: 'nyan'
            timeout: 2
        }
        .on 'error', error
        # .on 'finish', next
        
    next()

###
-------------------------------------
Watch
-------------------------------------
###
# Server
gulp.task 'watch:development:coffee', ->
    gulp.watch paths.server.coffee.from, gulpsync.sync [
        'development:coffee'
    ]
gulp.task 'watch:development:cson', ->
    gulp.watch paths.server.cson.from, gulpsync.sync [
        'development:cson'
    ]

# General
gulp.task 'watch:test:mocha', ->
    gulp.watch paths.general.test.from, gulpsync.sync [
        'test:mocha'
    ]

gulp.task 'watch:general:jsdoc', ->
    gulp.watch paths.general.jsdoc.from, gulpsync.sync [
        'general:jsdoc'
    ]

# Parent
gulp.task 'development', gulpsync.async [
    'development:coffee'
    'development:cson'
]

gulp.task 'general', gulpsync.async [
    'general:jsdoc'
    'general:clean'
    'general:backup'
    'general:release'
]

gulp.task 'test', gulpsync.async [
    'test:mocha'
]

gulp.task 'watch', gulpsync.async [
    'watch:development:coffee'
    'watch:development:cson'

    'watch:test:mocha'
    'watch:general:jsdoc'
]

# Init
gulp.task 'build', gulpsync.sync [
    # 'general:backup'
    'general:clean'

    [
        'development'
    ]
]

gulp.task 'release', gulpsync.sync [
    'build'
    'general:release'
]

gulp.task 'default', gulpsync.sync [
    'build'
    'general:backup:cron'
    'watch'
]