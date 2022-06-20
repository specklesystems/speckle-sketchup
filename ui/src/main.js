import 'regenerator-runtime/runtime'

import Vue from 'vue'
import App from './App.vue'
import router from './router'
import vuetify from './plugins/vuetify'
import { createProvider } from './vue-apollo'

Vue.prototype.$eventHub = new Vue()

Vue.config.productionTip = false

import VueTimeago from 'vue-timeago'
Vue.use(VueTimeago, { locale: 'en' })

import VueTooltip from 'v-tooltip'
Vue.use(VueTooltip)

import SpeckleMetrics from './plugins/speckle-metrics'
Vue.use(SpeckleMetrics, { token: 'acd87c5a50b56df91a795e999812a3a4' })

export const bus = new Vue()

new Vue({
  router,
  vuetify,
  apolloProvider: createProvider(),
  render: (h) => h(App)
}).$mount('#app')
