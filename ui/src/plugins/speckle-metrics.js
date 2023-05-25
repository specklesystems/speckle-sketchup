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

    Vue.prototype.$refreshMixpanelIds = function () {
      // 1. It logs out the user and removes out the registered props.
      Vue.prototype.$mixpanel.reset()

      // 2. create hashes for user distinction
      let distinctId =
        '@' +
        crypto
          .createHash('md5')
          .update(
            JSON.parse(localStorage.getItem('selectedAccount'))['userInfo']['email'].toLowerCase()
          )
          .digest('hex')
          .toUpperCase()

      let serverUrl = new URL(localStorage.getItem('serverUrl'))

      let serverId = crypto
        .createHash('md5')
        .update(serverUrl.hostname.toLowerCase())
        .digest('hex')
        .toUpperCase()

      // 3. Setting super properties that will be sent with every event
      Vue.prototype.$mixpanel.register({
        hostApp: 'sketchup',
        type: 'action',
        hostAppVersion: localStorage.getItem('hostAppVersion'),
        core_version: localStorage.getItem('speckleVersion'),
        server_id: serverId
      })

      // 4. Logging into user
      Vue.prototype.$mixpanel.identify(distinctId)

      // 5. If it is a registered user we can consider it is identified
      Vue.prototype.$mixpanel.people.set("Identified", true)
    }
  }
}

export default SpeckleMetrics
