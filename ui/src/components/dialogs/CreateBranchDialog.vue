<template>
  <!-- DIALOG: Create Branch -->
  <v-dialog v-model="showCreateBranch">
    <template #activator="{ on: dialog, attrs }">
      <v-btn
          v-tooltip="`Create ${branchTooltipName}`"
          icon x-small class="ml-0 mr-1"
          v-bind="attrs"
          v-on="{...dialog}"
      >
        <v-icon>
          mdi-plus-circle
        </v-icon>
      </v-btn>
    </template>
    <v-card>
      <v-card-title class="text-h5 mb-1">
        Create a New Branch
      </v-card-title>
      <v-card-subtitle class="py-0 my-0 font-italic">
        under {{ streamName }} stream
      </v-card-subtitle>
      <v-container class="px-6" pb-0>
        <v-text-field
            v-model="branchName"
            xxxclass="small-text-field"
            hide-details
            dense
            flat
            placeholder="Branch Name"
        />
        <v-text-field
            v-model="description"
            xxxclass="small-text-field"
            hide-details
            dense
            flat
            placeholder="Description (Optional)"
        />
      </v-container>

      <v-card-actions>
        <v-spacer></v-spacer>
        <v-btn
            color="blue darken-1"
            text
            @click="showCreateBranch = false"
        >
          Cancel
        </v-btn>
        <v-btn
            :disabled="branchName === ''"
            color="blue darken-1"
            text
            @click="createBranch"
        >
          Create
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
import gql from "graphql-tag";
import {bus} from "@/main";

export default {
  name: "CreateBranchDialog",
  props: {
    streamId: {
      type: String,
      default: null
    },
    streamName: {
      type: String,
      default: null
    },
    branchTooltipName: {
      type: String,
      default: ''
    }
  },
  data() {
    return {
      showCreateBranch: false,
      branchName: "",
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
  methods: {
    async createBranch(){
      let res = await this.$apollo.mutate({
        mutation: gql`
            mutation branchCreate($branch: BranchCreateInput!) {
              branchCreate(branch: $branch)
            }
          `,
        variables: {
          branch: {
            streamId: this.streamId,
            name: this.branchName,
            description: this.description === '' ? this.defaultDescription : this.description,
          }
        }
      })
      bus.$emit(`create-branch-${this.streamId}`, this.branchName)
      this.showCreateBranch = false
      this.branchName = ""
      this.description = ""
      this.$mixpanel.track('Connector Action', { name: 'Branch Create' })
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