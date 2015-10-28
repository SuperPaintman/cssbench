var BenchMark, CleanCSS, async, chalk, csso, cssshrink, fs, less, path, sass, stylus, uglifycss;

fs = require('fs');

path = require('path');

async = require('async');

chalk = require('chalk');

CleanCSS = require('clean-css');

cssshrink = require('cssshrink');

csso = require('csso');

uglifycss = require('uglifycss');

sass = require('node-sass');

less = require('less');

stylus = require('stylus');

BenchMark = (function() {
  function BenchMark() {
    this.timeStart = void 0;
    this.timeFinish = void 0;
    this.timeDelta = void 0;
  }

  BenchMark.prototype.start = function() {
    return this.timeStart = new Date().getTime();
  };

  BenchMark.prototype.end = function() {
    this.timeFinish = new Date().getTime();
    this.timeDelta = this.timeFinish - this.timeStart;
    return this.timeDelta;
  };

  return BenchMark;

})();

module.exports = function(filename, opts) {
  var options, ref;
  options = {
    saveRender: (ref = opts != null ? opts.saveRender : void 0) != null ? ref : false
  };
  return async.waterfall([
    function(callback) {
      return fs.readFile(filename, function(err, data) {
        var file, parsedFilename;
        if (err) {
          return callback(err, null);
        }
        file = data.toString();
        parsedFilename = path.parse(filename);
        return callback(null, parsedFilename, file);
      });
    }, function(parsedFilename, file, callback) {
      var css;
      switch (parsedFilename.ext) {
        case '.styl':
          return stylus.render(file, function(err, css) {
            if (err) {
              return callback(err, null);
            }
            return callback(null, parsedFilename, css);
          });
        case '.sass':
          return sass.render({
            data: file
          }, function(err, result) {
            var css;
            if (err) {
              return callback(err, null);
            }
            css = result.css.toString();
            return callback(null, parsedFilename, css);
          });
        case '.scss':
          return sass.render({
            data: file
          }, function(err, result) {
            var css;
            if (err) {
              return callback(err, null);
            }
            css = result.css.toString();
            return callback(null, parsedFilename, css);
          });
        case '.less':
          return less.render(file, function(err, output) {
            var css;
            if (err) {
              return callback(err, null);
            }
            css = output.css;
            return callback(null, parsedFilename, css);
          });
        default:
          css = file;
          return callback(null, parsedFilename, css);
      }
    }, function(parsedFilename, css, callback) {
      return (function(css, callback) {
        return async.series({
          vanilla: function(cb) {
            var fileLength;
            fileLength = css.length;
            return cb(null, {
              length: fileLength,
              time: 0
            });
          },
          cleancss: function(cb) {
            var bench, delta, fileLength, minified;
            bench = new BenchMark();
            bench.start();
            minified = new CleanCSS().minify(css).styles;
            delta = bench.end();
            if (options.saveRender) {
              fs.writeFile(parsedFilename.name + "-cleancss.css", minified);
            }
            fileLength = minified.length;
            return cb(null, {
              length: fileLength,
              time: delta
            });
          },
          cssshrink: function(cb) {
            var bench, delta, fileLength, minified;
            bench = new BenchMark();
            bench.start();
            minified = cssshrink.shrink(css);
            delta = bench.end();
            if (options.saveRender) {
              fs.writeFile(parsedFilename.name + "-cssshrink.css", minified);
            }
            fileLength = minified.length;
            return cb(null, {
              length: fileLength,
              time: delta
            });
          },
          csso: function(cb) {
            var bench, delta, fileLength, minified;
            bench = new BenchMark();
            bench.start();
            minified = csso.minify(css);
            delta = bench.end();
            if (options.saveRender) {
              fs.writeFile(parsedFilename.name + "-csso.css", minified);
            }
            fileLength = minified.length;
            return cb(null, {
              length: fileLength,
              time: delta
            });
          },
          uglifycss: function(cb) {
            var bench, delta, fileLength, minified;
            bench = new BenchMark();
            bench.start();
            minified = uglifycss.processString(css);
            delta = bench.end();
            if (options.saveRender) {
              fs.writeFile(parsedFilename.name + "-uglifycss.css", minified);
            }
            fileLength = minified.length;
            return cb(null, {
              length: fileLength,
              time: delta
            });
          }
        }, function(err, res) {
          return callback(err, res);
        });
      })(css, callback);
    }
  ], function(err, res) {
    var cssName, cssVal, i, len, result, results, results1;
    if (err) {
      console.log("[" + (chalk.red("ERROR")) + "]: ", err.message);
    }
    results = [];
    for (cssName in res) {
      cssVal = res[cssName];
      result = {};
      result = cssVal;
      result.value = cssName;
      switch (cssName) {
        case 'vanilla':
          result.name = 'Vanilla';
          result.color = 'magenta';
          result.percent = 1;
          break;
        case 'cleancss':
          result.name = 'CleanCSS';
          result.color = 'green';
          result.percent = cssVal.length / res.vanilla.length;
          break;
        case 'cssshrink':
          result.name = 'CssShrink';
          result.color = 'blue';
          result.percent = cssVal.length / res.vanilla.length;
          break;
        case 'csso':
          result.name = 'Csso';
          result.color = 'cyan';
          result.percent = cssVal.length / res.vanilla.length;
          break;
        case 'uglifycss':
          result.name = 'Uglifycss';
          result.color = 'magenta';
          result.percent = cssVal.length / res.vanilla.length;
      }
      results.push(result);
    }
    results.sort(function(a, b) {
      return a.percent > b.percent;
    });
    results1 = [];
    for (i = 0, len = results.length; i < len; i++) {
      result = results[i];
      results1.push(console.log("[" + (chalk[result.color](result.name)) + "]: \t", "length: " + (chalk.yellow(result.length)) + " \t", "compression: " + (chalk.yellow((100 - result.percent * 100).toFixed(2))) + "% \t", "time: " + (chalk.yellow(result.time)) + "ms"));
    }
    return results1;
  });
};
