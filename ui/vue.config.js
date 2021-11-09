const path = require('path')

module.exports = {
  publicPath: "./",
  outputDir: path.resolve(__dirname, '../speckle_connector', 'html'),
  transpileDependencies: ['vuetify', '@speckle/objectloader']
}
