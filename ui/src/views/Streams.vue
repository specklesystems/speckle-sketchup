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
      <stream-card :stream="stream" />
    </div>
  </v-container>
</template>

<script>
import streamsQuery from '../graphql/streams.gql'

export default {
  name: 'Streams',
  apollo: {
    streams: {
      prefetch: true,
      query: streamsQuery,
      fetchPolicy: 'cache-and-network',
      update(data) {
        return data.streams.items
      }
    }
  },
  components: {
    StreamCard: () => import('@/components/StreamCard')
  },
  data() {
    return {
      streams: []
    }
  },
  methods: {}
}
</script>
