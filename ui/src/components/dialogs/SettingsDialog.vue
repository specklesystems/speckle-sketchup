<template>
  <!-- DIALOG: Settings -->
  <v-dialog v-model="showSettings">
    <template #activator="{ on, attrs }">
      <v-btn
          icon small class="mx-1"
          v-bind="attrs"
          v-on="on"
      >
        <v-icon>mdi-cog</v-icon>
      </v-btn>
    </template>

    <v-card>
      <v-card-title class="text-h5">
        Settings
      </v-card-title>
      <v-container class="px-6" pb-0>
        <!-- Switch Theme -->
        <div class="sm1 mt-3">User Preferences</div>
        <v-divider class="mb-2"/>
        <v-btn icon small class="mx-1" @click="switchTheme">
          <v-icon>mdi-theme-light-dark</v-icon>
        </v-btn>
        <span>Color Mode</span>

        <!-- Switch Diffing -->
        <v-switch
            v-model="diffing"
            class="pt-3 mt-n2 mb-n2"
            :label="'Diffing (Alpha)'"
            @click="switchDiffing"
        />
        <div class="sm1 mt-3">Send Strategy</div>
        <v-divider class="mb-2"/>
        <v-switch
            v-model="combineFacesByMaterial"
            class="pt-1 mt-n2 mb-n2"
            :label="'Combine faces by material under mesh'"
        />
        <v-switch
            v-model="includeAttributes"
            class="pt-1 my-n5"
            :label="'Include entity attributes'"
        />
        <v-icon class="ml-3" style="line-height: 0;">mdi-arrow-right-bottom</v-icon>
        <v-switch
            v-model="includeEdgeAttributes"
            class="pt-1 my-n5 ml-10"
            :label="'Edge'"
            :disabled="!includeAttributes"
        />
        <v-icon class="ml-3" style="line-height: 0;">mdi-arrow-right-bottom</v-icon>
        <v-switch
            v-model="includeFaceAttributes"
            class="pt-1 my-n5 ml-10"
            :label="'Face'"
            :disabled="!includeAttributes"
        />
        <v-icon class="ml-3" style="line-height: 0;">mdi-arrow-right-bottom</v-icon>
        <v-switch
            v-model="includeGroupAttributes"
            class="pt-1 my-n5 ml-10"
            :label="'Group'"
            :disabled="!includeAttributes"
        />
        <v-icon class="ml-3" style="line-height: 0;">mdi-arrow-right-bottom</v-icon>
        <v-switch
            v-model="includeComponentAttributes"
            class="pt-1 my-n5 ml-10"
            :label="'Component'"
            :disabled="!includeAttributes"
        />

        <div class="sm1 mt-3">Receive Strategy</div>
        <v-divider class="mb-2"/>
        <v-switch
            v-model="mergeCoplanarFaces"
            class="pt-1 mt-n2 mb-n2"
            :label="'Merge co-planar faces on receive'"
        />

      </v-container>

      <v-card-actions>
        <v-spacer></v-spacer>
        <v-btn
            color="blue darken-1"
            text
            @click="showSettings = false"
        >
          Close
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
/*global sketchup*/
import {bus} from "@/main";

export default {
  name: "ShowSettings",
  props: {
    preferences: {
      type: Object,
      default: null
    }
  },
  data() {
    return {
      showSettings: false,
      streamName: "",
      description: "",
      combineFacesByMaterial: this.preferences.model.combine_faces_by_material,
      includeAttributes: this.preferences.model.include_entity_attributes,
      includeFaceAttributes: this.preferences.model.include_face_entity_attributes,
      includeEdgeAttributes: this.preferences.model.include_edge_entity_attributes,
      includeGroupAttributes: this.preferences.model.include_group_entity_attributes,
      includeComponentAttributes: this.preferences.model.include_component_entity_attributes,
      mergeCoplanarFaces: this.preferences.model.merge_coplanar_faces,
      diffing: this.preferences.user.diffing
    }
  },
  watch: {
    'showSettings': {
      handler(newValue) {
        if (newValue){
          this.$mixpanel.track('Connector Action', { name: 'Open Settings Dialog' })
        }
      },
      deep: true
    },
    'combineFacesByMaterial': {
      handler(newValue) {
        sketchup.exec({
          name: "model_preferences_updated",
          data: {preference: "combine_faces_by_material", value: newValue}
        })
        this.$mixpanel.track('Connector Action', { name: 'Combine Faces By Material Option' })
      },
      deep: true
    },
    'includeAttributes': {
      handler(newValue) {
        sketchup.exec({
          name: "model_preferences_updated",
          data: {preference: "include_entity_attributes", value: newValue}
        })
        this.$mixpanel.track('Connector Action', { name: 'Include Entity Attributes Option' })
      },
      deep: true
    },
    'includeFaceAttributes': {
      handler(newValue) {
        sketchup.exec({
          name: "model_preferences_updated",
          data: {preference: "include_face_entity_attributes", value: newValue}
        })
        this.$mixpanel.track('Connector Action', { name: 'Include Face Entity Attributes Option' })
      },
      deep: true
    },
    'includeEdgeAttributes': {
      handler(newValue) {
        sketchup.exec({
          name: "model_preferences_updated",
          data: {preference: "include_edge_entity_attributes", value: newValue}
        })
        this.$mixpanel.track('Connector Action', { name: 'Include Edge Entity Attributes Option' })
      },
      deep: true
    },
    'includeGroupAttributes': {
      handler(newValue) {
        sketchup.exec({
          name: "model_preferences_updated",
          data: {preference: "include_group_entity_attributes", value: newValue}
        })
        this.$mixpanel.track('Connector Action', { name: 'Include Group Entity Attributes Option' })
      },
      deep: true
    },
    'includeComponentAttributes': {
      handler(newValue) {
        sketchup.exec({
          name: "model_preferences_updated",
          data: {preference: "include_component_entity_attributes", value: newValue}
        })
        this.$mixpanel.track('Connector Action', { name: 'Include Component Entity Attributes Option' })
      },
      deep: true
    },
    'mergeCoplanarFaces': {
      handler(newValue) {
        sketchup.exec({
          name: "model_preferences_updated",
          data: {preference: "merge_coplanar_faces", value: newValue}
        })
        this.$mixpanel.track('Connector Action', { name: 'Merge Co-Planar Faces Option' })
      },
      deep: true
    },
    'diffing': {
      handler(newValue) {
        sketchup.exec({
          name: "user_preferences_updated",
          data: {preference_hash: "configSketchup", preference: "diffing", value: newValue}
        })
        this.$mixpanel.track('Connector Action', { name: 'Diffing' })
      },
      deep: true
    }
  },
  methods: {
    switchTheme() {
      this.$vuetify.theme.dark = !this.$vuetify.theme.dark
      sketchup.exec({
        name: "user_preferences_updated",
        data: {preference_hash: "configSketchup", preference: "dark_theme", value: this.$vuetify.theme.dark}
      })
      this.$mixpanel.track('Connector Action', { name: 'Toggle Theme' })
    },
    refresh() {
      this.$apollo.queries.user.refetch()
      bus.$emit('refresh-streams')
    }
  }
}
</script>

<style>

</style>