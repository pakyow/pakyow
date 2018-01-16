const path = require("path");
const webpack = require("webpack");

const ExtractTextPlugin = require("extract-text-webpack-plugin");
const ManifestPlugin = require("webpack-manifest-plugin");
const UglifyJSPlugin = require("uglifyjs-webpack-plugin");
const CompressionPlugin = require("compression-webpack-plugin");
const WebpackCleanupPlugin = require("webpack-cleanup-plugin");

var packs = JSON.parse(require("child_process").execSync("bundle exec pakyow assets:json").toString());
var packsEntry = {};

Object.keys(packs).forEach(function(key) {
  var val = packs[key];
  Object.keys(val).forEach(function(vkey) {
    packsEntry[key + "/" + vkey] = val[vkey];
  });
});

module.exports = {
  entry: packsEntry,

  output: {
    path: path.resolve(process.cwd(), "public/assets"),
    publicPath: "/assets/",
    filename: "[name].js"
  },

  module: {
    rules: [
      {
        test: /\.css$/,
        use: ExtractTextPlugin.extract({
          use: "css-loader"
        })
      },
      {
        test: /\.(scss|sass)$/,
        exclude: /node_modules/,
        use: ExtractTextPlugin.extract({
          use: ["css-loader", "sass-loader"]
        })
      },
      {
        test: /\.js$/,
        exclude: /(node_modules|bower_components)/,
        use: {
          loader: "babel-loader",
          options: {
            presets: [
              ["env", {
                "targets": {
                  // TODO: this should be a config option
                  "browsers": ["last 2 versions"]
                }
              }]
            ]
          }
        }
      },
      {
        test: /\.(woff|woff2|eot|ttf|otf)$/,
        use: {
          loader: "file-loader",
          options: {
            name: "[path][name].[ext]"
          }
        }
      },
      {
        test: /\.(png|svg|jpg|gif)$/,
        use: {
          loader: "file-loader",
          options: {
            name: "[path][name].[ext]"
          }
        }
      }
    ]
  },

  plugins: [
    new ManifestPlugin({
      publicPath: "/assets/"
    }),
    new ExtractTextPlugin("[name].css"),
    new webpack.optimize.CommonsChunkPlugin({
      name: "common"
    }),
    new WebpackCleanupPlugin()

    // TODO: production only
    // new UglifyJSPlugin(),
    // new CompressionPlugin()
  ],

  // TODO: dev only
  devtool: "eval-source-map",

  target: "web"
};
