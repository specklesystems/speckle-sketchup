<template>
  <v-container>
    <streams-list />

    <!-- testing sketchup bindings -->
    <v-container>
      <v-card>
        <v-card-title>Testing Sketchup Bindings</v-card-title>
        <v-card-text>
          <div class="d-flex align-center">
            Name: <v-text-field v-model="name" hint="Name" class="ml-3" />
          </div>
          <div class="d-flex align-center">
            Pokes: <v-text-field v-model.number="num_pokes" class="ml-3" />
          </div>
          <v-btn @click="poke">Poke {{ name }}!</v-btn>
        </v-card-text>
      </v-card>
    </v-container>
  </v-container>
</template>

<script>
/*global sketchup*/
import userQuery from "../graphql/user.gql";

export default {
  name: "Streams",
  computed: {},
  apollo: {
    user: {
      query: userQuery,
    },
  },
  data() {
    return {
      name: "Dim",
      num_pokes: 3,
    };
  },
  methods: {
    poke: function () {
      sketchup.poke(this.name, this.num_pokes);
    },
  },

  components: {
    StreamsList: () => import("@/components/StreamsList"),
  },
};
</script>
