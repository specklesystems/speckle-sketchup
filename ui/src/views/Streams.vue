<template>
  <v-container>
    <v-row>
      <v-col v-if="$apollo.loading">
        <v-row>
          <v-col>
            <v-skeleton-loader type="card"></v-skeleton-loader>
          </v-col>
        </v-row>
      </v-col>
    </v-row>
    <div v-for="stream in streams" :key="stream.id">
      <stream-card :stream-id="stream.id" />
    </div>
    <div v-if="!$apollo.loading && streams.length == 0" class="text-subtitle-1 text-center mt-8">
      No streams found... 👀
    </div>
  </v-container>
</template>

<script>
import gql from 'graphql-tag'
import { bus } from '../main'

export default {
  name: 'Streams',
  components: {
    StreamCard: () => import('@/components/StreamCard')
  },
  props: {
    streamSearchQuery: { type: String, default: null }
  },
  data() {
    return {
      streams: []
    }
  },
  mounted() {
    bus.$on('refresh-streams', () => {
      this.$apollo.queries.streams.refetch()
    })
  },
  apollo: {
    streams: {
      prefetch: true,
      debounce: 300,
      fetchPolicy: 'cache-and-network',
      query: gql`
        query Streams($query: String) {
          streams(query: $query) {
            totalCount
            cursor
            items {
              id
            }
          }
        }
      `,
      variables() {
        return {
          query: this.streamSearchQuery
        }
      },
      update(data) {
        return data.streams.items
      }
    }
  },
  methods: {}
}
</script>
