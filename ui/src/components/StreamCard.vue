<template>
  <v-card color="" class="mt-5 mb-5" style="transition: all 0.2s ease-in-out">
    <v-row>
      <v-col>
        <v-toolbar class="transparent elevation-0" dense>
          <v-toolbar-title>{{ stream.name }}</v-toolbar-title>
          <v-spacer />
        </v-toolbar>
        <v-card-text class="transparent elevation-0 mt-0 pt-0" dense>
          <v-toolbar-title>
            <v-chip small class="mr-1" v-if="stream.role">
              <v-icon small left>mdi-account-key-outline</v-icon>
              {{ stream.role.split(':')[1] }}
            </v-chip>
            <v-chip small class="mr-1">
              Updated
              <timeago :datetime="stream.updatedAt" class="ml-1"></timeago>
            </v-chip>
            <v-chip small v-if="stream.branches">
              <v-icon small class="mr-2 float-left">mdi-source-branch</v-icon>
              {{ stream.branches.totalCount }}
            </v-chip>
          </v-toolbar-title>
        </v-card-text>
      </v-col>
      <v-col md="auto" />
      <v-col align="end" justify="center">
        <v-btn fab :loading="loading" @click="send" class="mr-4 elevation-1 btn-fix" hint="Send">
          <v-img
            v-if="$vuetify.theme.dark"
            src="@/assets/SenderWhite.png"
            max-width="40"
            style="display: inline-block"
          />
          <v-img v-else src="@/assets/Sender.png" max-width="40" style="display: inline-block" />
        </v-btn>
      </v-col>
    </v-row>
  </v-card>
</template>

<script>
/*global sketchup*/
import { bus } from '../main'

global.convertedFromSketchup = function (args) {
  bus.$emit('converted-from-sketchup', args)
}

export default {
  props: {
    stream: {
      type: Object,
      default: function () {
        return {}
      }
    }
  },
  data() {
    return { loading: false }
  },
  mounted() {
    bus.$on('converted-from-sketchup', (args) => {
      console.log('received objects from sketchup', args)
    })
  },
  methods: {
    sleep(ms) {
      return new Promise((resolve) => setTimeout(resolve, ms))
    },
    async send() {
      this.loading = true
      sketchup.send_selection()
      console.log('send lol')
      await this.sleep(2000)
      this.loading = false
    }
  },
  computed: {}
}
</script>

<style>
.btn-fix:focus::before {
  opacity: 0 !important;
}
.btn-fix:hover::before {
  opacity: 0.08 !important;
}
</style>