<template>
  <div>
    <v-row>
      <v-col v-if="$apollo.loading && !streams">
        <v-row>
          <v-col>
            <v-skeleton-loader type="card-heading, list-item-three-line" />
          </v-col>
        </v-row>
      </v-col>
    </v-row>
    <div v-if="!streamsFound" class="text-subtitle-1 text-center mt-8">No streams found... 👀</div>
    <div v-if="savedStreams" class="mt-5">
      <div v-for="streamId in savedStreams" :key="streamId">
        <stream-card :stream-id="streamId" :saved="true" />
      </div>
    </div>
    <div v-if="allStreamsList" class="mt-5">
      <div v-for="stream in allStreamsList" :key="stream.id">
        <stream-card :stream-id="stream.id"/>
      </div>
      <div class="actions text-center">
        <v-btn
          v-if="!$apollo.loading && showMoreEnabled"
          rounded
          class="mt-4"
          elevation="0"
          @click="showMore"
        >
          {{ `More ${streamsText}` }}
        </v-btn>
      </div>
    </div>
  </div>
</template>

<script>
/*global sketchup*/
import gql from 'graphql-tag'
import { bus } from '../main'

global.setSavedStreams = function (streamIds) {
  localStorage.setItem('savedStreams', JSON.stringify(streamIds))
  bus.$emit('set-saved-streams', streamIds)
}

global.updateInvalidStreams = function (streamIds) {
  bus.$emit('validate-streams')

  streamIds.forEach((id) => {
    bus.$emit(`invalidate-stream-${id}`)
  })
}

const streamLimit = 5
export default {
  name: 'Streams',
  components: {
    StreamCard: () => import('@/components/StreamCard')
  },
  props: {
    streamSearchQuery: { 
      type: String, 
      default: null 
    }
  },
  data() {
    return {
      showMoreEnabled: true,
      savedStreams: [],
      streamsText: ''
    }
  },
  computed: {
    streamsFound() {
      return (this.streams && this.streams?.items?.length !== 0) || this.savedStreams?.length !== 0
    },
    isSavedStream(streamId) {
      return this.savedStreams?.includes(streamId)
    },
    allStreamsList() {
      if (this.$apollo.loading) return
      return this.streams?.items.filter((stream) => !this.savedStreams?.includes(stream.id))
    }
  },
  mounted() {
    bus.$on('update-preferences', async (preferences) => {
      const pref = JSON.parse(preferences)
      this.streamsText = pref.user.fe2 ? 'Projects' : 'Streams'
    })

    // Collect preferences to render UI according to it
    sketchup.exec({name: "collect_preferences", data: {}})

    bus.$on("deactivate-diffing-except", (exceptedStreamId) => {
      this.savedStreams.forEach((streamId) => {
        if (streamId !== exceptedStreamId){
          bus.$emit(`deactivate-diffing-${streamId}`)
        }
      })
      this.allStreamsList.forEach((stream) => {
        if (stream.id !== exceptedStreamId){
          bus.$emit(`deactivate-diffing-${stream.id}`)
        }
      })
    })
    bus.$on('validate-streams', () => {
      this.savedStreams.forEach((streamId) => {
        bus.$emit(`validate-stream-${streamId}`)
      })
      this.allStreamsList.forEach((stream) => {
        bus.$emit(`validate-stream-${stream.id}`)
      })
    })
    bus.$on('refresh-streams', () => {
      // TODO: We should remember selected branches and commits before refetch
      this.$apollo.queries.streams.refetch()
      // TODO: We should set previously selected branches and commits after refetch
    })
    bus.$on('set-saved-streams', (streamIds) => {
      this.savedStreams = streamIds
    })
    bus.$on('stream-added-by-id-or-url', async(streamId, branchId, commitId) => {
      if (!this.savedStreams){
        this.savedStreams = []
        this.savedStreams.push(streamId)
        sketchup.exec({name: "save_stream", data: {stream_id: streamId}})
      } else {
        if (!this.savedStreams.includes(streamId)){
          this.savedStreams.push(streamId)
          
          sketchup.exec({name: "save_stream", data: {stream_id: streamId}})
        }
      }
      await bus.$emit(`set-stream-branch-commit-${streamId}`, branchId, commitId)
    })
    sketchup.exec({name: "load_saved_streams", data: {}})
    console.log('LAUNCHED')
    this.$mixpanel.track('Connector Action', { name: 'Launched' })
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
    },
    $subscribe: {
      userStreamAdded: {
        query: gql`
          subscription {
            userStreamAdded
          }
        `,
        result() {
          this.$apollo.queries.stream.refetch()
        }
      },
      userStreamRemoved: {
        query: gql`
          subscription {
            userStreamRemoved
          }
        `,
        result() {
          this.$apollo.queries.stream.refetch()
        }
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
