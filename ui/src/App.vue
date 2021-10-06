<template>
  <v-app>
    <v-main>
      <v-app-bar app flat>
        <v-img
          class="mx-auto"
          max-width="45"
          src="@/assets/logo.svg"
          style="display: inline-block"
        />
        <v-toolbar-title class="space-grotesk pl-0">
          {{ $route.name }}
        </v-toolbar-title>
        <v-spacer />
        <v-btn v-tooltip="'Refresh accounts and streams'" icon @click="requestRefresh">
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

      <v-container fluid>
        <router-view />
      </v-container>
    </v-main>
  </v-app>
</template>

<script>
/*global sketchup*/
import { bus } from './main'
import userQuery from './graphql/user.gql'

global.loadAccounts = function (accounts) {
  localStorage.setItem('localAccounts', JSON.stringify(accounts))
  global.setSelectedAccount(accounts.find((acct) => acct['isDefault']))
}

global.setSelectedAccount = function (account) {
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
