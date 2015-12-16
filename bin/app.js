var BenchMark, CSSbench, CleanCSS, _, async, colors, cssnano, csso, cssshrink, fs, less, path, sass, stylus, uglifycss, zlib;

fs = require('fs');

path = require('path');

zlib = require('zlib');

async = require('async');

colors = require('colors');

_ = require('lodash');

CleanCSS = require('clean-css');

cssshrink = require('cssshrink');

csso = require('csso');

uglifycss = require('uglifycss');

cssnano = require('cssnano');

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

CSSbench = function(filename, opts) {
  var options;
  options = _.merge({
    title: false,
    saveRender: false
  }, opts);
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
      return async.series({
        vanilla: function(cb) {
          return zlib.deflate(css, function(err, buffer) {
            var fileLength, gzipfileLength;
            if (err) {
              return cb(err);
            }
            fileLength = css.length;
            gzipfileLength = buffer.toString().length;
            return cb(null, {
              size: fileLength,
              gzipSize: gzipfileLength,
              time: 0
            });
          });
        },
        cleancss: function(cb) {
          var bench, delta, e, error1, minified;
          bench = new BenchMark();
          bench.start();
          try {
            minified = new CleanCSS().minify(css).styles;
          } catch (error1) {
            e = error1;
            bench.end();
            return cb(null, {
              error: e
            });
          }
          delta = bench.end();
          if (options.saveRender) {
            fs.writeFileSync(parsedFilename.name + "-cleancss.css", minified);
          }
          return zlib.deflate(minified, function(err, buffer) {
            var fileLength, gzipfileLength;
            if (err) {
              return cb(err);
            }
            fileLength = minified.length;
            gzipfileLength = buffer.toString().length;
            return cb(null, {
              size: fileLength,
              gzipSize: gzipfileLength,
              time: delta
            });
          });
        },
        cssshrink: function(cb) {
          var bench, delta, e, error1, minified;
          bench = new BenchMark();
          bench.start();
          try {
            minified = cssshrink.shrink(css);
          } catch (error1) {
            e = error1;
            bench.end();
            return cb(null, {
              error: e
            });
          }
          delta = bench.end();
          if (options.saveRender) {
            fs.writeFileSync(parsedFilename.name + "-cssshrink.css", minified);
          }
          return zlib.deflate(minified, function(err, buffer) {
            var fileLength, gzipfileLength;
            if (err) {
              return cb(err);
            }
            fileLength = minified.length;
            gzipfileLength = buffer.toString().length;
            return cb(null, {
              size: fileLength,
              gzipSize: gzipfileLength,
              time: delta
            });
          });
        },
        csso: function(cb) {
          var bench, delta, e, error1, minified;
          bench = new BenchMark();
          bench.start();
          try {
            minified = csso.minify(css);
          } catch (error1) {
            e = error1;
            bench.end();
            return cb(null, {
              error: e
            });
          }
          delta = bench.end();
          if (options.saveRender) {
            fs.writeFileSync(parsedFilename.name + "-csso.css", minified);
          }
          return zlib.deflate(minified, function(err, buffer) {
            var fileLength, gzipfileLength;
            if (err) {
              return cb(err);
            }
            fileLength = minified.length;
            gzipfileLength = buffer.toString().length;
            return cb(null, {
              size: fileLength,
              gzipSize: gzipfileLength,
              time: delta
            });
          });
        },
        uglifycss: function(cb) {
          var bench, delta, e, error1, minified;
          bench = new BenchMark();
          bench.start();
          try {
            minified = uglifycss.processString(css);
          } catch (error1) {
            e = error1;
            bench.end();
            return cb(null, {
              error: e
            });
          }
          delta = bench.end();
          if (options.saveRender) {
            fs.writeFileSync(parsedFilename.name + "-uglifycss.css", minified);
          }
          return zlib.deflate(minified, function(err, buffer) {
            var fileLength, gzipfileLength;
            if (err) {
              return cb(err);
            }
            fileLength = minified.length;
            gzipfileLength = buffer.toString().length;
            return cb(null, {
              size: fileLength,
              gzipSize: gzipfileLength,
              time: delta
            });
          });
        },
        cssnano: function(cb) {
          var bench;
          bench = new BenchMark();
          bench.start();
          return cssnano.process(css, {
            autoprefixer: false
          }).then(function(result) {
            var delta, minified;
            minified = result.css;
            delta = bench.end();
            if (options.saveRender) {
              fs.writeFileSync(parsedFilename.name + "-cssnano.css", minified);
            }
            return zlib.deflate(minified, function(err, buffer) {
              var fileLength, gzipfileLength;
              if (err) {
                return cb(err);
              }
              fileLength = minified.length;
              gzipfileLength = buffer.toString().length;
              return cb(null, {
                size: fileLength,
                gzipSize: gzipfileLength,
                time: delta
              });
            });
          })["catch"](function(err) {
            return cb(null, {
              error: err
            });
          });
        }
      }, function(err, res) {
        return callback(err, res);
      });
    }
  ], function(err, res) {
    var cssName, cssVal, error, errors, gzipPercent, i, j, len, len1, percent, result, results;
    if (err) {
      console.log("[" + (colors.red("ERROR")) + "]: ", err.message);
    }
    results = [];
    errors = [];
    for (cssName in res) {
      cssVal = res[cssName];
      if (cssVal.error) {
        error = {
          color: 'grey',
          name: cssName,
          error: cssVal.error
        };
        errors.push(error);
        continue;
      }
      result = {};
      result = cssVal;
      result.value = cssName;
      switch (cssName) {
        case 'vanilla':
          result.name = 'Vanilla';
          result.color = 'magenta';
          break;
        case 'cleancss':
          result.name = 'CleanCSS';
          result.color = 'green';
          break;
        case 'cssshrink':
          result.name = 'CssShrink';
          result.color = 'blue';
          break;
        case 'csso':
          result.name = 'Csso';
          result.color = 'cyan';
          break;
        case 'uglifycss':
          result.name = 'Uglifycss';
          result.color = 'magenta';
          break;
        default:
          result.name = cssName;
          result.color = 'grey';
      }
      result.percent = cssVal.size / res.vanilla.size;
      result.gzipPercent = cssVal.gzipSize / res.vanilla.gzipSize;
      results.push(result);
    }
    results.sort(function(a, b) {
      return a.percent > b.percent;
    });
    if (options.title) {
      console.log(colors.green(options.title.toUpperCase()));
    }
    for (i = 0, len = results.length; i < len; i++) {
      result = results[i];
      percent = (100 - result.percent * 100).toFixed(2);
      gzipPercent = (100 - result.gzipPercent * 100).toFixed(2);
      console.log("[" + (colors[result.color](result.name)) + "]: \t", "size: " + (colors.yellow(result.size)), (colors.grey("(")) + "-" + (colors.yellow(percent)) + "%" + (colors.grey(")")), "gzip: " + (colors.yellow(result.gzipSize)) + " ", (colors.grey("(")) + "-" + (colors.yellow(gzipPercent)) + "%" + (colors.grey(")")), "time: " + (colors.yellow(result.time)) + "ms");
    }
    for (j = 0, len1 = errors.length; j < len1; j++) {
      error = errors[j];
      percent = (100 - result.percent * 100).toFixed(2);
      gzipPercent = (100 - result.gzipPercent * 100).toFixed(2);
      console.log("[" + (colors[error.color](error.name)) + "]: \t", colors.red(error.error.toString()));
    }
    if (options.title) {
      return console.log("\n");
    }
  });
};

if (!module.parent) {
  CSSbench(path.join(__dirname, "../example", "bootstrap.css"), {
    title: "bootstrap"
  });
  CSSbench(path.join(__dirname, "../example", "foundation.css"), {
    title: "foundation 6"
  });
  CSSbench(path.join(__dirname, "../example", "skeleton.css"), {
    title: "skeleton"
  });
} else {
  module.exports = CSSbench;
}
