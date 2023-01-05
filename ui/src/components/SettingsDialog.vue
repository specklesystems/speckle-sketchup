<template>
  <!-- DIALOG: Settings -->
  <v-dialog v-model="showSettings">
    <template #activator="{ on, attrs }">
      <v-btn
          icon small class="mx-1"
          v-bind="attrs"
          v-on="on"
      >
        <v-icon>mdi-cog</v-icon>
      </v-btn>
    </template>

    <v-card>
      <v-card-title class="text-h5">
        Settings
      </v-card-title>
      <v-container class="px-6" pb-0>
        <!-- Switch Theme -->
        <v-btn icon small class="mx-1" @click="switchTheme">
          <v-icon>mdi-theme-light-dark</v-icon>
        </v-btn>
        <span>Color Mode</span>

      </v-container>

      <v-card-actions>
        <v-spacer></v-spacer>
        <v-btn
            color="blue darken-1"
            text
            @click="showSettings = false"
        >
          Close
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
/*global sketchup*/
import {bus} from "@/main";

export default {
  name: "ShowSettings",
  data() {
    return {
      showSettings: false,
      streamName: "",
      description: "",
    }
  },
  watch: {
    'showSettings': {
      handler(newValue, oldValue) {
        if (newValue){
          console.log("mix panel triggered when dialog opened")
          this.$mixpanel.track('Connector Action', { name: 'Open Settings Dialog' })
        }
      },
      deep: true
    }
  },
  methods: {
    switchTheme() {
      this.$vuetify.theme.dark = !this.$vuetify.theme.dark
      sketchup.exec({
        name: "preference_updated",
        data: {preference_hash: "configDUI", preference: "DarkTheme", value: this.$vuetify.theme.dark}
      })
      this.$mixpanel.track('Connector Action', { name: 'Toggle Theme' })
    },
    refresh() {
      this.$apollo.queries.user.refetch()
      bus.$emit('refresh-streams')
    }
  }
}
</script>

<style>
</style>