<template>
  <v-container>
    <v-row>
      <v-col v-if="$apollo.loading && !streams">
        <v-row>
          <v-col>
            <v-skeleton-loader type="card-heading, list-item-three-line"></v-skeleton-loader>
          </v-col>
        </v-row>
      </v-col>
    </v-row>
    <div v-if="!streamsFound" class="text-subtitle-1 text-center mt-8">No streams found... 👀</div>
    <div v-if="streams">
      <div v-for="stream in streams.items" :key="stream.id">
        <stream-card :stream-id="stream.id" />
      </div>
      <div class="actions text-center">
        <v-btn
          v-if="!$apollo.loading && showMoreEnabled"
          rounded
          class="mt-4"
          elevation="0"
          @click="showMore"
        >
          More Streams
        </v-btn>
      </div>
    </div>
  </v-container>
</template>

<script>
import gql from 'graphql-tag'
import { bus } from '../main'

const streamLimit = 5
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
      showMoreEnabled: true
    }
  },
  computed: {
    streamsFound() {
      return this.streams && this.streams?.items?.length != 0
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
        query Streams($query: String, $limit: Int, $cursor: String) {
          streams(query: $query, limit: $limit, cursor: $cursor) {
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
    }
  },
  methods: {
    showMore() {
      // Fetch more data and transform the original result
      this.$apollo.queries.streams.fetchMore({
        // New variables
        variables: {
          query: this.streamSearchQuery,
          limit: streamLimit,
          cursor: this.streams.cursor
        },
        // Transform the previous result with new data
        updateQuery: (previousResult, { fetchMoreResult }) => {
          const newStreams = fetchMoreResult.streams?.items
          if (!newStreams) return previousResult.streams
          this.cursor = fetchMoreResult.streams.cursor
          return {
            streams: {
              __typename: previousResult.streams.__typename,
              cursor: fetchMoreResult.streams.cursor,
              totalCount: fetchMoreResult.streams.totalCount,
              // Merging the lists
              items: [...previousResult.streams.items, ...newStreams]
            }
          }
        }
      })
    }
  }
}
</script>
