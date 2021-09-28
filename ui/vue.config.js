const path = require('path')

module.exports = {
  publicPath:
    process.env.NODE_ENV === 'production'
      ? path.resolve(__dirname, '../speckle_connector', 'html')
      : '/',
  outputDir: path.resolve(__dirname, '../speckle_connector', 'html'),
  transpileDependencies: ['vuetify', '@speckle/objectloader']
}
