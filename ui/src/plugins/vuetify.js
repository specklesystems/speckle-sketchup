import Vue from 'vue'
import Vuetify from 'vuetify/lib/framework'
import '@/scss/styles.css'
Vue.use(Vuetify)

export default new Vuetify({
  theme: {
    dark: false,
    themes: {
      light: {
        primary: '#0480FB', //speckle blue
        secondary: '#01D1FD', //spark blue
        accent: '#46B958', //data yellow
        error: '#FF5555', //red
        warning: '#D8BF16', //lightning yellow
        info: '#2D2ADA', //majestic blue
        success: '#22966C', //mantis green
        environment: '#AF02CB', //environment purple
        background: '#eeeeee',
        background2: '#ffffff',
        text: '#FFFFFF'
      },
      dark: {
        primary: '#0480FB', //speckle blue
        secondary: '#01D1FD', //spark blue
        accent: '#46B958', //data yellow
        error: '#FF5555', //red
        warning: '#D8BF16', //lightning yellow
        info: '#2D2ADA', //majestic blue
        success: '#22966C', //mantis green
        environment: '#AF02CB', //environment purple
        background: '#3a3b3c',
        background2: '#303132'
      }
    }
  },
  icons: {
    iconfont: 'mdi'
  }
})
