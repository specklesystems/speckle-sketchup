<template>
  <v-container fluid class="px-1 pb-0 pt-0">
    <v-row>
      <v-col class="py-2">
        <!-- DIALOG: Create New Stream -->
        <v-dialog v-model="showCreateNewStream">
          <template #activator="{ on, attrs }">
            <v-btn
                class="ma-2 pa-3"
                small
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
                small
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
                  @click="getStream"
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
import {bus} from "@/main";
import userQuery from "@/graphql/user.gql";
import {StreamWrapper} from "@/utils/streamWrapper";

export default {
  name: "CreateStreamDialog",
  props: {
    accountId: {
      type: String,
      default: null
    },
    serverUrl: {
      type: String,
      default: null
    }
  },
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
    }
  },
  apollo: {
    user: {
      query: userQuery
    }
  },
  methods: {
    refresh() {
      this.$apollo.queries.user.refetch()
      bus.$emit('refresh-streams')
    },
    async getStream(){
      try {
        const streamWrapper = new StreamWrapper(this.createStreamByIdText, this.accountId, this.serverUrl)
        let res = await this.$apollo.query({
          query: gql`
            query Stream($id: String!){
              stream(id: $id){
                id
                name
                description
                isPublic
                role
                createdAt
                updatedAt
                commentCount
                favoritedDate
                favoritesCount
                collaborators {
                  id
                  name
                  role
                  avatar
                },
                branches (limit: ${10}){
                  totalCount,
                  cursor,
                  items {
                    id,
                    name,
                    description,
                    commits {
                      totalCount
                    }
                  }
                }
              }
            }
          `,
          variables: {
            id: streamWrapper.streamId
          }
        })
        let stream = res.data.stream

        this.$eventHub.$emit('notification', {
          text: 'Stream Added by URL!\n',
        })
        bus.$emit('stream-added-by-id-or-url', stream.id)
        this.$mixpanel.track('Connector Action', { name: 'Stream Add From URL' })
      }
      catch (e){
        this.$eventHub.$emit('error', {
          text: 'The stream you are trying to add might;\n' +
              '- lies on different server, \n' +
              '- be private, \n' +
              '- not be existed anymore.',
        })
      }

      this.showCreateStreamById = false
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
      this.$mixpanel.track('Connector Action', { name: 'Stream Create' })
      sketchup.exec({name: "save_stream", data: {stream_id: res["data"]["streamCreate"]}})
      this.refresh()
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