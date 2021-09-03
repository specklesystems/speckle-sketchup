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
    <v-card v-for="stream in streams" :key="stream.id">
      <v-card-title>{{ stream.name }}</v-card-title>
    </v-card>

    <streams-list />
  </v-container>
</template>

<script>
import streamsQuery from "../graphql/streams.gql";

export default {
  name: "Streams",
  computed: {},
  apollo: {
    streams: {
      prefetch: true,
      query: streamsQuery,
      fetchPolicy: "cache-and-network",
      update(data) {
        return data.streams.items;
      },
    },
  },
  data() {
    return {
      streams: [],
    };
  },
  methods: {},
  components: {
    StreamsList: () => import("@/components/StreamsList"),
  },
};
</script>
