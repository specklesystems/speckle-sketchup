const path = require('path')

module.exports = {
  publicPath: './',
  outputDir: path.resolve(__dirname, '../speckle_connector_3', 'vue_ui'),
  transpileDependencies: ['vuetify', '@speckle/objectloader']
}
