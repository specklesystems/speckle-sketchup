<template>
  <v-hover v-slot="{ hover }">
    <v-card color="" class="mt-5 mb-5" style="transition: all 0.2s ease-in-out">
      <v-row>
        <v-col>
          <v-toolbar class="transparent elevation-0" dense>
            <v-toolbar-title>{{ stream.name }}</v-toolbar-title>
            <v-spacer />
          </v-toolbar>
          <v-card-text class="transparent elevation-0 mt-0 pt-0" dense>
            <div class="text-caption">
              Updated
              <timeago :datetime="stream.updatedAt" />
            </div>
            <v-toolbar-title>
              <v-chip v-if="stream.role" small class="mr-1">
                <v-icon small left>mdi-account-key-outline</v-icon>
                {{ stream.role.split(':')[1] }}
              </v-chip>

              <v-menu offset-y>
                <template #activator="{ on, attrs }">
                  <v-chip v-if="stream.branches" small v-bind="attrs" v-on="on">
                    <v-icon small class="mr-1 float-left">mdi-source-branch</v-icon>
                    {{ branchName }}
                  </v-chip>
                </template>
                <v-list dense>
                  <v-list-item
                    v-for="(branch, index) in stream.branches.items"
                    :key="index"
                    link
                    @click="switchBranch(branch.name)"
                  >
                    <v-list-item-title class="text-caption">
                      {{ branch.name }} ({{ branch.commits.totalCount }})
                    </v-list-item-title>
                  </v-list-item>
                </v-list>
              </v-menu>
            </v-toolbar-title>
          </v-card-text>
        </v-col>
        <v-col v-if="hover" align="end" justify="center">
          <v-btn icon class="mr-4 btn-fix" @click="openInWeb">
            <v-icon>mdi-open-in-new</v-icon>
          </v-btn>
          <v-btn
            fab
            :loading="loadingSend"
            class="mr-4 elevation-1 btn-fix"
            hint="Send"
            @click="send"
          >
            <v-img
              v-if="$vuetify.theme.dark"
              src="@/assets/SenderWhite.png"
              max-width="40"
              style="display: inline-block"
            />
            <v-img v-else src="@/assets/Sender.png" max-width="40" style="display: inline-block" />
          </v-btn>
          <v-btn
            fab
            :loading="loadingReceive"
            class="mr-4 elevation-1 btn-fix"
            hint="Receive"
            @click="receive"
          >
            <v-img
              v-if="$vuetify.theme.dark"
              src="@/assets/ReceiverWhite.png"
              max-width="40"
              style="display: inline-block"
            />
            <v-img
              v-else
              src="@/assets/Receiver.png"
              max-width="40"
              style="display: inline-block"
            />
          </v-btn>
        </v-col>
      </v-row>
      <v-progress-linear
        v-if="(loadingSend || loadingReceive) && loadingStage"
        height="14"
        indeterminate
      >
        <div class="text-caption">{{ loadingStage }}</div>
      </v-progress-linear>
    </v-card>
  </v-hover>
</template>

<script>
/*global sketchup*/
import gql from 'graphql-tag'
import { bus } from '../main'
import ObjectLoader from '@speckle/objectloader'
import { BaseObjectSerializer } from '../utils/serialization'

global.convertedFromSketchup = function (streamId, objects) {
  bus.$emit(`sketchup-objects-${streamId}`, objects)
}

global.finishedReceiveInSketchup = function (streamId) {
  bus.$emit(`sketchup-received-${streamId}`)
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
    return { loadingSend: false, loadingReceive: false, loadingStage: null, branchName: 'main' }
  },
  computed: {
    selectedBranch() {
      if (this.$apollo.loading) return
      return this.stream.branches.items.find((branch) => branch.name == this.branchName)
    }
  },
  mounted() {
    bus.$on(`sketchup-objects-${this.stream.id}`, async (objects) => {
      console.log('received objects from sketchup', objects)

      await this.createCommit(objects)
    })
    bus.$on(`sketchup-received-${this.stream.id}`, () => {
      console.log('finished receiving in sketchup', this.stream.id)
      this.loadingReceive = false
      this.loadingStage = null
    })
  },
  methods: {
    sleep(ms) {
      return new Promise((resolve) => setTimeout(resolve, ms))
    },
    openInWeb() {
      window.open(`${localStorage.getItem('serverUrl')}/streams/${this.stream.id}`)
    },
    switchBranch(branchName) {
      this.branchName = branchName
    },
    async receive() {
      this.loadingStage = 'requesting'
      this.loadingReceive = true
      const refId = this.selectedBranch.commits.items[0]?.referencedObject
      if (!refId) {
        this.loadingReceive = false
        this.loadingStage = null
        return
      }

      const loader = new ObjectLoader({
        serverUrl: localStorage.getItem('serverUrl'),
        token: localStorage.getItem('SpeckleSketchup.AuthToken'),
        streamId: this.stream.id,
        objectId: refId
      })

      let rootObj = await loader.getAndConstructObject(this.updateLoadingStage)
      console.log(rootObj)
      sketchup.receive_objects(rootObj, this.stream.id)
      this.loadingStage = 'converting'
    },
    updateLoadingStage({ stage }) {
      this.loadingStage = stage
    },
    async send() {
      this.loadingStage = 'converting'
      this.loadingSend = true
      sketchup.send_selection(this.stream.id)
      console.log('request for data sent to sketchup')
      await this.sleep(2000)
    },
    async createCommit(objects) {
      if (objects.length == 0) {
        this.loadingSend = false
        this.loadingStage = null
        return
      }

      this.loadingStage = 'serializing'
      let s = new BaseObjectSerializer()
      let { hash, serialized } = s.writeJson({ '@data': objects, speckle_type: 'Base' })

      try {
        this.loadingStage = 'uploading'
        this.loadingSend = true
        let batches = s.batchObjects()
        for (const batch of batches) {
          let res = await this.sendBatch(batch)
          if (res.status !== 201) throw `Upload request failed: ${res}`
        }

        let commit = {
          streamId: this.stream.id,
          branchName: this.branchName,
          objectId: hash,
          message: 'sent from sketchup',
          sourceApplication: 'sketchup',
          totalChildrenCount: s.objects[hash].totalChildrenCount
        }
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
        console.log('sent to stream: ' + this.stream.id, commit)

        this.loadingSend = false
        this.loadingStage = null
      } catch (err) {
        this.loadingSend = false
        this.loadingStage = null
        console.log(err)
      }
    },
    async sendBatch(batch) {
      let formData = new FormData()
      formData.append(`batch-1`, new Blob([JSON.stringify(batch)], { type: 'application/json' }))
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
