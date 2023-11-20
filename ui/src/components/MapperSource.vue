<template>
  <v-container class="pa-0">
    <v-autocomplete
        v-model="sourceStreamId"
        :label="streamText"
        :items="allStreamsList"
        item-text="name"
        item-value="id"
        density="compact"
    ></v-autocomplete>

    <v-autocomplete
        v-model="sourceBranchId"
        class="pt-0 mb-n5"
        :label="branchText"
        :items="allBranchesList"
        :disabled="sourceStreamId === null"
        item-text="name"
        item-value="id"
        density="compact"
    ></v-autocomplete>

    <v-container class="pa-0 mt-2">
      <v-row justify="center" align="center">
        <v-col cols="auto" class="pa-1 pb-2">
          <v-btn
              small
              @click="applySource"
          >
            <v-icon dark left>
              mdi-checkbox-marked-circle
            </v-icon>Apply
          </v-btn>
        </v-col>
        <v-col cols="auto" class="pa-1 pb-2">
          <v-btn
              small
              :disabled="!sourceApplied"
              @click="clearSource"
          >
            <v-icon dark left>
              mdi-close-circle
            </v-icon>Clear
          </v-btn>
        </v-col>
      </v-row>

    </v-container>
  </v-container>
</template>

<script>
/*global sketchup*/
import gql from "graphql-tag";
import streamQuery from "@/graphql/stream.gql";
import {bus} from "@/main";
import ObjectLoader from "@speckle/objectloader";

const streamLimit = 20

export default {
  name: "MappingSource",
  props: {
    streamSearchQuery: { type: String, default: null },
    sourceState: { type: String, default: 'Not Set' },
    streamText: {
      type: String,
      default: ''
    },
    branchText: {
      type: String,
      default: ''
    }
  },
  data() {
    return {
      sourceApplied: false,
      sourceStreamId: null,
      sourceBranchId: null,
      sourceStreamName: null,
      sourceBranchName: null
    }
  },
  apollo: {
    streams: {
      prefetch: true,
      debounce: 300,
      fetchPolicy: 'cache-and-network',
      query: gql`
        query Streams($query: String, $limit: Int, $cursor: String) {
          streams(query: $query, limit: $limit, cursor: $cursor) {
            totalCount
            cursor
            items {
              id
              name
            }
          }
        }
      `,
      variables() {
        return {
          query: this.streamSearchQuery,
          limit: streamLimit,
          cursor: null
        }
      },
      update(data) {
        bus.$emit('streams-loaded')
        this.showMoreEnabled = data.streams?.items.length < data.streams.totalCount
        return data.streams
      },
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
            streamId: this.sourceStreamId
          }
        },
        result(data) {
          if (data.data.commitCreated.sourceApplication.includes('Revit')){
            if (data.data.commitCreated.branchName === this.selectedBranch.name){
              this.afterCommitCreated()
              this.$eventHub.$emit('notification', {
                text: `A new commit was created on Revit!`,
              })
              this.$apollo.queries.stream.refetch()
            }
          }
        },
        skip() {
            // Return true to skip the initial query execution
            return this.sourceStreamId === null;
        },
      }
    },
    stream: {
      query: streamQuery,
      prefetch: true,
      variables() {
        return {
          id: this.sourceStreamId
        }
      },
      skip() {
        // Return true to skip the initial query execution
        return this.sourceStreamId === null;
      },
    }
  },
  computed: {
    selectedBranch() {
      if (!this.stream) return
      return this.stream.branches.items.find((branch) => branch.id === this.sourceBranchId)
    },
    allStreamsList() {
      if (this.$apollo.loading) return
      return this.streams?.items
    },
    allBranchesList() {
      if (this.$apollo.loading) return
      return this.stream?.branches.items
    },
  },
  mounted() {
    bus.$on('refresh-source-branch', () => {
      this.onSourceBranchChanged()
      bus.$emit('set-source-up-to-date', 'Set')
    })
  },
  methods: {
    applySource(){
      bus.$emit('set-source-up-to-date', 'Set')
      this.onSourceBranchChanged()
      this.$eventHub.$emit('success', {
        text: 'Mapper source applied.\n'
      })
      this.$mixpanel.track('MappingsAction', { name: 'Mappings Source Apply' })
    },
    clearSource(){
      sketchup.exec({name:"clear_mapper_source" , data: {}})
      bus.$emit('set-source-up-to-date', 'Not Set')
      this.sourceApplied = false
      this.sourceBranchName = null
      this.sourceStreamName = null
      this.sourceBranchId = null
      this.sourceStreamId = null
      this.$eventHub.$emit('error', {
        text: 'Mapper source cleared.\n'
      })
    },
    afterCommitCreated(){
      bus.$emit('set-source-up-to-date', 'Outdated')
    },
    async onSourceBranchChanged() {
      const commitRefId = this.selectedBranch.commits.items[0]?.referencedObject
      if (!commitRefId) { return }

      const loader = new ObjectLoader({
        serverUrl: localStorage.getItem('serverUrl'),
        token: localStorage.getItem('SpeckleSketchup.AuthToken'),
        streamId: this.sourceStreamId,
        objectId: commitRefId
      })

      let rootObj = await loader.getAndConstructObject(this.updateLoadingStage)
      sketchup.exec({name:"mapper_source_updated" , data: {
          base: rootObj,
          stream_id: this.sourceStreamId,
          commit_id: commitRefId
        }})
      this.sourceApplied = true
    }
  }
}

</script>

<style scoped>

</style>