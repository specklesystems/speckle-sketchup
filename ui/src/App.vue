<template>
  <v-app>
    <v-main>
      <v-navigation-drawer
        :app="!$vuetify.breakpoint.xsOnly"
        permanent
        mini-variant
        :expand-on-hover="true || $vuetify.breakpoint.mdAndUp"
        floating
        stateless
        fixed
        :color="`${$vuetify.theme.dark ? 'grey darken-4' : 'grey lighten-4'}`"
        :dark="$vuetify.theme.dark"
        style="z-index: 100"
        :class="`elevation-5 hidden-xs-only`"
        mini-variant-width="56"
      >
        <v-toolbar class="transparent elevation-0">
          <v-toolbar-title class="space-grotesk primary--text">
            <router-link to="/" class="text-decoration-none">
              <v-img
                class="mt-2"
                max-width="30"
                src="@/assets/logo.svg"
                style="display: inline-block"
              />
            </router-link>
            <router-link
              to="/"
              class="text-decoration-none"
              style="position: relative; top: -4px; margin-left: 20px"
            >
              <span class="pb-4"><b>Speckle</b></span>
            </router-link>
          </v-toolbar-title>
        </v-toolbar>

        <v-list>
          <v-list-item link to="/" style="height: 59px">
            <v-list-item-icon>
              <v-icon>mdi-folder</v-icon>
            </v-list-item-icon>
            <v-list-item-content>
              <v-list-item-title>Streams</v-list-item-title>
              <v-list-item-subtitle class="caption"
                >All your streams.</v-list-item-subtitle
              >
            </v-list-item-content>
          </v-list-item>

          <v-list-item link to="/settings" style="height: 59px">
            <v-list-item-icon>
              <v-icon>mdi-cog</v-icon>
            </v-list-item-icon>
            <v-list-item-content>
              <v-list-item-title>Settings</v-list-item-title>
              <v-list-item-subtitle class="caption"
                >Latest events.</v-list-item-subtitle
              >
            </v-list-item-content>
          </v-list-item>

          <v-divider></v-divider>
        </v-list>

        <template v-slot:append>
          <v-list dense>
            <v-list-item
              link
              href="https://speckle.community/new-topic?category=features"
              target="_blank"
              class="primary"
              dark
            >
              <v-list-item-icon>
                <v-icon small class="ml-1">mdi-comment-arrow-right</v-icon>
              </v-list-item-icon>
              <v-list-item-content>
                <v-list-item-title>Feedback</v-list-item-title>
              </v-list-item-content>
            </v-list-item>

            <v-list-item link @click="switchTheme">
              <v-list-item-icon>
                <v-icon small class="ml-1">mdi-theme-light-dark</v-icon>
              </v-list-item-icon>
              <v-list-item-content>
                <v-list-item-title>Switch Theme</v-list-item-title>
              </v-list-item-content>
            </v-list-item>
          </v-list>
        </template>
      </v-navigation-drawer>

      <router-view />

      <v-bottom-navigation
        fixed
        xxx-hide-on-scroll
        class="hidden-sm-and-up elevation-20"
      >
        <v-btn color="primary" text to="/" style="height: 100%">
          <span>Streams</span>
          <v-icon>mdi-folder</v-icon>
        </v-btn>

        <v-btn color="primary" text to="/settings" style="height: 100%">
          <span>Settings</span>
          <v-icon>mdi-cog</v-icon>
        </v-btn>
      </v-bottom-navigation>
    </v-main>
  </v-app>
</template>

<script>
export default {
  name: "App",
  created() {
    this.$store.dispatch("loadAccounts");
  },
  methods: {
    switchTheme() {
      this.$vuetify.theme.dark = !this.$vuetify.theme.dark;
      localStorage.setItem(
        "darkModeEnabled",
        this.$vuetify.theme.dark ? "dark" : "light"
      );
    },
  },
  data: () => ({
    //
  }),
};
</script>
