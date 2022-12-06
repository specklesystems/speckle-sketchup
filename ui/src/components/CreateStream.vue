<template>
  <v-container fluid class="px-1 pb-0 pt-1">
    <v-row>
      <v-col>
        <!-- DIALOG: Create New Stream -->
        <v-dialog v-model="showCreateNewStream">
          <template #activator="{ on, attrs }">
            <v-btn
                class="ma-2 pa-3"
                x-small
                v-bind="attrs"
                v-on="on"
            >
              <v-icon
                  dark
                  left
              >
                mdi-plus-circle
              </v-icon>Create New Stream
            </v-btn>
          </template>

          <v-card>
            <v-card-title class="text-h5">
              Create a New Stream
            </v-card-title>
            <v-container class="px-6" pb-0>
              <!--
              <v-menu offset-y class="pb-3">
                <template #activator="{ on, attrs }">
                  <v-chip v-if="accounts" small v-bind="attrs" v-on="on">
                    <v-icon small class="mr-1 float-left">mdi-account</v-icon>
                    {{ accountToCreateStream === null ?
                      activeAccount().userInfo.email + activeAccount().serverInfo.url:
                      accountToCreateStream.userInfo.email + accountToCreateStream.serverInfo.url }}
                  </v-chip>
                </template>
                <v-list dense>
                  <v-list-item
                      v-for="(account, index) in accounts"
                      :key="index"
                      link
                      @click="switchAccountToCreateStream(account)"
                  >
                    <v-list-item-title class="text-caption font-weight-regular">
                      {{ account.userInfo.email }} ({{ account.serverInfo.url }})
                    </v-list-item-title>
                  </v-list-item>
                </v-list>
              </v-menu>
              -->
              <v-text-field
                  v-model="streamName"
                  xxxclass="small-text-field"
                  hide-details
                  dense
                  flat
                  placeholder="Stream Name (Optional)"
              />
              <v-text-field
                  v-model="description"
                  xxxclass="small-text-field"
                  hide-details
                  dense
                  flat
                  placeholder="Description (Optional)"
              />
              <v-switch
                  v-model="privateStream"
                  :label="'Private Stream'"
              ></v-switch>
            </v-container>

            <v-card-actions>
              <v-spacer></v-spacer>
              <v-btn
                  color="blue darken-1"
                  text
                  @click="showCreateNewStream = false"
              >
                Cancel
              </v-btn>
              <v-btn
                  color="blue darken-1"
                  text
                  @click="createStream"
              >
                Create
              </v-btn>
            </v-card-actions>
          </v-card>
        </v-dialog>

        <!-- DIALOG: Add a Stream by ID or URL -->
        <v-dialog v-model="showCreateStreamById">
          <template #activator="{ on, attrs }">
            <v-btn
                class="ma-2 pa-3"
                x-small
                min-width="163"
                v-bind="attrs"
                v-on="on"
            >
              <v-icon
                  dark
                  left
              >
                mdi-link-plus
              </v-icon>Add By ID or URL
            </v-btn>
          </template>

          <v-card>
            <v-card-title class="text-h5">
              Add a Stream by ID or URL
            </v-card-title>
            <v-card-text>
              Stream IDs and Stream/Branch/Commit URLs are supported.
            </v-card-text>
            <v-container class="px-6">
              <v-text-field
                  v-model="createStreamByIdText"
                  xxxclass="small-text-field"
                  hide-details
                  dense
                  flat
                  placeholder="Stream URL"
              />
            </v-container>
            <v-card-actions>
              <v-spacer></v-spacer>
              <v-btn
                  color="blue darken-1"
                  text
                  @click="showCreateStreamById = false"
              >
                Cancel
              </v-btn>
              <v-btn
                  :disabled="createStreamByIdText === ''"
                  color="blue darken-1"
                  text
                  @click="showCreateStreamById = false"
              >
                Add
              </v-btn>
            </v-card-actions>
          </v-card>
        </v-dialog>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
/*global sketchup*/
import gql from "graphql-tag";

export default {
  name: "CreateStream",
  data() {
    return {
      showCreateNewStream: false,
      showCreateStreamById: false,
      createStreamByIdText: "",
      privateStream: false,
      streamName: "",
      description: "",
      defaultDescription: "Stream created from SketchUp",
      accountToCreateStream: null
    }
  },
  computed: {
    loggedIn() {
      return localStorage.getItem('SpeckleSketchup.AuthToken') !== null
    },
    accounts() {
      return JSON.parse(localStorage.getItem('localAccounts'))
    },
  },
  methods: {
    activeAccount(){
      return JSON.parse(localStorage.getItem('selectedAccount'))
    },
    switchAccountToCreateStream(account) {
      this.accountToCreateStream = account
    },
    async createStream(){
      let res = await this.$apollo.mutate({
        mutation: gql`
            mutation streamCreate($stream: StreamCreateInput!) {
              streamCreate(stream: $stream)
            }
          `,
        variables: {
          stream: {
            name: this.streamName,
            description: this.description === '' ? this.defaultDescription : this.description,
            isPublic: !this.privateStream
          }
        }
      })
      this.showCreateNewStream = false
      this.streamName = ""
      this.description = ""
      sketchup.exec({name: "save_stream", data: {stream_id: res["data"]["streamCreate"]}})
      return res
    }
  }
}
</script>

<style>

.v-dialog {
  max-width: 390px
}

.v-text-field >>> input {
  font-size: 0.9em;
}
.v-text-field >>> label {
  font-size: 0.9em;
}

</style>