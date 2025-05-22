<template>
  <v-dialog v-model="dialog" max-width="400">
    <v-card>
      <v-card-title class="headline">Legacy Version</v-card-title>
      <v-card-text>
        ⚠️Warning: This is a legacy connector.
        <br /><br />
        <a 
          href="https://app.speckle.systems/connectors" 
          target="_blank" 
          style="color: #1976D2; text-decoration: none; font-weight: 500;"
        >
          Download next-gen SketchUp connector
        </a>
      </v-card-text>
      <v-card-actions>
        <v-spacer></v-spacer>
        <v-btn color="grey" text @click="dialog = false">Dismiss</v-btn>
        <v-btn color="primary" @click="downloadLatest">Download</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
export default {
  data() {
    return {
      dialog: true
    }
  },
  methods: {
    async downloadLatest() {
      const response = await fetch(
        `https://releases.speckle.dev/manager2/feeds/sketchup-v3.json`,
        {
          method: 'GET'
        }
      )

      if (!response.ok) {
        throw new Error('Failed to fetch versions')
      }

      const data = await response.json()
      const sortedVersions = data.Versions.sort(function (a, b) {
        return new Date(b.Date).getTime() - new Date(a.Date).getTime()
      })
      const latestAvailableVersion = sortedVersions[0]

      latestAvailableVersion.value = sortedVersions[0]
      window.open(latestAvailableVersion.value?.Url)
    }
  }
}
</script>
