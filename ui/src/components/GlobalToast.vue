<template>
  <v-snackbar v-if="text" v-model="snack" app bottom :color="color">
    <div v-for="(line, index) in text.split('\n')" :key="index">
      {{ line }}
    </div>
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
      color: "primary",
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
      this.snack = true
      this.color = "primary"
      this.text = args.text
      this.actionName = args.action ? args.action.name : null
      this.url = args.action ? args.action.url : null
    })
    this.$eventHub.$on('error', (args) => {
      this.snack = true
      this.color = "#CC3300"
      this.text = args.text
      this.actionName = args.action ? args.action.name : null
      this.url = args.action ? args.action.url : null
    })
  },
  methods: {
    openUrl(link) {
      this.$mixpanel.track('Connector Action', { name: 'Open In Web' })
      window.open(link)
    }
  }
}
</script>
