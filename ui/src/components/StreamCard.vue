<template>
  <v-card
    v-if="stream"
    :class="`mb-3 rounded-lg grey ${$vuetify.theme.dark ? 'darken-4' : 'lighten-4'}`"
    @mouseenter="hover = true"
    @mouseleave="hover = false"
  >
    <v-toolbar flat height="70" :color="getColor(invalid)">
      <v-btn v-tooptip="''" icon small outlined class="delta-btn" v-if="invalid" @click="activateDiffing">
        <v-icon v-if="!diffing" class="toggleUpDown" :class='{ "rotate": diffing }' small>mdi-eye-off-outline</v-icon>
        <v-icon v-else class="toggleUpDown" :class='{ "rotate": diffing }' small>mdi-eye</v-icon>
      </v-btn>
      <v-toolbar-title class="ml-0" style="position: relative; left: -10px">
        <!-- Uncomment when pinning is in place and add style="position: relative; left: -10px" to the element above :)  -->
        <v-btn
          v-tooltip="`Pin this ${streamText.toLowerCase()} - it will be saved to this file.`"
          icon
          x-small
          @click="toggleSavedStream"
        >
          <v-icon v-if="saved" x-small>mdi-pin</v-icon>
          <v-icon v-else x-small>mdi-pin-outline</v-icon>
        </v-btn>
        {{ stream.name }}
      </v-toolbar-title>
      <v-spacer />
      <v-slide-x-transition>
        <div v-show="hover" style="white-space: nowrap">
          <v-btn v-tooltip="'View online'" icon small class="mr-3" @click="openInWeb">
            <v-icon small>mdi-open-in-new</v-icon>
          </v-btn>
          <v-btn
            v-tooltip="'Send'"
            icon
            class="mr-3 elevation-2"
            :loading="loadingSend"
            @click="send"
          >
            <!-- <v-icon>mdi-upload</v-icon> -->
            <v-img v-if="$vuetify.theme.dark" src="@/assets/SenderWhite.png" max-width="30" />
            <v-img v-else src="@/assets/Sender.png" max-width="30" />
          </v-btn>
          <v-btn
            v-tooltip="'Receive'"
            icon
            class="elevation-2"
            :loading="loadingReceive"
            @click="receive"
          >
            <!-- <v-icon>mdi-download</v-icon> -->
            <v-img v-if="$vuetify.theme.dark" src="@/assets/ReceiverWhite.png" max-width="30" />
            <v-img v-else src="@/assets/Receiver.png" max-width="30" />
          </v-btn>
        </div>
      </v-slide-x-transition>
    </v-toolbar>
    <v-card-text class="caption pt-1 text-truncate" style="white-space: nowrap">
      Updated
      <timeago class="mr-1" :datetime="stream.updatedAt" />
      |
      <v-icon class="ml-1" small>mdi-account-key-outline</v-icon>
      {{ stream.role === null ? "" : stream.role.split(':')[1] }}
    </v-card-text>
    <v-card-text class="d-flex align-center pb-5 mb-5 -mt-2" style="height: 50px">
      <v-menu offset-y>
        <template #activator="{ on, attrs }">
          <v-slide-x-transition>
            <div v-show="hover">
              <create-branch-dialog :branch-tooltip-name="branchText" :stream-name="stream.name" :stream-id="streamId"/>
            </div>
          </v-slide-x-transition>
          <v-chip v-if="stream.branches" small v-bind="attrs" class="mr-1" v-on="on">
            <v-icon small class="mr-1 float-left">mdi-source-branch</v-icon>
            {{ branchName }}
          </v-chip>
        </template>
        <!-- Branch list -->
        <v-list dense>
          <v-list-item
            v-for="(branch, index) in stream.branches.items"
            :key="index"
            link
            @click="switchBranch(branch.name)"
          >
            <v-list-item-title class="text-caption font-weight-regular">
              <v-icon v-if="branch.name === branchName" small class="mr-1 float-left">
                mdi-check
              </v-icon>
              <v-icon v-else small class="mr-1 float-left">mdi-source-branch</v-icon>
              {{ branch.name }} ({{ branch.commits.totalCount }})
            </v-list-item-title>
          </v-list-item>
        </v-list>
      </v-menu>
      <v-menu offset-y>
        <template #activator="{ on, attrs }">
          <v-chip v-if="stream.commits" small v-bind="attrs" v-on="on">
            <v-icon small class="mr-1 float-left">mdi-source-commit</v-icon>
            {{ selectedBranch.commits.items.length ? commitId : 'no commits' }}
          </v-chip>
        </template>
        <v-list dense>
          <v-list-item
            v-for="(commit, index) in selectedBranch.commits.items"
            :key="index"
            link
            @click="switchCommit(commit.id)"
          >
            <v-list-item-title class="text-caption font-weight-regular">
              <v-icon
                v-if="(commitId == 'latest' && index == 0) || commit.id == commitId"
                small
                class="mr-1 float-left"
              >
                mdi-check
              </v-icon>
              <v-icon v-else small class="mr-1 float-left">mdi-source-commit</v-icon>
              {{ commit.id }} |
              <span class="font-weight-regular">{{ commit.message }} |</span>
              <span class="font-weight-light ml-1">
                <timeago :datetime="commit.createdAt" />
              </span>
            </v-list-item-title>
          </v-list-item>
        </v-list>
      </v-menu>
      <div class="flex-grow-1 px-4">
        <v-slide-y-transition>
          <div v-show="hover">
            <v-text-field
              v-model="commitMessage"
              xxxclass="small-text-field"
              hide-details
              dense
              flat
              :placeholder="`Write your ${commitText.toLowerCase()} message here`"
            />
          </div>
        </v-slide-y-transition>
      </div>
    </v-card-text>
    <v-progress-linear
      v-if="(loadingSend || loadingReceive) && loadingStage"
      key="progress-bar"
      height="14"
      indeterminate
    >
      <div class="text-caption">
        {{ loadingStage }}
      </div>
    </v-progress-linear>
  </v-card>
  <v-card v-else class="my-2">
    <v-skeleton-loader type="article" />
  </v-card>
