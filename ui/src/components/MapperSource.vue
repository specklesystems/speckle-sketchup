<template>
  <v-container class="pa-0">
    <v-autocomplete
        v-model="sourceStreamId"
        label="Stream"
        :items="allStreamsList"
        item-text="name"
        item-value="id"
        density="compact"
    ></v-autocomplete>

    <v-autocomplete
        v-model="sourceBranchId"
        class="pt-0 mb-n5"
        label="Branch"
        :items="allBranchesList"
        :disabled="sourceStreamId === null"
        item-text="name"
        item-value="id"
        density="compact"
        @change="onSourceBranchChanged"
    ></v-autocomplete>
  </v-container>
</template>

<script>
/*global sketchup*/
import gql from "graphql-tag";
import streamQuery from "@/graphql/stream.gql";
import {bus} from "@/main";
import ObjectLoader from "@speckle/objectloader";

const streamLimit = 20

global.mapperSourceUpdated = function (streamId, levels, types) {
  console.log(JSON.stringify(levels), "levels")
  console.log(JSON.stringify(types), "types")
}

export default {
  name: "MappingSource",
  props: {
    streamSearchQuery: { type: String, default: null },
    sourceUpToDate: { type: Boolean },
  },
  data() {
    return {
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
        result() {
          this.afterCommitCreated()
            this.$eventHub.$emit('notification', {
                text: `A new commit was created on source stream!`,
            })
          this.$apollo.queries.stream.refetch()
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
      bus.$emit('set-source-up-to-date', true)
    })
  },
  methods: {
    afterCommitCreated(){
      bus.$emit('set-source-up-to-date', false)
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

      console.log(commitRefId)

      let rootObj = await loader.getAndConstructObject(this.updateLoadingStage)
      sketchup.exec({name:"mapper_source_updated" , data: {
          base: rootObj,
          stream_name: this.stream.name,
          stream_id: this.sourceStreamId,
          branch_name: this.selectedBranch.name,
          branch_id: this.selectedBranch.id
        }})
    }
  }
}

</script>

<style scoped>

</style>