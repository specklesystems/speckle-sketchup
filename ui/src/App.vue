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
        <v-toolbar-title class="space-grotesk">Speckle Sketchup</v-toolbar-title>
        <v-spacer />
        <v-btn icon small class="mx-1" @click="switchTheme">
          <v-icon>mdi-theme-light-dark</v-icon>
        </v-btn>
        <v-btn icon small class="mx-1" @click="requestRefresh">
          <v-icon>mdi-refresh</v-icon>
        </v-btn>
        <v-menu v-if="loggedIn" bottom min-width="200px" rounded offset-y>
          <template #activator="{ on, attrs }">
            <v-btn class="ml-1" icon x-large v-on="on">
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
                <v-btn
                  v-if="account.userInfo.id != user.id"
                  rounded
                  large
                  class="my-1 elevation-0"
                  @click="switchAccount(account)"
                >
                  <span style="white-space: normal">
                    <b>{{ account.userInfo.email }}</b>
                    <div class="caption">
                      {{ account.serverInfo.url }}
                    </div>
                  </span>
                </v-btn>
              </div>
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
    switchAccount(account) {
      global.setSelectedAccount(account)
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
