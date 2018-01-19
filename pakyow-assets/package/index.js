const path = require("path");
const webpack = require("webpack");

const ExtractTextPlugin = require("extract-text-webpack-plugin");
const ManifestPlugin = require("webpack-manifest-plugin");
const UglifyJSPlugin = require("uglifyjs-webpack-plugin");
const CompressionPlugin = require("compression-webpack-plugin");
const WebpackCleanupPlugin = require("webpack-cleanup-plugin");

var config = {};
if (process.env.PAKYOW_ASSETS_CONFIG) {
  config = JSON.parse(new Buffer(process.env.PAKYOW_ASSETS_CONFIG, "base64").toString("ascii"));
} else {
  config = JSON.parse(require("child_process").execSync("bundle exec pakyow assets:json").toString());
}

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

var webpackConfig = {
  entry: packsEntry,

  output: {
    path: path.resolve(process.cwd(), config["output_path"]),
    publicPath: config["public_path"],
    filename: `[${config["fingerprint"] ? "chunkhash" : "name"}].js`
  },

  module: {
    rules: [
      {
        test: function (path) {
          var ext = "." + path.split('.').pop();
          if (config["types"]["styles"].indexOf(ext) > -1) { return true; }
        },
        exclude: /(node_modules|bower_components)/,
        use: ExtractTextPlugin.extract({
          use: ["css-loader", "sass-loader"]
        })
      },

      {
        test: function (path) {
          var ext = "." + path.split('.').pop();
          if (config["types"]["scripts"].indexOf(ext) > -1) { return true; }
        },
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
        test: function (path) {
          var ext = "." + path.split('.').pop();
          if (config["types"]["av"].indexOf(ext) > -1) { return true; }
          if (config["types"]["data"].indexOf(ext) > -1) { return true; }
          if (config["types"]["fonts"].indexOf(ext) > -1) { return true; }
          if (config["types"]["images"].indexOf(ext) > -1) { return true; }
        },
        exclude: /(node_modules|bower_components)/,
        use: {
          loader: "file-loader",
          options: {
            name: `[path][${config["fingerprint"] ? "hash" : "name"}].foo.[ext]`
          }
        }
      }
    ]
  },

  plugins: [
    new ManifestPlugin({
      publicPath: config["public_path"]
    }),

    new ExtractTextPlugin({
      filename: `[${config["fingerprint"] ? "contenthash" : "name"}].css`,
      allChunks: true
    }),

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
