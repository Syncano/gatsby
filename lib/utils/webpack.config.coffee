webpack = require 'webpack'
StaticSiteGeneratorPlugin = require 'static-site-generator-webpack-plugin'
ExtractTextPlugin = require 'extract-text-webpack-plugin'

gatsbyLib = /(gatsby.lib)/i
libDirs = /(node_modules|bower_components)/i
babelExcludeTest = (absPath) ->
  result = false
  # There is a match, don't exclude this file.
  if absPath.match(gatsbyLib) isnt null
    result = false
  # There is a match, do exclude this file.
  else if absPath.match(libDirs) isnt null
    result = true
  else
    result = false

  return result

module.exports = (program, directory, stage, webpackPort = 1500, routes=[]) ->
  output = ->
    switch stage
      when "develop"
        path: directory
        filename: 'bundle.js'
        publicPath: "http://#{program.host}:#{webpackPort}/"
      when "production"
        filename: "bundle.js"
        path: directory + "/public"
        publicPath: "/"
      when "static"
        path: directory + "/public"
        filename: "bundle.js"
        libraryTarget: 'umd'

  entry = ->
    switch stage
      when "develop"
        [
          "#{__dirname}/../../node_modules/webpack-dev-server/client?#{program.host}:#{webpackPort}",
          "#{__dirname}/../../node_modules/webpack/hot/only-dev-server",
          "#{__dirname}/web-entry"
        ]
      when "production"
        [
          "#{__dirname}/web-entry"
        ]
      when "static"
        [
          "#{__dirname}/static-entry"
        ]

  plugins = ->
    switch stage
      when "develop"
        [
          new webpack.HotModuleReplacementPlugin(),
          new webpack.DefinePlugin({
            "process.env": {
              NODE_ENV: JSON.stringify(if process.env.NODE_ENV then process.env.NODE_ENV else "development")
            }
            __PREFIX_LINKS__: program.prefixLinks
          })
        ]
      when "production"
        [
          new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/)
          new webpack.DefinePlugin({
            "process.env": {
              NODE_ENV: JSON.stringify(if process.env.NODE_ENV then process.env.NODE_ENV else "production")
            }
            __PREFIX_LINKS__: program.prefixLinks
          })
          new ExtractTextPlugin("style.css")
          new webpack.optimize.DedupePlugin()
          new webpack.optimize.UglifyJsPlugin()
        ]
      when "static"
        [
          new StaticSiteGeneratorPlugin('bundle.js', routes)
          new webpack.DefinePlugin({
            "process.env": {
              NODE_ENV: JSON.stringify(if process.env.NODE_ENV then process.env.NODE_ENV else "production")
            }
            __PREFIX_LINKS__: program.prefixLinks
          })
          new ExtractTextPlugin("style.css")
        ]

  resolve = ->
    {
      extensions: ['', '.js', '.jsx', '.cjsx', '.coffee', '.json', '.less', '.toml', '.yaml']
      modulesDirectories: [directory, "#{__dirname}/../isomorphic", "#{directory}/node_modules", "node_modules"]
    }

  devtool = ->
    switch stage
      when "develop", "static"
        "eval"
      when "production"
        "source-map"

  module = ->
    switch stage
      when "develop"
        loaders: [
          { test: /\.css$/, loaders: ['style', 'css']},
          { test: /\.cjsx$/, loaders: ['react-hot', 'coffee', 'cjsx']},
          {
            test: /(\.js$|\.jsx$)/,
            exclude: babelExcludeTest
            loaders: ['react-hot', 'babel']
          }
          { test: /\.less/, loaders: ['style', 'css', 'less']},
          { test: /\.coffee$/, loader: 'coffee' }
          { test: /\.md$/, loader: 'markdown' }
          { test: /\.html$/, loader: 'raw' }
          { test: /\.json$/, loaders: ['json'] }
          { test: /^((?!config).)*\.toml$/, loaders: ['toml'] } # Match everything except config.toml
          { test: /\.pdf$/, loader: 'null' }
          { test: /\.txt$/, loader: 'null' }
          { test: /\.(eot|woff|woff2|ttf|svg|png|jpg|svg|ico|gif)$/, loader: 'url-loader?limit=40000&name=[path][name]-[hash].[ext]'}
          { test: /config\.[toml|yaml|json]/, loader: 'config', query: {
            directory: directory
          } }
        ]
      when "static"
        loaders: [
          { test: /\.css$/, loader: ExtractTextPlugin.extract("style-loader", "css-loader")},
          { test: /\.cjsx$/, loaders: ['coffee', 'cjsx']},
          {
            test: /(\.js$|\.jsx$)/,
            exclude: babelExcludeTest
            loaders: ['babel']
          }
          { test: /\.less/, loaders: ['css', 'less']},
          { test: /\.coffee$/, loader: 'coffee' }
          { test: /\.md$/, loader: 'markdown' }
          { test: /\.html$/, loader: 'raw' }
          { test: /\.json$/, loaders: ['json'] }
          { test: /^((?!config).)*\.toml$/, loaders: ['toml'] } # Match everything except config.toml
          { test: /\.pdf$/, loader: 'null' }
          { test: /\.txt$/, loader: 'null' }
          { test: /\.(eot|woff|woff2|ttf|svg|png|jpg|svg|ico|gif)$/, loader: 'url-loader?limit=40000&name=[name]-[hash].[ext]'}
          { test: /config\.[toml|yaml|json]/, loader: 'config', query: {
            directory: directory
          } }
        ]
      when "production"
        loaders: [
          { test: /\.css$/, loader: ExtractTextPlugin.extract("style-loader", "css-loader")},
          { test: /\.cjsx$/, loaders: ['coffee', 'cjsx']},
          {
            test: /(\.js$|\.jsx$)/,
            exclude: babelExcludeTest
            loaders: ['babel']
          }
          { test: /\.less/, loaders: ['style', 'css', 'less']},
          { test: /\.coffee$/, loader: 'coffee' }
          { test: /\.md$/, loader: 'markdown' }
          { test: /\.html$/, loader: 'raw' }
          { test: /\.json$/, loaders: ['json'] }
          { test: /^((?!config).)*\.toml$/, loaders: ['toml'] } # Match everything except config.toml
          { test: /\.pdf$/, loader: 'null' }
          { test: /\.txt$/, loader: 'null' }
          { test: /\.(eot|woff|woff2|ttf|svg|png|jpg|svg|ico|gif)$/, loader: 'url-loader?limit=40000&name=[name]-[hash].[ext]'}
          { test: /config\.[toml|yaml|json]/, loader: 'config', query: {
            directory: directory
          } }
        ]
  return {
    context: directory + "/pages"
    node:
      __filename: true
    entry: entry()
    debug: true
    devtool: devtool()
    output: output()
    resolveLoader: {
      modulesDirectories: ["#{__dirname}/../../node_modules", "#{directory}/node_modules", "#{__dirname}/../loaders"]
    },
    plugins: plugins()
    resolve: resolve()
    module: module()
  }
