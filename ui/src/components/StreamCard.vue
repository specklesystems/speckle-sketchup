<template>
  <v-hover v-slot="{ hover }">
    <v-card color="" class="mt-5 mb-5" style="transition: all 0.2s ease-in-out">
      <v-row>
        <v-col v-if="$apollo.loading">
          <v-row>
            <v-col><v-skeleton-loader type="article" /></v-col>
          </v-row>
        </v-col>
        <v-col v-else>
          <v-toolbar class="transparent elevation-0" dense>
            <v-toolbar-title>{{ stream.name }}</v-toolbar-title>
            <v-spacer />
          </v-toolbar>
          <v-card-text class="transparent elevation-0 mt-0 pt-0" dense>
            <div class="text-caption">
              Updated
              <timeago class="mr-1" :datetime="stream.updatedAt" />
              |
              <v-icon class="ml-1" small>mdi-account-key-outline</v-icon>
              {{ stream.role.split(':')[1] }}
            </div>
            <v-toolbar-title>
              <v-menu offset-y>
                <template #activator="{ on, attrs }">
                  <v-chip v-if="stream.branches" small v-bind="attrs" class="mr-1" v-on="on">
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
                    <v-list-item-title class="text-caption font-weight-regular">
                      <v-icon v-if="branch.name == branchName" small class="mr-1 float-left">
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
            </v-toolbar-title>
          </v-card-text>
        </v-col>
        <v-col v-if="hover && !$apollo.loading" align="end" justify="center">
          <v-tooltip bottom>
            <template #activator="{ on, attrs }">
              <v-btn icon class="mr-4 btn-fix" v-bind="attrs" v-on="on" @click="openInWeb">
                <v-icon>mdi-open-in-new</v-icon>
              </v-btn>
            </template>
            <span>Open in web</span>
          </v-tooltip>

          <v-tooltip bottom>
            <template #activator="{ on, attrs }">
              <v-btn
                fab
                :loading="loadingSend"
                class="mr-4 elevation-1 btn-fix"
                hint="Send"
                v-bind="attrs"
                v-on="on"
                @click="send"
              >
                <v-img
                  v-if="$vuetify.theme.dark"
                  src="@/assets/SenderWhite.png"
                  max-width="40"
                  style="display: inline-block"
                />
                <v-img
                  v-else
                  src="@/assets/Sender.png"
                  max-width="40"
                  style="display: inline-block"
                />
              </v-btn>
            </template>
            <span>Send</span>
          </v-tooltip>

          <v-tooltip bottom>
            <template #activator="{ on, attrs }">
              <v-btn
                fab
                :loading="loadingReceive"
                class="mr-4 elevation-1 btn-fix"
                hint="Receive"
                v-bind="attrs"
                v-on="on"
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
            </template>
            <span>Receive</span>
          </v-tooltip>
        </v-col>
      </v-row>
      <transition-group name="expand">
        <v-card-text v-if="hover && !$apollo.loading" key="commit-message-field" class="mt-0 pt-0">
          <transition name="fade">
            <v-text-field
              v-model="commitMessage"
              class="small-text-field"
              hide-details
              dense
              flat
              label="Commit Message"
              placeholder="Write your commit message here"
            ></v-text-field>
          </transition>
        </v-card-text>
        <v-progress-linear
          v-if="(loadingSend || loadingReceive) && loadingStage"
          key="progress-bar"
          height="14"
          indeterminate
        >
          <div class="text-caption">{{ loadingStage }}</div>
        </v-progress-linear>
      </transition-group>
    </v-card>
  </v-hover>
</template>

<script>
/*global sketchup*/
import gql from 'graphql-tag'
import { bus } from '../main'
import streamQuery from '../graphql/stream.gql'
import ObjectLoader from '@speckle/objectloader'
import { BaseObjectSerializer } from '../utils/serialization'

global.convertedFromSketchup = function (streamId, objects) {
  bus.$emit(`sketchup-objects-${streamId}`, objects)
}

global.finishedReceiveInSketchup = function (streamId) {
  bus.$emit(`sketchup-received-${streamId}`)
}

global.sketchupOperationFailed = function (streamId) {
  bus.$emit(`sketchup-fail-${streamId}`)
}

export default {
  name: 'StreamCard',
  props: {
    streamId: {
      type: String,
      default: null
    }
  },
  data() {
    return {
      loadingSend: false,
      loadingReceive: false,
      loadingStage: null,
      branchName: 'main',
      commitId: 'latest',
      commitMessage: null
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
      if (this.$apollo.loading) return
      return this.stream.branches.items.find((branch) => branch.name == this.branchName)
    },
    selectedCommit() {
      if (this.$apollo.loading) return
      if (this.commitId == 'latest') return this.selectedBranch.commits.items[0]
      return this.selectedBranch.commits.items.find((commit) => commit.id == this.commitId)
    }
  },
  mounted() {
    bus.$on(`sketchup-objects-${this.streamId}`, async (objects) => {
      console.log('>>> SpeckleSketchUp: Received objects from sketchup')

      await this.createCommit(objects)
    })
    bus.$on(`sketchup-received-${this.streamId}`, () => {
      console.log('>>> SpeckleSketchUp: Finished receiving in sketchup', this.streamId)
      this.loadingReceive = false
      this.loadingStage = null
    })
    bus.$on(`sketchup-fail-${this.streamId}`, () => {
      this.$matomo && this.$matomo.setCustomUrl(`http://connectors/SketchUp/stream/fail`)
      this.$matomo && this.$matomo.trackPageView(`stream/fail`)
      console.log('>>> SpeckleSketchUp: operation failed', this.streamId)
      this.loadingReceive = this.loadingSend = false
      this.loadingStage = null
    })
  },
  methods: {
    sleep(ms) {
      return new Promise((resolve) => setTimeout(resolve, ms))
    },
    openInWeb() {
      window.open(`${localStorage.getItem('serverUrl')}/streams/${this.streamId}`)
      this.$matomo && this.$matomo.setCustomUrl(`http://connectors/SketchUp/stream/open-in-web`)
      this.$matomo && this.$matomo.trackPageView(`stream/open-in-web`)
    },
    switchBranch(branchName) {
      this.branchName = branchName
      this.commitId = 'latest'
    },
    switchCommit(commitId) {
      this.commitId = commitId
    },
    async receive() {
      this.loadingStage = 'requesting'
      this.loadingReceive = true
      this.$matomo && this.$matomo.setCustomUrl(`http://connectors/SketchUp/receive`)
      this.$matomo && this.$matomo.trackPageView(`receive`)
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
      console.log(rootObj)

      sketchup.receive_objects(rootObj, this.streamId)

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
      this.$matomo && this.$matomo.setCustomUrl(`http://connectors/SketchUp/send`)
      this.$matomo && this.$matomo.trackPageView(`send`)
      sketchup.send_selection(this.streamId)
      console.log('>>> SpeckleSketchUp: Objects requested from SketchUp')
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
        const totBatches = batches.length
        console.log(`>>> SpeckleSketchUp: ${totBatches} batches ready for sending`)
        let batchesSent = 0
        for (const batch of batches) {
          let res = await this.sendBatch(batch)
          if (res.status !== 201) throw `Upload request failed: ${res.status}`
          batchesSent++
          this.loadingStage = `uploading: ${Math.round((batchesSent / totBatches) * 100)}%`
        }

        let commit = {
          streamId: this.streamId,
          branchName: this.branchName,
          objectId: hash,
          message: this.commitMessage ?? 'sent from sketchup',
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
        console.log('>>> SpeckleSketchUp: Sent to stream: ' + this.streamId, commit)

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
