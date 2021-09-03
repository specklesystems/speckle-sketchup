<template>
  <v-app>
    <v-app-bar app flat>
      <v-toolbar-title class="space-grotesk pl-0">
        <v-icon class="mb-1 hidden-xs-only">mdi-folder</v-icon>
        Streams
      </v-toolbar-title>
      <v-spacer></v-spacer>
    </v-app-bar>
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
  </v-app>
</template>

<script>
/*global sketchup*/

export default {
  name: "Streams",
  computed: {},
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