</template>

<script>
/*global sketchup*/
import gql from 'graphql-tag'
import { bus } from '../main'
import streamQuery from '../graphql/stream.gql'
import ObjectLoader from '@speckle/objectloader'
import {HostApplications} from '@/utils/hostApplications'

global.convertedFromSketchup = function (streamId, batches, commitId, totalChildrenCount) {
  bus.$emit(`sketchup-objects-${streamId}`, batches, commitId, totalChildrenCount)
}

global.finishedReceiveInSketchup = function (streamId) {
  bus.$emit(`sketchup-received-${streamId}`)
}

global.sketchupOperationFailed = function (streamId) {
  bus.$emit(`sketchup-fail-${streamId}`)
}

global.oneClickSend = function (streamId) {
  bus.$emit(`one-click-send-${streamId}`)
}

export default {
  name: 'StreamCard',
  components: {
    CreateBranchDialog: () => import('@/components/dialogs/CreateBranchDialog'),
  },
  props: {
    streamId: {
      type: String,
      default: null
    },
    saved: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      hover: false,
      loadingSend: false,
      loadingReceive: false,
      loadingStage: null,
      branchName: 'main',
      commitId: 'latest',
      commitMessage: null,
      invalid: false,
      diffing: false,
      streamText: '',
      branchText: '',
      commitText: ''
    }
  },
  apollo: {
    stream: {
      prefetch: true,
      query: streamQuery,
      variables() {
        return {
          id: this.streamId
        }
      }
    },
    $subscribe: {
      commitCreated: {
        query: gql`
          subscription ($streamId: String!) {
            commitCreated(streamId: $streamId)
          }
        `,
        variables() {
          return {
            streamId: this.streamId
          }
        },
        result() {
          this.$apollo.queries.stream.refetch()
        }
      },
      branchCreated: {
        query: gql`
          subscription ($streamId: String!) {
            branchCreated(streamId: $streamId)
          }
        `,
        variables() {
          return { streamId: this.streamId }
        },
        result() {
          this.$apollo.queries.stream.refetch()
        }
      },
      branchDeleted: {
        query: gql`
          subscription ($streamId: String!) {
            branchDeleted(streamId: $streamId)
          }
        `,
        variables() {
          return { streamId: this.streamId }
        },
        result() {
          this.$apollo.queries.stream.refetch()
        }
      },
      branchUpdated: {
        query: gql`
          subscription ($streamId: String!) {
            branchUpdated(streamId: $streamId)
          }
        `,
        variables() {
          return { streamId: this.streamId }
        },
        result() {
          this.$apollo.queries.stream.refetch()
        }
      }
    }
  },
  computed: {
    selectedBranch() {
      if (!this.stream) return
      return this.stream.branches.items.find((branch) => branch.name === this.branchName)
    },
    selectedCommit() {
      if (!this.selectedBranch) return
      if (this.commitId === 'latest') return this.selectedBranch.commits.items[0]
      return this.selectedBranch.commits.items.find((commit) => commit.id === this.commitId)
    }
  },
  mounted() {
    bus.$on('update-preferences', async (preferences) => {
      const pref = JSON.parse(preferences)
      this.streamText = pref.user.fe2 ? 'Project' : 'Stream'
      this.branchText = pref.user.fe2 ? 'Model' : 'Branch'
      this.commitText = pref.user.fe2 ? 'Version' : 'Commit'
    })
    // Collect preferences to render UI according to it
    sketchup.exec({name: "collect_preferences", data: {}})

    bus.$on(`deactivate-diffing-${this.streamId}`, () => {
      this.diffing = false
    })
    bus.$on(`validate-stream-${this.streamId}`, () => {
      this.invalid = false
      console.log(`validate-stream-${this.streamId}`)
    })
    bus.$on(`invalidate-stream-${this.streamId}`, () => {
      this.invalid = true
      console.log(`invalidate-stream-${this.streamId}`)
    })
    bus.$on(`refresh-stream-${this.streamId}`, () => {
      let oldBranchName = this.branchName
      let oldCommitId = this.commitId
      this.$apollo.queries.stream.refetch()
      this.branchName = oldBranchName
      this.commitId = oldCommitId
    })
    bus.$on(`create-branch-${this.streamId}`, (branchName) => {
      this.$apollo.queries.stream.refetch()
      this.branchName = branchName
      this.commitId = 'latest'
    })
    bus.$on(`sketchup-objects-${this.streamId}`, async (batches, commitId, totalChildrenCount) => {
      console.log('>>> SpeckleSketchUp: Received objects from sketchup')

      await this.createCommit(batches, commitId, totalChildrenCount)
    })
    bus.$on(`sketchup-received-${this.streamId}`, () => {
      console.log('>>> SpeckleSketchUp: Finished receiving in sketchup', this.streamId)
      this.loadingReceive = false
      this.loadingStage = null
    })
    bus.$on(`sketchup-fail-${this.streamId}`, () => {
      this.$mixpanel.track('Connector Action', { name: 'Stream Fail' })
      console.log('>>> SpeckleSketchUp: operation failed', this.streamId)
      this.loadingReceive = this.loadingSend = false
      this.loadingStage = null
    })
    bus.$on(`one-click-send-${this.streamId}`, () => {
      this.$mixpanel.track('Send', { method: 'OneClick' })
    })

    if (this.saved) sketchup.exec({name: "notify_connected", data: {stream_id: this.streamId}})
  },
  methods: {
    getColor(invalid){
      if(invalid){
        return "#ffdfdf"
      } else {
        return ""
      }
    },
    sleep(ms) {
      return new Promise((resolve) => setTimeout(resolve, ms))
    },
    openInWeb() {
      window.open(`${localStorage.getItem('serverUrl')}/streams/${this.streamId}`)
      this.$mixpanel.track('Connector Action', { name: 'Open In Web' })
    },
    switchBranch(branchName) {
      this.$mixpanel.track('Connector Action', { name: 'Branch Switch' })
      this.branchName = branchName
      this.commitId = 'latest'
    },
    switchCommit(commitId) {
      this.$mixpanel.track('Connector Action', { name: 'Commit Switch' })
      this.commitId = commitId
    },
    activateDiffing(){
      if (this.diffing){
        this.diffing = false
        sketchup.exec({name: "deactivate_diffing", data: {}})
        return
      }
      this.diffing = true
      bus.$emit("deactivate-diffing-except", (this.streamId))
      sketchup.exec({name: "activate_diffing", data: {stream_id: this.streamId}})
    },
    toggleSavedStream() {
      if (this.saved) {
        sketchup.exec({name: "remove_stream", data: {stream_id: this.streamId}})
        this.$mixpanel.track('Connector Action', { name: 'Stream Remove' })
      } else {
        sketchup.exec({name: "save_stream", data: {stream_id: this.streamId}})
        this.$mixpanel.track('Connector Action', { name: 'Stream Save' })
      }
    },
    async receive() {
      this.loadingStage = 'requesting'
      this.loadingReceive = true
      const selectedAccount = JSON.parse(localStorage.getItem('selectedAccount'))
      const isMultiplayer = this.selectedCommit.authorId !== selectedAccount['userInfo']['id']
      const sourceApp = this.selectedCommit.sourceApplication
      const sourceAppSlug = HostApplications.GetHostAppFromString(sourceApp).slug
      this.$mixpanel.track('Receive', { isMultiplayer: isMultiplayer, sourceHostApp: sourceAppSlug, sourceHostAppVersion: sourceApp})
      const refId = this.selectedCommit?.referencedObject
      if (!refId) {
        this.loadingReceive = false
        this.loadingStage = null
        return
      }

      const loader = new ObjectLoader({
        serverUrl: localStorage.getItem('serverUrl'),
        token: localStorage.getItem('SpeckleSketchup.AuthToken'),
        streamId: this.streamId,
        objectId: refId
      })

      let rootObj = await loader.getAndConstructObject(this.updateLoadingStage)

      sketchup.exec({name:"receive_objects" , data: {
          base: rootObj,
          stream_name: this.stream.name,
          stream_id: this.streamId,
          branch_name: this.selectedCommit.branchName,
          branch_id: this.selectedCommit.id,
          source_app: this.selectedCommit.sourceApplication
      }})

      await this.$apollo.mutate({
        mutation: gql`
          mutation commitReceive($input: CommitReceivedInput!) {
            commitReceive(input: $input)
          }
        `,
        variables: {
          input: {
            sourceApplication: 'sketchup',
            streamId: this.streamId,
            commitId: this.selectedCommit.id
          }
        }
      })

      this.loadingStage = 'converting'
    },
    updateLoadingStage({ stage }) {
      this.loadingStage = stage
    },
    async send() {
      this.loadingStage = 'converting'
      this.loadingSend = true
      this.$mixpanel.track('Send')
      sketchup.exec({name:"send_selection" , data: {stream_id: this.streamId}})
      console.log('>>> SpeckleSketchUp: Objects requested from SketchUp')
      await this.sleep(2000)
    },
    async createCommit(batches, commitId, totalChildrenCount) {
      if (batches.length === 0) {
        this.loadingSend = false
        this.loadingStage = null
        this.$eventHub.$emit('notification', {
          text: 'No objects selected. Nothing was sent.\n'
        })
        return
      }

      try {
        this.loadingStage = 'uploading'
        this.loadingSend = true
        const totBatches = batches.length
        console.log(`>>> SpeckleSketchUp: ${totBatches} batches ready for sending`)
        let batchesSent = 0

        const t0 = Date.now()
        for (const batch of batches) {
          let res = await this.sendBatch(batch)
          if (res.status !== 201) throw `Upload request failed: ${res.status}`
          batchesSent++
          this.loadingStage = `uploading: ${Math.round((batchesSent / totBatches) * 100)}%`
        }

        const t1 = Date.now()
        const elapsedTime = (t1-t0) / 1000
        console.log(`Upload time: ${elapsedTime} second`)

        let commit = {
          streamId: this.streamId,
          branchName: this.branchName,
          objectId: commitId,
          message: this.commitMessage ?? 'sent from sketchup',
          sourceApplication: 'sketchup',
          totalChildrenCount: totalChildrenCount
        }
        let res = await this.$apollo.mutate({
          mutation: gql`
            mutation CommitCreate($commit: CommitCreateInput!) {
              commitCreate(commit: $commit)
            }
          `,
          variables: {
            commit: commit
          }
        })
        console.log('>>> SpeckleSketchUp: Sent to stream: ' + this.streamId, commit)
        this.$eventHub.$emit('notification', {
          text: 'Model selection sent!\n',
          action: {
            name: 'View in Web',
            url: `${localStorage.getItem('serverUrl')}/streams/${this.streamId}/commits/${
              res.data.commitCreate
            }`
          }
        })
        this.$apollo.queries.stream.refetch()
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
      formData.append(`batch-1`, new Blob([batch], { type: 'application/json' }))
      let token = localStorage.getItem('SpeckleSketchup.AuthToken')
      let res = await fetch(`${localStorage.getItem('serverUrl')}/objects/${this.streamId}`, {
        method: 'POST',
        headers: { Authorization: 'Bearer ' + token },
        body: formData
      })
      return res
    }
  }
}
</script>

<style scoped>
.delta-btn.v-btn--outlined {
  border: 1px solid #474747;
  background: white;
  margin-left: -90px;
  margin-top: -50px;
  position: absolute;
}

.toggleUpDown {
  transition: transform .3s ease-in-out !important;
}

.toggleUpDown.rotate {
  transform: rotate(180deg);
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease-in;
}
.fade-enter,
.fade-leave-to {
  opacity: 0;
}

.expand-enter-active {
  transition: all 0.2s ease;
  max-height: 1200px;
  overflow: hidden;
}
.expand-leave-active {
  transition: all 0.3s ease;
  max-height: 1200px;
  overflow: hidden;
}
.expand-enter,
.expand-leave-to {
  max-height: 0;
  opacity: 0;
}

.v-text-field >>> input {
  font-size: 0.9em;
}
.v-text-field >>> label {
  font-size: 0.9em;
}

.btn-fix:focus::before {
  opacity: 0 !important;
}
.btn-fix:hover::before {
  opacity: 0.08 !important;
}
</style>
