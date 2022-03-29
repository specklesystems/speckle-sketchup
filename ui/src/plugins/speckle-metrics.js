let mixpanel = require('mixpanel-browser')
import crypto from 'crypto'

const SpeckleMetrics = {
  install(Vue, { token, config }) {
    config = config || {
      // eslint-disable-next-line camelcase
      api_host: 'https://analytics.speckle.systems'
    }

    Vue.prototype.$mixpanel = mixpanel
    Vue.prototype.$mixpanel.init(token, config)
    Vue.prototype.$mixpanel.register({ hostApp: 'sketchup', type: 'action' })

    Vue.prototype.$refreshMixpanelIds = function () {
      let distinctId =
        '@' +
        crypto
          .createHash('md5')
          .update(
            JSON.parse(localStorage.getItem('selectedAccount'))['userInfo']['email'].toLowerCase()
          )
          .digest('hex')
          .toUpperCase()

      let serverId = crypto
        .createHash('md5')
        .update(localStorage.getItem('serverUrl').toLowerCase())
        .digest('hex')
        .toUpperCase()

      Vue.prototype.$mixpanel.register({
        // eslint-disable-next-line camelcase
        distinct_id: distinctId,
        // eslint-disable-next-line camelcase
        server_id: serverId
      })
    }
  }
}

export default SpeckleMetrics
