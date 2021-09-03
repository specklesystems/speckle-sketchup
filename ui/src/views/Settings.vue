<template>
  <v-app>
    <v-app-bar app flat>
      <v-toolbar-title class="space-grotesk pl-0">
        <v-icon class="mb-1 hidden-xs-only">mdi-cog</v-icon>
        Settings
      </v-toolbar-title>
      <v-spacer></v-spacer>
    </v-app-bar>
    <streams-list />
  </v-app>
</template>

<script>
export default {
  name: "Streams",
  computed: {},

  components: {
    StreamsList: () => import("@/components/StreamsList"),
  },
};
</script>
