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
    ></v-autocomplete>
  </v-container>
</template>

<script>
/*global sketchup*/
import gql from "graphql-tag";
import streamQuery from "@/graphql/stream.gql";
import {bus} from "@/main";

const streamLimit = 20

export default {
  name: "MappingSource",
  props: {
    streamSearchQuery: { type: String, default: null }
  },
  data() {
    return {
      sourceStreamId: null,
      sourceBranchId: null,
      sourceStreamName: null,
      sourceBranchName: null,
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
      }
    },
    stream: {
      query: streamQuery,
      prefetch: false,
      variables() {
        return {
          id: this.sourceStreamId
        }
      }
    }
  },
  computed: {
    allStreamsList() {
      if (this.$apollo.loading) return
      return this.streams?.items
    },
    allBranchesList() {
      if (this.$apollo.loading) return
      return this.stream?.branches.items
    },
  }
}

</script>

<style scoped>

</style>