<template>
  <v-container></v-container>
</template>

<script>
/*global sketchup*/
import { bus } from '../main'
import userQuery from '../graphql/user.gql'

global.clickFromSettings = function (args) {
  bus.$emit('click-from-settings', args)
}

export default {
  name: 'Settings',
  components: {},
  data() {
    return {}
  },
  computed: {},
  apollo: {
    user: {
      query: userQuery
    }
  },
  mounted() {
    bus.$on('click-from-main', (args) => console.log('triggered from main', args))
    bus.$on('click-from-settings', (args) => console.log('triggered from settings', args))
  },
  methods: {}
}
</script>
