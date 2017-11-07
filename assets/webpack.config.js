'use strict';

var path = require('path');
var ExtractTextPlugin = require("extract-text-webpack-plugin");
var CopyWebpackPlugin = require("copy-webpack-plugin");
const webpack = require('webpack');
const glob = require('glob');

function join(dest) { return path.resolve(__dirname, dest); }

function assets(dest) { return join('./' + dest); }

const config = {

  entry: {
    "app": [assets('js/app.js'), assets('css/app.css')]
  },

  output: {
    path: join('../priv/static'),
    filename: "js/app.js"
  },

  resolve: {
    extensions: ['.js', '.css'],
    modules: ['node_modules'],
  },

  module: {
    rules: [
    {
      test: /\.(jpg|png|svg)$/,
      loader: 'file-loader',
      options: {
        name: 'images/[name].[ext]',
      },
    },
    {
      test: /\.(ico|txt)$/,
      loader: 'file-loader',
      options: {
        name: './[name].[ext]',
      },
    },
    {
      test: /\.css$/,
      use: ExtractTextPlugin.extract({
        fallback: "style-loader",
        use: "css-loader"
      })
    },
    {
      test: /\.js$/,
      exclude: /node_modules/,
      loader: "babel-loader",
      query: {
        cacheDirectory: true,
        presets: [ "es2015" ]
      }
    },
    {
      include: join('node_modules/pixi.js'),
      loader: 'transform-loader?brfs',
      enforce: "post"
    }
    ]
  },

  plugins: [
    new webpack.optimize.UglifyJsPlugin({ minimize: true} ),
    new ExtractTextPlugin({ filename: 'css/app.css', allChunks: false }),
    new CopyWebpackPlugin([
      { from: "./static/images", to: "./images" },
    ]),
  ]
};

module.exports = config;
