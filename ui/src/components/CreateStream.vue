<template>
  <v-container fluid class="px-1 pb-0 pt-1">
    <v-dialog
        v-model="createNewStreamDialog"
        max-width="390"
    >
      <template v-slot:activator="{ on, attrs }">
        <v-btn
            class="ma-2"
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
        <v-card-text>
          Let Google help apps determine location. This means sending anonymous location data to Google, even when no apps are running.
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
              color="blue darken-1"
              text
              @click="createNewStreamDialog = false"
          >
            Cancel
          </v-btn>
          <v-btn
              color="blue darken-1"
              text
              @click="createNewStreamDialog = false"
          >
            Create
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    <v-dialog
        v-model="createStreamByIdDialog"
        max-width="390"
    >
      <template v-slot:activator="{ on, attrs }">
        <v-btn
            class="ma-2"
            min-width="185"
            small
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
          Create a New Stream
        </v-card-title>
        <v-card-text>
          Stream IDs and Stream/Branch/Commit URLs are supported.
        </v-card-text>
        <v-container>
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
              @click="createStreamByIdDialog = false"
          >
            Cancel
          </v-btn>
          <v-btn
              :disabled="{createStreamByIdText}"
              color="blue darken-1"
              text
              @click="createStreamByIdDialog = false"
          >
            Add
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<script>



export default {
  name: "CreateStream",
  data() {
    return {
      createNewStreamDialog: false,
      createStreamByIdDialog: false,
      createStreamByIdText: ""
    }
  },
}
</script>
