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
        <v-text-field
          v-model="streamSearchQuery"
          prepend-inner-icon="mdi-magnify"
          label="Search streams"
          hide-details
          clearable
          rounded
          filled
          dense
          flat
          solo
        />
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
              <v-divider class="my-3" />

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

      <create-stream/>

      <v-container fluid>
        <router-view :stream-search-query="streamSearchQuery" />
      </v-container>
      <global-toast />
    </v-main>
  </v-app>
</template>

<script>
/*global sketchup*/
import { bus } from './main'
import userQuery from './graphql/user.gql'
import { onLogin } from './vue-apollo'
import CreateStream from "@/components/CreateStream";

global.loadAccounts = function (accounts) {
  console.log('>>> SpeckleSketchup: Loading accounts', accounts)
  localStorage.setItem('localAccounts', JSON.stringify(accounts))
  let uuid = localStorage.getItem('uuid')
  if (uuid) {
    global.setSelectedAccount(accounts.find((acct) => acct['userInfo']['id'] == uuid))
  } else {
    global.setSelectedAccount(accounts.find((acct) => acct['isDefault']))
  }
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
  components: {
    CreateStream: () => import('@/components/CreateStream'),
    GlobalToast: () => import('@/components/GlobalToast')
  },
  props: {
    size: {
      type: Number,
      default: 42
    },
  },
  data() {
    return {
      streamSearchQuery: null,
      createNewStreamDialog: false,
      createStreamByIdDialog: false,
      createStreamByIdText: ""
    }
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
      query: userQuery
    }
  },
  mounted() {
    bus.$on('selected-account-reloaded', async () => {
      await onLogin(this.$apollo.provider.defaultClient)
      this.$refreshMixpanelIds()
      this.refresh()
    })
    bus.$on('streams-loaded', () => {
      // on first load, the user query seems to be firing before the apollo client is ready.
      // this refetches the user in this scenario
      if (!this.user) this.$apollo.queries.user.refetch()
    })

    this.$vuetify.theme.dark = localStorage.getItem('theme') == 'dark'
    sketchup.exec({name: "init_local_accounts", data: {}})
  },
  methods: {
    switchTheme() {
      this.$vuetify.theme.dark = !this.$vuetify.theme.dark
      localStorage.setItem('theme', this.$vuetify.theme.dark ? 'dark' : 'light')
      this.$mixpanel.track('Connector Action', { name: 'Toggle Theme' })
    },
    switchAccount(account) {
      this.$mixpanel.track('Connector Action', { name: 'Account Select' })
      global.setSelectedAccount(account)
    },
    requestRefresh() {
      sketchup.exec({name: 'reload_accounts', data: {}})
      sketchup.exec({name: "load_saved_streams", data: {}})
      this.refresh()
    },
    refresh() {
      this.$mixpanel.track('Connector Action', { name: 'Refresh' })
      this.$apollo.queries.user.refetch()
      bus.$emit('refresh-streams')
    }
  }
}
</script>
