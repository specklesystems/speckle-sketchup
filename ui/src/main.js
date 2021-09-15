import Vue from 'vue'
import App from './App.vue'
import './registerServiceWorker'
import router from './router'
import store from './store'
import vuetify from './plugins/vuetify'
import { createProvider } from './vue-apollo'

Vue.config.productionTip = false

import VueTimeago from 'vue-timeago'
Vue.use(VueTimeago, { locale: 'en' })

export const bus = new Vue()

// sketchup bindings
global.clickFromMain = function (args) {
  bus.$emit('click-from-main', args)
}

new Vue({
  router,
  store,
  vuetify,
  apolloProvider: createProvider(),
  render: (h) => h(App)
}).$mount('#app')
