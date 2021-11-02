import Vue from 'vue'
import App from './App.vue'
import './registerServiceWorker'
import router from './router'
import vuetify from './plugins/vuetify'
import { createProvider } from './vue-apollo'

Vue.config.productionTip = false

import VueTimeago from 'vue-timeago'
Vue.use(VueTimeago, { locale: 'en' })

import VueMatomo from 'vue-matomo'

Vue.use(VueMatomo, {
  host: 'https://speckle.matomo.cloud',
  siteId: 2,
  userId: localStorage.getItem('suuid')
})


export const bus = new Vue()

// sketchup bindings
global.clickFromMain = function (args) {
  bus.$emit('click-from-main', args)
}

new Vue({
  router,
  vuetify,
  apolloProvider: createProvider(),
  render: (h) => h(App)
}).$mount('#app')
