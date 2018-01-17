const path = require("path");
const webpack = require("webpack");

const ExtractTextPlugin = require("extract-text-webpack-plugin");
const ManifestPlugin = require("webpack-manifest-plugin");
const UglifyJSPlugin = require("uglifyjs-webpack-plugin");
const CompressionPlugin = require("compression-webpack-plugin");
const WebpackCleanupPlugin = require("webpack-cleanup-plugin");

var config = JSON.parse(require("child_process").execSync("bundle exec pakyow assets:json").toString());

var packsEntry = {};
Object.keys(config["packs"]).forEach(function(key) {
  var val = config["packs"][key];
  Object.keys(val).forEach(function(vkey) {
    var packVal = val[vkey];
    if (packVal && packVal.length > 0) {
      packsEntry[key + "/" + vkey] = packVal;
    }
  });
});

var filenameString = config["fingerprint"] ? "chunkhash" : "name";

var webpackConfig = {
  entry: packsEntry,

  output: {
    path: path.resolve(process.cwd(), config["output_path"]),
    publicPath: config["public_path"],
    filename: `[${filenameString}].js`
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
                  "browsers": [config["browsers"]]
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
            name: `[path][${filenameString}].[ext]`
          }
        }
      },
      {
        test: /\.(png|svg|jpg|gif)$/,
        use: {
          loader: "file-loader",
          options: {
            name: `[path][${filenameString}].[ext]`
          }
        }
      }
    ]
  },

  plugins: [
    new ManifestPlugin({
      publicPath: config["public_path"]
    }),
    new ExtractTextPlugin(`[${filenameString}].css`),
    new WebpackCleanupPlugin()
  ],

  target: "web"
};

if (config["source_maps"]) {
  webpackConfig["devtool"] = "eval-source-map";
}

if (config["common"]) {
  webpackConfig["plugins"].push(
    new webpack.optimize.CommonsChunkPlugin({
      name: "common"
    })
  );
}

if (config["uglify"]) {
  webpackConfig["plugins"].push(new UglifyJSPlugin());
}

if (config["compress"]) {
  webpackConfig["plugins"].push(new CompressionPlugin());
}

module.exports = webpackConfig;