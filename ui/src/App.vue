<template>
  <v-app>
    <v-main>
      <v-app-bar app flat height="50">
        <v-img
          class="mx-auto px-0"
          max-width="45"
          src="@/assets/logo.svg"
          style="display: inline-block"
        />
        <v-tabs
            v-model="tab"
            align-tabs="title"
            class="mx-sm-1"
        >
          <v-tabs-slider class="mx-sm-1"></v-tabs-slider>
          <v-tab href="#streams">
            {{ streamsText }}
          </v-tab>
          <v-tab href="#mapper">
            {{"Mapper"}}
          </v-tab>
        </v-tabs>
        <v-spacer />
        <v-btn icon small class="mx-1" @click="requestRefresh">
          <v-icon>mdi-refresh</v-icon>
        </v-btn>
        <settings-dialog :preferences="preferences"/>
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
            <v-card-text v-if="accounts()">
              <v-divider class="my-3" />

              <div v-for="account in accounts()" :key="account.id">
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

      <v-tabs-items v-model="tab">
        <v-tab-item :key="1" value="streams">
          <v-container class="ma-0 pa-0">
            <v-container>
              <v-text-field
                  v-model="streamSearchQuery"
                  prepend-inner-icon="mdi-magnify"
                  :label="searchText"
                  background-color="background"
                  hide-details
                  clearable
                  rounded
                  filled
                  dense
                  flat
                  solo
              />
            </v-container>
            <create-stream-dialog
                v-if="accounts().length !== 0"
                :is-f-e2="preferences && preferences.user && preferences.user.fe2"
                :account-id="activeAccount().userInfo.id"
                :server-url="activeAccount().serverInfo.url"
            />
            <v-container v-if="accounts().length !== 0" fluid>
              <router-view :stream-search-query="streamSearchQuery" />
            </v-container>
            <v-container v-else>
              <login/>
            </v-container>
            <global-toast />
          </v-container>
        </v-tab-item>
        <v-tab-item :key="2" value="mapper">
          <v-card flat>
            <mapper :stream-text="streamText" :branch-text="branchText"></mapper>
          </v-card>
        </v-tab-item>
      </v-tabs-items>
    </v-main>
  </v-app>
</template>

<script>
/*global sketchup*/
import { bus } from './main'
import userQuery from './graphql/user.gql'
import { onLogin } from './vue-apollo'
import Login from "@/views/Login";

global.collectPreferences = function (preferences) {
  bus.$emit('update-preferences', preferences)
}

global.collectVersions = function (versions) {
  let vers = JSON.parse(versions)
  localStorage.setItem('hostAppVersion', vers.sketchup)
  localStorage.setItem('speckleVersion', vers.speckle)
}

global.loadAccounts = function (accounts) {
  console.log('>>> SpeckleSketchup: Loading accounts', accounts)
  localStorage.setItem('localAccounts', JSON.stringify(accounts))
  let uuid = localStorage.getItem('uuid')
  if (accounts.length !== 0){
    if (uuid) {
      global.setSelectedAccount(accounts.find((acct) => acct['userInfo']['id'] === uuid))
    } else {
      global.setSelectedAccount(accounts.find((acct) => acct['isDefault']))
    }
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
    Login,
    CreateStreamDialog: () => import('@/components/dialogs/CreateStreamDialog'),
    SettingsDialog: () => import('@/components/dialogs/SettingsDialog'),
    GlobalToast: () => import('@/components/GlobalToast'),
    Mapper: () => import('@/components/Mapper')
  },
  props: {
    size: {
      type: Number,
      default: 42
    }
  },
  data() {
    return {
      streamSearchQuery: null,
      createNewStreamDialog: false,
      createStreamByIdDialog: false,
      createStreamByIdText: "",
      preferences: {},
      tab: "streams",
      searchText: '',
      streamsText: 'Streams',
      streamText: 'Stream',
      branchText: 'Branch'
    }
  },
  computed: {
    loggedIn() {
      return localStorage.getItem('SpeckleSketchup.AuthToken') !== null
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

    bus.$on('update-preferences', async (preferences) => {
      this.preferences = JSON.parse(preferences)
      this.searchText = this.preferences.user.fe2 ? 'Search projects' : 'Search streams'
      this.streamsText = this.preferences.user.fe2 ? 'Projects' : 'Streams'
      this.streamText = this.preferences.user.fe2 ? 'Project' : 'Stream'
      this.branchText = this.preferences.user.fe2 ? 'Model' : 'Branch'
      this.$vuetify.theme.dark = this.preferences.user.dark_theme
    })

    // Collect versions to inform mixpanel
    sketchup.exec({name: "collect_versions", data: {}})

    // Collect preferences to render UI according to it
    sketchup.exec({name: "collect_preferences", data: {}})

    // Collect accounts from 'Accounts.db' by ruby sqlite3
    sketchup.exec({name: "init_local_accounts", data: {}})
  },
  methods: {
    accounts() {
      return JSON.parse(localStorage.getItem('localAccounts'))
    },
    activeAccount(){
      return this.accounts().find((account) => account['isDefault'])
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

<style>

/deep/ .v-toolbar__content {
  padding: 0px !important;
}

</style>
