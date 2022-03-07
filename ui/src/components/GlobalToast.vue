<template>
  <v-snackbar v-model="snack" app bottom color="primary">
    {{ text }}
    <template #action="{}">
      <v-btn v-if="actionName" small outlined @click="openUrl(url)" @click:append="snack = false">
        {{ actionName }}
      </v-btn>
      <v-btn small icon @click="snack = false">
        <v-icon small>mdi-close</v-icon>
      </v-btn>
    </template>
  </v-snackbar>
</template>
<script>
export default {
  data() {
    return {
      snack: false,
      text: null,
      actionName: null,
      url: null
    }
  },
  watch: {
    snack(newVal) {
      if (!newVal) {
        this.text = null
        this.actionName = null
        this.url = null
      }
    }
  },
  mounted() {
    this.$eventHub.$on('notification', (args) => {
      console.log('in toast notification', args)
      this.snack = true
      this.text = args.text
      this.actionName = args.action ? args.action.name : null
      this.url = args.action ? args.action.url : null
      console.log('results of notif', this.actionName, this.url)
    })
  },
  methods: {
    openUrl(link) {
      window.open(link)
    }
  }
}
</script>
