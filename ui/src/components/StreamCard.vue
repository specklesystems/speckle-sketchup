<template>
  <v-card color="" class="mt-5 mb-5" style="transition: all 0.2s ease-in-out">
    <v-row>
      <v-col>
        <v-toolbar class="transparent elevation-0" dense>
          <v-toolbar-title>{{ stream.name }} O HAI</v-toolbar-title>
          <v-spacer />
        </v-toolbar>
        <v-card-text class="transparent elevation-0 mt-0 pt-0" dense>
          <v-toolbar-title>
            <v-chip v-if="stream.role" small class="mr-1">
              <v-icon small left>mdi-account-key-outline</v-icon>
              {{ stream.role.split(':')[1] }}
            </v-chip>
            <v-chip small class="mr-1">
              Updated
              <timeago :datetime="stream.updatedAt" class="ml-1"></timeago>
            </v-chip>
            <v-chip v-if="stream.branches" small>
              <v-icon small class="mr-2 float-left">mdi-source-branch</v-icon>
              {{ stream.branches.totalCount }}
            </v-chip>
          </v-toolbar-title>
        </v-card-text>
      </v-col>
      <v-col md="auto" />
      <v-col align="end" justify="center">
        <v-btn fab :loading="loading" class="mr-4 elevation-1 btn-fix" hint="Send" @click="send">
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
import gql from 'graphql-tag'
import { bus } from '../main'
import { BaseObjectSerializer } from '../utils/serialization'

global.convertedFromSketchup = function (streamId, objects) {
  bus.$emit('converted-from-sketchup', streamId, objects)
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
  computed: {},
  mounted() {
    bus.$on('converted-from-sketchup', async (streamId, objects) => {
      if (streamId != this.stream.id) return
      console.log('received objects from sketchup', objects)

      await this.createCommit(objects)
    })
  },
  methods: {
    sleep(ms) {
      return new Promise((resolve) => setTimeout(resolve, ms))
    },
    async send() {
      this.loading = true
      sketchup.send_selection(this.stream.id)
      console.log('request for data sent to sketchup')
      await this.sleep(2000)
    },
    async createCommit(objects) {
      if (objects.length == 0) {
        this.loading = false
        return
      }

      let s = new BaseObjectSerializer()
      let { hash, serialized } = s.writeJson({ '@data': objects, speckle_type: 'Base' })

      console.log('objects:', s.objects)
      try {
        this.loading = true
        let batches = s.batchObjects()
        for (const batch of batches) {
          let res = await this.sendBatch(batch)
          console.log(res)
          if (res.status !== 201) throw `Upload request failed: ${res}`
        }

        let commit = {
          streamId: this.stream.id,
          branchName: 'main',
          objectId: hash,
          message: 'sent from sketchup',
          sourceApplication: 'sketchup',
          totalChildrenCount: s.objects[hash].totalChildrenCount
        }
        console.log('commit:', commit)
        await this.$apollo.mutate({
          mutation: gql`
            mutation CommitCreate($commit: CommitCreateInput!) {
              commitCreate(commit: $commit)
            }
          `,
          variables: {
            commit: commit
          }
        })
        console.log('sent to stream: ' + this.stream.id)

        this.loading = false
      } catch (err) {
        this.loading = false
        console.log(err)
      }
    },
    async sendBatch(batch) {
      let formData = new FormData()
      formData.append(
        `batch-${num}`,
        new Blob([JSON.stringify(batch)], { type: 'application/json' })
      )
      let token = localStorage.getItem('SpeckleSketchup.AuthToken')
      let res = await fetch(`${localStorage.getItem('serverUrl')}/objects/${this.stream.id}`, {
        method: 'POST',
        headers: { Authorization: 'Bearer ' + token },
        body: formData
      })
      return res
    }
  }
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
