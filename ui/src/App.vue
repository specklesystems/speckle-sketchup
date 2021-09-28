<template>
  <v-app>
    <v-main>
      <v-app-bar app flat>
        <v-toolbar-title class="space-grotesk pl-0">
          {{ $route.name }}
        </v-toolbar-title>
        <v-spacer />
        <v-btn icon @click="requestRefresh">
          <v-icon>mdi-refresh</v-icon>
        </v-btn>
        <v-menu v-if="loggedIn" bottom min-width="200px" rounded offset-y open-on-hover>
          <template #activator="{ on, attrs }">
            <v-btn icon x-large v-on="on">
              <v-avatar
                v-if="user"
                class="ma-1"
                color="grey lighten-3"
                :size="size"
                v-bind="attrs"
                v-on="on"
              >
                <v-img v-if="user.avatar" :src="user.avatar" />
                <v-img v-else :src="`https://robohash.org/` + user.id + `.png?size=40x40`" />
              </v-avatar>
            </v-btn>
          </template>
          <v-card v-if="user">
            <v-card-text v-if="!$apollo.loading" class="text-center">
              <v-avatar class="my-4" color="grey lighten-3" :size="40">
                <v-img v-if="user.avatar" :src="user.avatar" />
                <v-img v-else :src="`https://robohash.org/` + user.id + `.png?size=40x40`" />
              </v-avatar>
              <div>
                <b>{{ user.name }}</b>
              </div>
              <div class="caption">
                {{ user.company }}
                <br />
                {{ user.bio ? 'Bio: ' + user.bio : '' }}
              </div>
            </v-card-text>
            <v-card-text v-if="accounts">
              <v-divider class="my-3"></v-divider>
              <div v-for="account in accounts" :key="account.id">
                <b>{{ account.userInfo.name }}</b>
                <div class="caption">
                  {{ account.userInfo.company }}
                </div>
              </div>
              <v-divider class="my-3"></v-divider>
              <v-btn depressed rounded text>Disconnect</v-btn>
            </v-card-text>
          </v-card>
        </v-menu>
      </v-app-bar>
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
              <v-list-item-subtitle class="caption">All your streams.</v-list-item-subtitle>
            </v-list-item-content>
          </v-list-item>

          <v-list-item link to="/settings" style="height: 59px">
            <v-list-item-icon>
              <v-icon>mdi-cog</v-icon>
            </v-list-item-icon>
            <v-list-item-content>
              <v-list-item-title>Settings</v-list-item-title>
              <v-list-item-subtitle class="caption">App settings</v-list-item-subtitle>
            </v-list-item-content>
          </v-list-item>

          <v-divider></v-divider>
        </v-list>

        <template #append>
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

      <v-container fluid>
        <router-view />
      </v-container>

      <v-bottom-navigation fixed xxx-hide-on-scroll class="hidden-sm-and-up elevation-20">
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
/*global sketchup*/
import { bus } from './main'
import userQuery from './graphql/user.gql'

global.loadAccounts = function (accounts) {
  console.log('IN LOAD ACCOUNTS', accounts)
  localStorage.setItem('localAccounts', JSON.stringify(accounts))
  global.setSelectedAccount(accounts.find((acct) => acct['isDefault']))
}

global.setSelectedAccount = function (account) {
  console.log('IN SET SELECTED ACCT', account)
  localStorage.setItem('selectedAccount', JSON.stringify(account))
  localStorage.setItem('serverUrl', account['serverInfo']['url'])
  localStorage.setItem('SpeckleSketchup.AuthToken', account['token'])
  localStorage.setItem('uuid', account['userInfo']['id'])
  bus.$emit('selected-account-reloaded')
}

export default {
  name: 'App',
  components: {},
  props: {
    size: {
      type: Number,
      default: 42
    }
  },
  data: function () {
    return {}
  },
  computed: {
    loggedIn() {
      return localStorage.getItem('SpeckleSketchup.AuthToken') !== null
    },
    accounts() {
      return JSON.parse(localStorage.getItem('localAccounts'))
    }
  },
  apollo: {
    user: {
      prefetch: true,
      query: userQuery,
      update(data) {
        return data.user
      }
    }
  },
  mounted() {
    bus.$on('selected-account-reloaded', () => {
      this.refresh()
    })
  },
  methods: {
    switchTheme() {
      this.$vuetify.theme.dark = !this.$vuetify.theme.dark
      localStorage.setItem('darkModeEnabled', this.$vuetify.theme.dark ? 'dark' : 'light')
    },
    requestRefresh() {
      sketchup.reload_accounts()
    },
    refresh() {
      this.$apollo.queries.user.refetch()
      bus.$emit('refresh-streams')
    }
  }
}
</script>
